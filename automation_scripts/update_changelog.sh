#!/bin/bash

# Automated Changelog Update Script for Sage
# Usage: ./automation_scripts/update_changelog.sh

set -e

CHANGELOG="CHANGELOG.md"
DATE=$(date +%Y-%m-%d)
USER=$(git config user.name || echo "Unknown")

# Get the latest commit info
git diff --cached --name-only > /tmp/changed_files.txt
if [ ! -s /tmp/changed_files.txt ]; then
  # If no staged changes, use last commit
  SECTION=$(git show --name-only --pretty=format: | head -n 1)
else
  SECTION=$(head -n 1 /tmp/changed_files.txt)
fi

# Prompt for details
echo "Enter a short description of the change (e.g., 'Refactored feature extraction logic'):"
read -r DESCRIPTION
echo "Enter the rationale/source (e.g., 'Bug fix', 'User feedback', 'Research update'):"
read -r RATIONALE
echo "Enter the version (e.g., v1.2) or leave blank to skip:"
read -r VERSION

# Prepare the changelog entry
if [ -z "$VERSION" ]; then
  VERSION="-"
fi

ENTRY="| $DATE | $VERSION | $SECTION | $DESCRIPTION | $RATIONALE | $USER | - |"

# Create CHANGELOG.md if it doesn't exist
if [ ! -f "$CHANGELOG" ]; then
  cat <<EOF > "$CHANGELOG"
# CHANGELOG.md

All significant changes to the Sage project—including code, standards, documentation, and AI prompt updates—are documented here for transparency, reproducibility, and compliance.

| Date       | Version | Section/File Affected      | Description of Change                | Rationale/Source                | Updated By | Related Issue/PR |
|------------|---------|---------------------------|--------------------------------------|----------------------------------|------------|------------------|
EOF
fi

# Append the entry
# Insert after the header row (after the last '|' in the header)
awk -v entry="$ENTRY" 'NR==7{print entry}1' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"

echo "Changelog updated!"
cat "$CHANGELOG" | head -n 15 