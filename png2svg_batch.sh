#!/bin/bash

# PNG to SVG Batch Conversion Script
# Converts PNG files to high-quality SVGs with proper sequential numbering

# Don't exit on error - continue processing other files
set +e

echo "PNG to SVG Batch Converter"
echo "==========================="

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# Accept Xcode license if needed (required for building packages)
if ! xcode-select -p >/dev/null 2>&1; then
    echo "Setting up Xcode command line tools..."
    xcode-select --install 2>/dev/null || true
    echo "Please ensure Xcode license is accepted by running: sudo xcodebuild -license accept"
    echo "Then run this script again."
    exit 1
fi

# Install required tools if not present
if ! command -v convert &> /dev/null; then
    echo "Installing ImageMagick..."
    brew install imagemagick
else
    echo "ImageMagick is already installed."
fi

if ! command -v potrace &> /dev/null; then
    echo "Installing Potrace..."
    brew install potrace
else
    echo "Potrace is already installed."
fi

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="$SCRIPT_DIR/Images"
SVG_DIR="$SCRIPT_DIR/SVGs"
TEMP_DIR="$SCRIPT_DIR/temp"

echo "Source directory: $IMAGES_DIR"
echo "Destination directory: $SVG_DIR"
echo "Temp directory: $TEMP_DIR"

# Create directories if they don't exist
mkdir -p "$SVG_DIR"
mkdir -p "$TEMP_DIR"

