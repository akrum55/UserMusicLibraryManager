#!/usr/bin/env bash
#
# build.sh — build UserMusicLibraryManager from the command line and, if the
# build succeeds, stage and commit the current changes.
#
# Usage:
#   ./build.sh                 # build, then commit with an auto-generated message
#   ./build.sh "fix track num" # build, then commit with your message
#   ./build.sh --no-commit     # build only, don't touch git
#
# First-time setup:  chmod +x build.sh

set -euo pipefail

# --- Config -----------------------------------------------------------------
PROJECT="UserMusicLibraryManager.xcodeproj"
SCHEME="UserMusicLibraryManager"
CONFIGURATION="Debug"
# ----------------------------------------------------------------------------

# Move to the directory this script lives in, so it works from anywhere.
cd "$(dirname "$0")"

NO_COMMIT=false
MSG=""

for arg in "$@"; do
  case "$arg" in
    --no-commit) NO_COMMIT=true ;;
    *) MSG="$arg" ;;
  esac
done

echo "==> Building $SCHEME ($CONFIGURATION)..."

# Code signing is disabled here on purpose — command-line builds of this app
# fail with signing errors otherwise.
if xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
    build; then
  echo "==> Build succeeded."
else
  echo "==> Build FAILED. Not committing." >&2
  exit 1
fi

if [ "$NO_COMMIT" = true ]; then
  echo "==> --no-commit set, done."
  exit 0
fi

# Only commit if there's something to commit.
if [ -z "$(git status --porcelain)" ]; then
  echo "==> Working tree clean, nothing to commit."
  exit 0
fi

if [ -z "$MSG" ]; then
  MSG="Build passed — $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "==> Committing: $MSG"
git add -A
git commit -m "$MSG"

echo "==> Done. To publish:  git push"
