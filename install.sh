#!/bin/bash

# Hardcode your repository URL here
REPO_URL="https://github.com/tm0090/dank-niri-config.git"
TARGET_DIR="$HOME/Downloads/inspect-niri-settings"

echo "Setting up repository in $TARGET_DIR..."

# Ensure the Downloads folder exists
mkdir -p "$HOME/Downloads"

# Check if the target directory already exists
if [ -d "$TARGET_DIR" ]; then
    echo "Error: The folder '$TARGET_DIR' already exists."
    echo "Please remove it first or rename it before running this script."
    exit 1
fi

# Clone the repository directly into the target directory
git clone "$REPO_URL" "$TARGET_DIR"

# Verify if the clone was successful
if [ $? -eq 0 ]; then
    echo "Success! The repository has been cloned to: $TARGET_DIR"
else
    echo "Error: Failed to clone the repository. Check the URL or your internet connection."
    exit 1
fi