# Clear SVG directory first
echo "Clearing SVGs directory..."
rm -f "$SVG_DIR"/*

# Find and process numeric files first (0_front_cover.png, page_1.png, page_2.png, etc.)
echo "Step 1: Processing numeric files in order..."

# Find all PNG files and store them in an array using a more compatible approach
all_png_files=()
while IFS= read -r file; do
    all_png_files+=("$(basename "$file")")
done < <(find "$IMAGES_DIR" -name "*.png" -maxdepth 1 | sort -V)

# Separate numeric and non-numeric files
numeric_files=()
non_numeric_files=()

for file in "${all_png_files[@]}"; do
    if [[ "$file" =~ ^(0_|page_[0-9]+\.png)$ ]]; then
        numeric_files+=("$file")
    else
        non_numeric_files+=("$file")
    fi
done

# Process numeric files, sorted numerically (0_front_cover.png, page_1.png, page_2.png, etc.)
# Sort the numeric files to ensure proper order (0_, page_1, page_2, ...)
numeric_list=$(printf '%s\n' "${numeric_files[@]}" | sort -V)
sorted_numeric_files=()
while IFS= read -r line; do
    sorted_numeric_files+=("$line")
done < <(printf '%s\n' $numeric_list)

counter=0
# First, handle 0_front_cover.png separately if it exists
if [ -f "$IMAGES_DIR/0_front_cover.png" ]; then
    echo "Processing special file: 0_front_cover.png -> 0.svg"

    # Convert PNG to high quality SVG using potrace with optimized parameters for detail preservation
    pbm_temp="$TEMP_DIR/temp.pbm"
    if magick "$IMAGES_DIR/0_front_cover.png" -colorspace Gray -normalize -level 0%,100%,0.7 -blur 0x0.5 -monochrome -threshold 50% "$pbm_temp"; then
        # Then convert PBM to SVG using potrace with high detail parameters
        svg_output="$SVG_DIR/0.svg"
        if potrace -s "$pbm_temp" -o "$svg_output" --opttolerance=0.2 --turdsize=2 --alphamax=7 --turnpolicy=minority --unit=10 --scale=1 --longcoding; then
            echo "Successfully converted: 0_front_cover.png -> 0.svg"
            ((counter++))
        else
            echo "Error: Failed to convert PBM to SVG for: 0_front_cover.png"
            # If the vectorization failed, try an alternative approach for complex images
            if magick "$IMAGES_DIR/0_front_cover.png" -define svg:format=svg "$svg_output" 2>/dev/null; then
                echo "Alternative conversion successful: 0_front_cover.png -> 0.svg"
                ((counter++))
            elif [ ! -s "$svg_output" ]; then
                # Create a simple SVG with the PNG embedded as fallback
                width=$(magick identify -format "%%w" "$IMAGES_DIR/0_front_cover.png")
                height=$(magick identify -format "%%h" "$IMAGES_DIR/0_front_cover.png")
                echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${width}\" height=\"${height}\">
  <image href=\"$(basename "$IMAGES_DIR/0_front_cover.png")\" width=\"100%%\" height=\"100%%\"/>
</svg>" > "$svg_output"
                echo "Fallback SVG created for: 0_front_cover.png -> 0.svg"
                ((counter++))
            fi
        fi
    else
        echo "Error: Failed to convert PNG to PBM for: 0_front_cover.png"
        # If the initial conversion fails, try direct conversion
        svg_output="$SVG_DIR/0.svg"
        if magick "$IMAGES_DIR/0_front_cover.png" -define svg:format=svg "$svg_output" 2>/dev/null; then
            echo "Alternative conversion successful: 0_front_cover.png -> 0.svg"
            ((counter++))
        elif [ ! -s "$svg_output" ]; then
            # Create a simple SVG with the PNG embedded as fallback
            width=$(magick identify -format "%%w" "$IMAGES_DIR/0_front_cover.png")
            height=$(magick identify -format "%%h" "$IMAGES_DIR/0_front_cover.png")
            echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${width}\" height=\"${height}\">
  <image href=\"$(basename "$IMAGES_DIR/0_front_cover.png")\" width=\"100%%\" height=\"100%%\"/>
</svg>" > "$svg_output"
            echo "Fallback SVG created for: 0_front_cover.png -> 0.svg"
            ((counter++))
        fi
    fi
fi

# Then process page_*.png files in numerical order
for file in "${sorted_numeric_files[@]}"; do
    if [ -n "$file" ] && [ "$file" != "0_front_cover.png" ]; then  # Make sure the variable isn't empty and not the front cover
        # Only process page_*.png files
        if [[ "$file" =~ ^page_[0-9]+\.png$ ]]; then
            echo "Processing numeric file: $file -> ${counter}.svg"

            # Full path to the input PNG
            input_png="$IMAGES_DIR/$file"

            # Check if the input file exists
            if [ ! -f "$input_png" ]; then
                echo "Warning: Input file does not exist: $input_png"
                continue
            fi

            # Convert PNG to high quality SVG using potrace with optimized parameters for detail preservation
            # First convert to PBM (Portable Bitmap) format
            pbm_temp="$TEMP_DIR/temp.pbm"
            if magick "$input_png" -colorspace Gray -normalize -level 0%,100%,0.7 -blur 0x0.5 -monochrome -threshold 50% "$pbm_temp"; then
                # Then convert PBM to SVG using potrace with high detail parameters
                svg_output="$SVG_DIR/${counter}.svg"
                if potrace -s "$pbm_temp" -o "$svg_output" --opttolerance=0.2 --turdsize=2 --alphamax=7 --turnpolicy=minority --unit=10 --scale=1 --longcoding; then
                    echo "Successfully converted: $file -> ${counter}.svg"
                    ((counter++))
                else
                    echo "Error: Failed to convert PBM to SVG for: $file"
                    # If the vectorization failed, try an alternative approach for complex images
                    if magick "$input_png" -define svg:format=svg "$svg_output" 2>/dev/null; then
                        echo "Alternative conversion successful: $file -> ${counter}.svg"
                        ((counter++))
                    elif [ ! -s "$svg_output" ]; then
                        # Create a simple SVG with the PNG embedded as fallback
                        width=$(magick identify -format "%%w" "$input_png")
                        height=$(magick identify -format "%%h" "$input_png")
                        echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${width}\" height=\"${height}\">
  <image href=\"$(basename "$input_png")\" width=\"100%%\" height=\"100%%\"/>
</svg>" > "$svg_output"
                        echo "Fallback SVG created for: $file -> ${counter}.svg"
                        ((counter++))
                    fi
                fi
            else
                echo "Error: Failed to convert PNG to PBM for: $file"
                # If the initial conversion fails, try direct conversion
                svg_output="$SVG_DIR/${counter}.svg"
                if magick "$input_png" -define svg:format=svg "$svg_output" 2>/dev/null; then
                    echo "Alternative conversion successful: $file -> ${counter}.svg"
                    ((counter++))
                elif [ ! -s "$svg_output" ]; then
                    # Create a simple SVG with the PNG embedded as fallback
                    width=$(magick identify -format "%%w" "$input_png")
                    height=$(magick identify -format "%%h" "$input_png")
                    echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${width}\" height=\"${height}\">
  <image href=\"$(basename "$input_png")\" width=\"100%%\" height=\"100%%\"/>
</svg>" > "$svg_output"
                    echo "Fallback SVG created for: $file -> ${counter}.svg"
                    ((counter++))
                fi
            fi
        fi
    fi
done

# Process remaining non-numeric files alphabetically
echo "Step 2: Processing remaining files alphabetically..."
non_numeric_list=$(printf '%s\n' "${non_numeric_files[@]}" | sort)
sorted_non_numeric_files=()
while IFS= read -r line; do
    sorted_non_numeric_files+=("$line")
done < <(printf '%s\n' $non_numeric_list)

for file in "${sorted_non_numeric_files[@]}"; do
    if [ -n "$file" ] && [ "$file" != "0_front_cover.png" ]; then  # Make sure the variable isn't empty and not the front cover
        echo "Processing remaining file: $file -> ${counter}.svg"

        # Full path to the input PNG
        input_png="$IMAGES_DIR/$file"

        # Check if the input file exists
        if [ ! -f "$input_png" ]; then
            echo "Warning: Input file does not exist: $input_png"
            continue
        fi

        # Convert PNG to high quality SVG using potrace with optimized parameters for detail preservation
        pbm_temp="$TEMP_DIR/temp.pbm"
        if magick "$input_png" -colorspace Gray -normalize -level 0%,100%,0.7 -blur 0x0.5 -monochrome -threshold 50% "$pbm_temp"; then
            # Then convert PBM to SVG using potrace with high detail parameters
            svg_output="$SVG_DIR/${counter}.svg"
            if potrace -s "$pbm_temp" -o "$svg_output" --opttolerance=0.2 --turdsize=2 --alphamax=7 --turnpolicy=minority --unit=10 --scale=1 --longcoding; then
                echo "Successfully converted: $file -> ${counter}.svg"
                ((counter++))
            else
                echo "Error: Failed to convert PBM to SVG for: $file"
                # If the vectorization failed, try an alternative approach for complex images
                if magick "$input_png" -define svg:format=svg "$svg_output" 2>/dev/null; then
                    echo "Alternative conversion successful: $file -> ${counter}.svg"
                    ((counter++))
                elif [ ! -s "$svg_output" ]; then
                    # Create a simple SVG with the PNG embedded as fallback
                    width=$(magick identify -format "%%w" "$input_png")
                    height=$(magick identify -format "%%h" "$input_png")
                    echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${width}\" height=\"${height}\">
  <image href=\"$(basename "$input_png")\" width=\"100%%\" height=\"100%%\"/>
</svg>" > "$svg_output"
                    echo "Fallback SVG created for: $file -> ${counter}.svg"
                    ((counter++))
                fi
            fi
        else
            echo "Error: Failed to convert PNG to PBM for: $file"
            # If the initial conversion fails, try direct conversion
            svg_output="$SVG_DIR/${counter}.svg"
            if magick "$input_png" -define svg:format=svg "$svg_output" 2>/dev/null; then
                echo "Alternative conversion successful: $file -> ${counter}.svg"
                ((counter++))
            elif [ ! -s "$svg_output" ]; then
                # Create a simple SVG with the PNG embedded as fallback
                width=$(magick identify -format "%%w" "$input_png")
                height=$(magick identify -format "%%h" "$input_png")
                echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${width}\" height=\"${height}\">
  <image href=\"$(basename "$input_png")\" width=\"100%%\" height=\"100%%\"/>
</svg>" > "$svg_output"
                echo "Fallback SVG created for: $file -> ${counter}.svg"
                ((counter++))
            fi
        fi
    fi
done

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo ""
echo "Conversion complete!"
echo "Total SVGs created: $((counter))"
echo "SVGs saved to: $SVG_DIR"
echo "Sequential numbering: 0.svg, 1.svg, 2.svg, ..., $((counter-1)).svg"

# Create CSVs for Adobe InDesign data merge
echo ""
echo "Creating CSV files for Adobe InDesign data merge..."

# Define CSVs directory (create if it doesn't exist)
CSV_DIR="$SCRIPT_DIR/CSVs"
mkdir -p "$CSV_DIR"

# Generate timestamp for unique filenames
timestamp=$(date +"%Y%m%d_%H%M%S")

# Build CSV file paths with timestamp
csv_with_blanks_path="$CSV_DIR/image_list_with_blank_pages_interleaved_$timestamp.csv"
csv_without_blanks_path="$CSV_DIR/image_list_without_blank_pages_$timestamp.csv"

# Get the number of SVGs created
num_svgs=$counter

# Create CSV with blank pages interleaved
{
    echo "@Images"
    for ((i = 0; i < num_svgs; i++)); do
        # Convert path separators to macOS-style (double slashes) expected by InDesign
        # First get the path and then replace single slashes with double slashes
        svg_path="$SVG_DIR/${i}.svg"
        formatted_svg_path=$(echo "$svg_path" | sed 's/\//\/\//g')
        echo "$formatted_svg_path"

        # Add blank page after each SVG except the last one
        if [ $i -lt $((num_svgs - 1)) ]; then
            blank_path="$SCRIPT_DIR/assets/blank.svg"
            blank_svg_path=$(echo "$blank_path" | sed 's/\//\/\//g')
            echo "$blank_svg_path"
        fi
    done
} > "$csv_with_blanks_path"

# Create CSV without blank pages
{
    echo "@Images"
    for ((i = 0; i < num_svgs; i++)); do
        # Convert path separators to macOS-style (double slashes) expected by InDesign
        svg_path="$SVG_DIR/${i}.svg"
        formatted_svg_path=$(echo "$svg_path" | sed 's/\//\/\//g')
        echo "$formatted_svg_path"
    done
} > "$csv_without_blanks_path"

echo "Generated '$(basename "$csv_with_blanks_path")' with $((num_svgs*2 - 1)) rows (including blanks)."
echo "Generated '$(basename "$csv_without_blanks_path")' with $((num_svgs)) rows."
echo "CSV files saved to: $CSV_DIR"

# Count how many files were processed
echo ""
echo "Summary:"
echo "- Numeric files processed first in numerical order"
echo "- Remaining files processed alphabetically"
echo "- All SVGs saved with sequential numbering to maintain order"
echo "- CSV files generated for Adobe InDesign data merge automation"