#!/bin/bash

# Execute and print the command
exe() {
    echo "\$ $@"
    "$@"
}
export -f exe

# Check if directory is passed as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

prefix=$1

# Loop through directories inside the given directory
for fulldir in "$prefix"*/; do
  dir=$(basename "$fulldir")
  if [ -d "$dir" ]; then
    echo "Directory '$dir' exists already, skip."
  else
    echo "Processing directory: '$dir'"
    exe mkdir "$dir"
    (
      exe cd "$dir"
      exe cp "${fulldir}"std*.txt ./
      exe cp "${fulldir}"*.par ./
    )
  fi
done
