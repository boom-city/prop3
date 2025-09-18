#!/bin/bash

# Validate GitHub Actions workflows
set -e

echo "🔍 Validating GitHub Actions workflows..."

# Check if Python and PyYAML are available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python3 to validate YAML syntax."
    exit 1
fi

if ! python3 -c "import yaml" &> /dev/null; then
    echo "⚠️  PyYAML not found. Installing..."
    pip3 install PyYAML || {
        echo "❌ Failed to install PyYAML. Please install manually: pip3 install PyYAML"
        exit 1
    }
fi

# Validate each workflow file
WORKFLOWS_DIR=".github/workflows"
VALIDATION_PASSED=true

if [ ! -d "$WORKFLOWS_DIR" ]; then
    echo "❌ Workflows directory not found: $WORKFLOWS_DIR"
    exit 1
fi

echo ""
echo "Validating workflow files in $WORKFLOWS_DIR:"
echo "=============================================="

for workflow in "$WORKFLOWS_DIR"/*.yml "$WORKFLOWS_DIR"/*.yaml; do
    if [ -f "$workflow" ]; then
        filename=$(basename "$workflow")
        echo -n "📄 $filename ... "

        if python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null; then
            echo "✅ Valid"
        else
            echo "❌ Invalid YAML syntax"
            VALIDATION_PASSED=false

            echo "   Error details:"
            python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>&1 | head -5 | sed 's/^/   /'
            echo ""
        fi
    fi
done

echo ""
echo "=============================================="

if [ "$VALIDATION_PASSED" = true ]; then
    echo "✅ All workflow files have valid YAML syntax!"
    exit 0
else
    echo "❌ Some workflow files have YAML syntax errors."
    echo ""
    echo "💡 Common fixes:"
    echo "   - Check for unescaped quotes in multi-line strings"
    echo "   - Use proper YAML multi-line syntax (|, >, or |-)"
    echo "   - Ensure proper indentation (spaces, not tabs)"
    echo "   - Use heredocs for complex multi-line content"
    exit 1
fi