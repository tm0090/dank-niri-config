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
    echo "Cleaning up unwanted files..."
    
    # Remove the .git hidden folder
    rm -rf "$TARGET_DIR/.git"
    
    # Remove README.md (case-insensitive check for common variations)
    rm -f "$TARGET_DIR"/README.md "$TARGET_DIR"/readme.md
    
    # Remove the install script itself
    rm -f "$TARGET_DIR/install.sh"
    
    echo "Success! The configuration files are ready in: $TARGET_DIR"
else
    echo "Error: Failed to clone the repository."
    exit 1
fi
