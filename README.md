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