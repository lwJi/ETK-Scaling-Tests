#!/bin/bash
set -e

# Execute and print the command
exe() {
    echo "\$ $@"
    "$@"
}

# Check if prefix is passed as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_prefix>"
    exit 1
fi

prefix=$1

# Enable nullglob so empty globs expand to nothing
shopt -s nullglob

# Check if any directories match the prefix
dirs=("$prefix"*/)
if [ ${#dirs[@]} -eq 0 ]; then
    echo "Error: No directories match prefix '$prefix*'"
    exit 1
fi

# Loop through directories matching the prefix
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
