#!/bin/bash

# Define variables
#REPO_DIR="kubernetes"  # Change this to your repo path
REMOTE_NAME="origin"  # Change this to your remote name
BRANCH_NAME="main"  # Change to the correct branch if needed
COMMIT_MSG="Automated backup on $(date '+%Y-%m-%d')"

# Navigate to the repository
#cd "$REPO_DIR" || exit

# Add all changes
git add .

# Commit changes
git commit -m "$COMMIT_MSG"

# Push changes to the remote repository
git push -uf "$REMOTE_NAME" "$BRANCH_NAME"

echo "Backup completed at $(date)"
