#!/usr/bin/env bash
# optimize_images.sh — image optimization pipeline for Sayfa sites
#
# Requires: vips (recommended) or imagemagick
# Install:  brew install vips        (macOS)
#           apt install libvips-tools (Debian/Ubuntu)
#
# Usage: bash scripts/optimize_images.sh
#        bash scripts/optimize_images.sh --input static/images --output static/images

set -euo pipefail

INPUT_DIR="${1:-static/images}"
OUTPUT_DIR="${2:-static/images}"

if ! command -v vips &>/dev/null && ! command -v convert &>/dev/null; then
  echo "Error: neither 'vips' nor 'convert' (ImageMagick) found."
  echo "Install vips: brew install vips  OR  apt install libvips-tools"
  exit 1
fi

process_with_vips() {
  local src="$1"
  local base="${src%.*}"

  # Skip already-optimized files
  if [[ "$src" == *_1200.* ]]; then
    return
  fi

  # Skip if all outputs already exist
  if [[ -f "${base}_1200.jpg" && -f "${base}.webp" ]]; then
    echo "Skipping (already optimized): $src"
    return
  fi

  echo "Processing: $src"

  # Resize to max 1200px wide, keep aspect ratio
  vips thumbnail "$src" "${base}_1200.jpg" 1200

  # Generate WebP variant
  vips thumbnail "$src" "${base}.webp" 1200

  # Generate AVIF variant (requires vips >= 8.11)
  if vips --version | grep -qE "8\.(1[1-9]|[2-9][0-9])"; then
    vips thumbnail "$src" "${base}.avif" 1200
  fi
}

process_with_imagemagick() {
  local src="$1"
  local base="${src%.*}"

  # Skip already-optimized files
  if [[ "$src" == *_1200.* ]]; then
    return
  fi

  # Skip if all outputs already exist
  if [[ -f "${base}_1200.jpg" && -f "${base}.webp" ]]; then
    echo "Skipping (already optimized): $src"
    return
  fi

  echo "Processing: $src"

  # Resize to max 1200px wide
  convert "$src" -resize '1200>' -quality 85 "${base}_1200.jpg"

  # Generate WebP variant
  convert "$src" -resize '1200>' -quality 85 "${base}.webp"
}

find "$INPUT_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r img; do
  if command -v vips &>/dev/null; then
    process_with_vips "$img"
  else
    process_with_imagemagick "$img"
  fi
done

echo "Done. Processed images are in $OUTPUT_DIR"
