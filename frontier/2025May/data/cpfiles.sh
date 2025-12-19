#!/bin/bash
set -e

# Execute and print the command
exe() {
    echo "\$ $@"
    "$@"
}

# Check if directory is passed as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Error: '$1' is not a directory"
    exit 1
fi

prefix=$1

# Enable nullglob so empty globs expand to nothing
shopt -s nullglob

# Loop through directories inside the given directory
for fulldir in "$prefix"*/; do
    dir=$(basename "$fulldir")

    if [ -d "$dir" ]; then
        echo "Directory '$dir' exists already, skip."
        continue
    fi

    echo "Processing directory: '$dir'"
    exe mkdir "$dir"

    # Copy std*.txt files if any exist
    files=("${fulldir}"std*.txt)
    if [ ${#files[@]} -gt 0 ]; then
        exe cp "${files[@]}" "$dir/"
    fi

    # Copy *.par files if any exist
    files=("${fulldir}"*.par)
    if [ ${#files[@]} -gt 0 ]; then
        exe cp "${files[@]}" "$dir/"
    fi
done
