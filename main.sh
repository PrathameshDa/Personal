#!/bin/bash

# Daily Maintenance Script Runner
# Runs main.py using UV

echo "===================================="
echo "Daily Maintenance Script Runner"
echo "Using UV Package Manager"
echo "===================================="
echo

# Set the working directory to the script location
cd "$(dirname "$0")" || exit 1

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
uv --version
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

# Set Python path
export PYTHONPATH="$(pwd)"

echo "Starting Daily Maintenance Script..."
echo "===================================="
echo

# Option 1: Try UV with pyproject.toml
echo "Attempting to sync and run with UV..."
echo "Step 1: Syncing dependencies..."

if uv sync; then

    echo "Dependencies synced successfully!"
    echo "Step 2: Running main.py..."

    if uv run main.py; then
        echo
        echo "===================================="
        echo "Script completed successfully with UV!"
        echo "===================================="
        exit 0
    else
        EXIT_CODE=$?
        echo "UV run failed, error code: $EXIT_CODE"
    fi

else
    EXIT_CODE=$?
    echo "UV sync failed, error code: $EXIT_CODE"
fi


# Fallback
echo
echo "Trying fallback with requirements.txt..."
echo

if [ -f "requirements.txt" ]; then

    if uv run --with-requirements requirements.txt --no-project main.py; then

        echo
        echo "===================================="
        echo "Script completed successfully with UV (fallback)!"
        echo "===================================="
        exit 0

    else

        EXIT_CODE=$?

        echo "UV fallback failed."
        echo "Script failed with all methods! Error code: $EXIT_CODE"
        echo "===================================="
        echo
        echo "Troubleshooting tips:"
        echo "1. Check the log files in the Logs directory"
        echo "2. Verify your config.yaml settings"
        echo "3. Ensure all credentials are properly configured"
        echo "4. Check your network connection"
        echo "5. Try running: uv sync --verbose"

        exit "$EXIT_CODE"
    fi

else

    echo "requirements.txt not found."
    echo "Script failed with all methods!"
    echo "===================================="
    echo
    echo "Troubleshooting tips:"
    echo "1. Check the log files in the Logs directory"
    echo "2. Verify your config.yaml settings"
    echo "3. Ensure all credentials are properly configured"
    echo "4. Check your network connection"
    echo "5. Try running: uv sync --verbose"

    exit 1
fi
