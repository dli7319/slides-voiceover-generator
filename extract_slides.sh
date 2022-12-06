#!/bin/bash
trap "exit" INT
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${DIR}" || exit 1

slides_file="slides.pdf"

# Extract the slides from the PDF.
mkdir -p slides
pdftoppm -png "${slides_file}" -r 300 slides/slide