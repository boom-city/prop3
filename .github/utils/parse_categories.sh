#!/bin/bash

# Parse categories script
# This script reads resources.txt and formats it into categorized output

input_file="${1:-resources.txt}"
output_file="${2:-categorized_resources.md}"

if [[ ! -f "$input_file" ]]; then
    echo "Error: Input file '$input_file' not found!"
    exit 1
fi

# Create temporary file for processing
temp_file=$(mktemp)

# Process the input file
# Skip the last line (sum of resources) and process each resource line
head -n -1 "$input_file" | while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Extract the path after ./resources/
    if [[ $line =~ ^\./resources/(.*)$ ]]; then
        path="${BASH_REMATCH[1]}"
        
        # Extract category (first bracketed section)
        if [[ $path =~ ^\[([^\]]+)\]/(.*)$ ]]; then
            category="${BASH_REMATCH[1]}"
            remaining="${BASH_REMATCH[2]}"
            
            # Check if there's a subcategory
            if [[ $remaining =~ ^\[([^\]]+)\]/(.*)$ ]]; then
                subcategory="${BASH_REMATCH[1]}"
                resource="${BASH_REMATCH[2]}"
                echo "$category|$subcategory|$resource"
            else
                resource="$remaining"
                echo "$category||$resource"
            fi
        fi
    fi
done > "$temp_file"

# Sort by category, then subcategory, then resource
sort "$temp_file" > "${temp_file}.sorted"

# Count resources for summary
total_resources=$(wc -l < "${temp_file}.sorted")
category_count=$(cut -d'|' -f1 "${temp_file}.sorted" | sort -u | wc -l)

# Generate clean markdown output with clear hierarchy
{
    echo "# Resources"
    echo ""
    echo "Total: $total_resources resources across $category_count categories"
    echo ""
    
    current_category=""
    current_subcategory=""
    
    while IFS='|' read -r category subcategory resource; do
        # New category
        if [[ "$category" != "$current_category" ]]; then
            [[ -n "$current_category" ]] && echo ""  # Add blank line between categories
            echo "## [$category]"
            current_category="$category"
            current_subcategory=""
        fi
        
        # New subcategory within same category
        if [[ -n "$subcategory" && "$subcategory" != "$current_subcategory" ]]; then
            echo ""
            echo "  **[$subcategory]**"
            current_subcategory="$subcategory"
        fi
        
        # Print resource with appropriate indentation
        if [[ -n "$subcategory" ]]; then
            echo "    - $resource"
        else
            echo "  - $resource"
            current_subcategory=""  # Reset subcategory for direct category resources
        fi
        
    done < "${temp_file}.sorted"
    
} > "$output_file"

# Clean up temporary files
rm -f "$temp_file" "${temp_file}.sorted"

echo "Generated: $output_file"

# Show a preview
echo ""
echo "Preview:"
echo "========"
head -n 20 "$output_file"
if [[ $(wc -l < "$output_file") -gt 20 ]]; then
    echo "..."
    echo ""
    echo "Full output: $output_file ($(wc -l < "$output_file") lines)"
fi
