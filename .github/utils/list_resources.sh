#!/bin/bash

# Script to list the first unbracketed parent folder in each path by crawling nested directories

# Base directory to start the search
# Check if base directory is provided as argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <base_directory>"
    echo "Example: $0 /path/to/boom-base/resources"
    exit 1
fi

base_dir="$1"

# Check if the provided directory exists
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory '$base_dir' does not exist"
    exit 1
fi

# Use find to traverse directories
find "$base_dir" -type d | while IFS= read -r dir; do
    # If the directory itself is the base_dir, skip processing
    if [[ "$dir" == "$base_dir" ]]; then
        continue
    fi
    # Split the path into components after base_dir
    relative_path="${dir#$base_dir/}"
    IFS='/' read -ra components <<< "$relative_path"
    # Initialize path to build from base_dir
    path="$base_dir"
    # Iterate through components to find the first unbracketed folder
    for component in "${components[@]}"; do
        path="$path/$component"
        if [[ ! "$component" =~ \[.*\] ]]; then
            echo "$path"
            break
        fi
    done
done | sort -u | tee /dev/tty | wc -l | xargs -I {} echo "Sum of resources: {}"
