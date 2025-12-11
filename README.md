# PNG to SVG Batch Conversion Script

This script converts PNG images to high-quality SVGs for use with Adobe InDesign.

## How It Works

The script processes PNG files in the `Images` folder with the following priority:

1. **Special file**: `0_front_cover.png` is converted to `0.svg` (front cover)
2. **Numeric files**: `page_1.png`, `page_2.png`, etc. are converted to `1.svg`, `2.svg`, etc. in numerical order
3. **Alphabetical files**: Remaining files (like `z_back_cover.png`) are converted to subsequent numbers in alphabetical order (e.g., `37.svg`)

## Usage

1. Place all PNG files you want to convert in the `Images` folder
2. Run the script from the project root directory:

```bash
./png2svg_batch.sh
```

## Dependencies

The script will automatically install the required tools if they're not present:
- ImageMagick (for image processing)
- Potrace (for vectorization)

## Output

All SVG files are placed in the `SVGs` folder with sequential numbering:
- `0.svg`, `1.svg`, `2.svg`, ..., `n.svg`

## Quality Improvements

This script is optimized to preserve fine details during conversion:
- Advanced ImageMagick pre-processing with contrast and gamma adjustments
- High-precision Potrace parameters for detailed vectorization
- Multi-step conversion process to maintain quality

## Requirements

- macOS with Homebrew installed
- Xcode command line tools (run `xcode-select --install` if needed)

## Using CSV Files in Adobe InDesign

The script automatically generates two CSV files that can be used for InDesign's Data Merge feature:

### 1. With Blank Pages (`image_list_with_blank_pages_interleaved_*.csv`)
- Contains SVG file paths with blank pages interleaved between each image
- Use this for layouts that require blank pages between content pages
- Perfect for books with alternating content and blank pages

### 2. Without Blank Pages (`image_list_without_blank_pages_*.csv`)
- Contains only the SVG file paths in sequence
- Use this for continuous layouts without blank pages
- Ideal for books with content on every page

### Steps to Use in InDesign:
1. Open your InDesign template from the `InDesign Data Match Files` folder
2. Go to `Window > Utilities > Data Merge`
3. Click "Select Data Source" in the Data Merge panel
4. Select one of the generated CSV files from the `CSVs` folder
5. Drag the "Images" field from the Data Merge panel to your image placeholder
6. Click "Create Merged Documents" to generate your book layout
7. InDesign will create a document with all images placed according to your template

### Note:
- The CSV files include absolute file paths to the SVGs in the SVGs folder
- Make sure your InDesign document and asset locations are set up properly
- The files are timestamped to avoid overwriting previous versions