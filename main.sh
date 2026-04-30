#!/bin/bash

# Daily Maintenance Script Runner

echo "===================================="
echo "Daily Maintenance Script Runner"
echo "Using UV Package Manager"
echo "===================================="
echo

# Set working directory to script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Display current directory
echo "Current directory: $(pwd)"
echo

# Check if UV is installed
echo "Checking UV installation..."
if ! command -v uv >/dev/null 2>&1; then
    echo "ERROR: UV is not installed or not in PATH"
    echo "Please install UV first: pip install uv"
    exit 1
fi

echo "UV is installed successfully!"
echo

# Check if pyproject.toml exists
if [ ! -f "pyproject.toml" ]; then
    echo "ERROR: pyproject.toml not found"
    echo "Please ensure pyproject.toml is in the project directory"
    exit 1
fi

echo "Found pyproject.toml"
echo

# Check if main.py exists
if [ ! -f "main.py" ]; then
    echo "ERROR: main.py not found"
    echo "Please ensure main.py is in the project directory"
    exit 1
fi

echo "Found main.py"
echo

# Set PYTHONPATH
export PYTHONPATH="$(pwd)"

echo "Starting Daily Maintenance Script..."
echo "===================================="
echo

# Option 1: Try UV with pyproject.toml
echo "Attempting to sync and run with UV..."
echo "Step 1: Syncing dependencies..."

uv sync
SYNC_STATUS=$?

if [ $SYNC_STATUS -eq 0 ]; then
    echo "Dependencies synced successfully!"
    echo "Step 2: Running main.py..."

    uv run main.py
    RUN_STATUS=$?

    if [ $RUN_STATUS -eq 0 ]; then
        echo
        echo "===================================="
        echo "Script completed successfully with UV!"
        echo "===================================="
        exit 0
    else
        echo "UV run failed, error code: $RUN_STATUS"
    fi
else
    echo "UV sync failed, error code: $SYNC_STATUS"
fi

echo
echo "Trying fallback with requirements.txt..."

# Option 2: Fallback with requirements.txt
if [ -f "requirements.txt" ]; then
    uv run --with-requirements requirements.txt --no-project main.py
    FALLBACK_STATUS=$?

    if [ $FALLBACK_STATUS -eq 0 ]; then
        echo
        echo "===================================="
        echo "Script completed successfully with UV (fallback)!"
        echo "===================================="
        exit 0
    else
        echo "UV fallback failed."
        echo "Script failed with all methods! Error code: $FALLBACK_STATUS"
    fi
else
    echo "requirements.txt not found. Script failed with all methods!"
fi

echo "===================================="
echo
echo "Troubleshooting tips:"
echo "1. Check the log files in the Logs directory"
echo "2. Verify your config.yaml settings"
echo "3. Ensure all credentials are properly configured"
echo "4. Check your network connection"
echo "5. Try running: uv sync --verbose"

echo
echo "Exiting Daily Maintenance Script Runner."
exit 1