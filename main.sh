#!/bin/bash

set -e

# ================================
# CONFIGURATION
# ================================
WORK_DIR="/home/arcgis_service/Daily_M1.2"
REPO_URL="github.com/PrathameshDa/DailyM1.2"

# ================================
# TOKEN FROM JENKINS
# ================================
if [ -z "$GITHUBTOKEN" ]; then
    echo "ERROR: GITHUBTOKEN environment variable not found!"
    exit 1
fi

TOKEN="$GITHUBTOKEN"

echo "Token received successfully"

# ================================
# START EXECUTION
# ================================
cd "$WORK_DIR" || {
    echo "ERROR: Cannot change directory"
    exit 1
}

echo "===== Daily Maintenance Execution Started ====="
echo "Current Directory: $(pwd)"

# ================================
# GIT SAFE DIRECTORY FIX
# ================================
echo "Configuring Git safe directory..."
#git config --global --add safe.directory "$WORK_DIR"

echo "Checking for updates in the current directory..."

# ================================
# GIT OPERATIONS
# ================================
GIT_URL="https://${TOKEN}@${REPO_URL}"

if [ ! -d ".git" ]; then

    echo "Initializing local repository..."

    git init

    git remote add origin "$GIT_URL"

    git fetch

    git checkout -t origin/main -f

    if [ $? -ne 0 ]; then
        echo "ERROR: Git initialization failed"
        exit 1
    fi

else

    echo "Pulling latest code..."

    git stash || true

    git pull "$GIT_URL"

    if [ $? -ne 0 ]; then
        echo "ERROR: Git pull failed"
        exit 1
    fi
fi

echo "Git sync completed successfully!"

# ================================
# UV EXECUTION
# ================================
echo ""
echo "Sync Complete!"
echo "===================================="

cd "$WORK_DIR" || exit 1

# ================================
# FIND UV PATH
# ================================
UV_PATH="/home/arcgis_service/.local/bin/uv"

UV_CANDIDATES=(
    "~/.local/bin/uv"
    "/usr/local/bin/uv"
    "/snap/bin/uv"
)

for candidate in "${UV_CANDIDATES[@]}"; do
    if [ -f "$candidate" ]; then
        UV_PATH="$candidate"
        break
    fi
done

# Check system PATH
if [ -z "$UV_PATH" ]; then
    UV_PATH=$(command -v uv 2>/dev/null || true)
fi

echo "Checking UV installation..."

# ================================
# INSTALL UV IF MISSING
# ================================
if [ -z "$UV_PATH" ]; then

    echo "Installing UV..."

    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Re-check after install
    for candidate in "${UV_CANDIDATES[@]}"; do
        if [ -f "$candidate" ]; then
            UV_PATH="$candidate"
            break
        fi
    done

    if [ -z "$UV_PATH" ]; then
        echo "ERROR: UV installation failed!"
        exit 1
    fi
fi

echo "UV found at: $UV_PATH"

export PATH="$(dirname "$UV_PATH"):$PATH"

# ================================
# VALIDATE PROJECT FILES
# ================================
if [ ! -f "pyproject.toml" ]; then
    echo "ERROR: pyproject.toml not found"
    exit 1
fi

if [ ! -f "main.py" ]; then
    echo "ERROR: main.py not found"
    exit 1
fi

# ================================
# RUN UV SYNC
# ================================
echo "Running UV sync..."

"$UV_PATH" sync

if [ $? -ne 0 ]; then
    echo "ERROR: UV sync failed"
    exit 1
fi

# ================================
# RUN PYTHON SCRIPT
# ================================
echo "Running Python script..."

"$UV_PATH" run python main.py

if [ $? -ne 0 ]; then
    echo "ERROR: Python script failed"
    exit 1
fi

echo "===================================="
echo "Execution completed successfully!"
echo "===================================="

# ================================
# PRINT LATEST LOG FILE
# ================================
LOG_DIR="$WORK_DIR/Logs"

echo ""
echo "===== LOG FILE ANALYSIS ====="
echo "Log Directory: $LOG_DIR"

if [ -d "$LOG_DIR" ]; then

    latestFile=$(find "$LOG_DIR" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

    if [ -n "$latestFile" ]; then

        echo "Latest log file: $(basename "$latestFile")"
        echo "Last Modified: $(date -r "$latestFile")"

        echo "------------------------------------"
        echo "CONTENT START"
        echo "------------------------------------"

        cat "$latestFile"

        echo ""
        echo "------------------------------------"
        echo "CONTENT END"
        echo "------------------------------------"

    else
        echo "No log files found in logs directory."
    fi

else
    echo "Logs directory not found: $LOG_DIR"
fi
