#!/bin/bash
# One-time setup after cloning: checks tools, installs the git hooks, generates the Xcode project.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v xcodebuild > /dev/null || { echo "Install Xcode first." >&2; exit 1; }
command -v xcodegen > /dev/null || { echo "Install XcodeGen: brew install xcodegen" >&2; exit 1; }

git config core.hooksPath scripts/hooks
echo "Git hooks installed (pre-commit runs scripts/check.sh)"

xcodegen generate --quiet
echo "Generated WorldClock.xcodeproj"
