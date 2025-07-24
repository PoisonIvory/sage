#!/bin/bash
# Pre-commit check: run tests, check docstrings, and changelog

echo "Running all tests..."
xcodebuild test -scheme Sage -destination 'platform=iOS Simulator,name=iPhone 15' || { echo "Tests failed! Commit aborted."; exit 1; }

echo "Checking for required docstrings in SwiftUI files..."
missing_docs=0
for file in $(find Sage/DesignSystem Sage/Views/Onboarding -name '*.swift'); do
  if ! grep -q "Implements" "$file"; then
    echo "Missing docstring in $file"
    missing_docs=1
  fi
done
if [ $missing_docs -ne 0 ]; then
  echo "One or more files are missing required docstrings. Commit aborted."
  exit 1
fi

echo "Checking CHANGELOG.md..."
if ! grep -q "$(date +%Y-%m-%d)" CHANGELOG.md; then
  echo "CHANGELOG.md does not have an entry for today ($(date +%Y-%m-%d))."
  echo "Please run: bash automation_scripts/update_changelog.sh"
  exit 1
fi

echo "All checks passed. Proceeding with commit." 