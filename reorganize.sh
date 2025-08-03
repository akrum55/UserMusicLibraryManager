#!/usr/bin/env bash
set -euo pipefail

SRC="UserMusicLibraryManager"
DST="Sources"

# 1. Create the target folders under Sources/
mkdir -p "${DST}/Cache"
mkdir -p "${DST}/Metadata"
mkdir -p "${DST}/Extensions/AVFoundation"
mkdir -p "${DST}/Extensions/FileManager"
mkdir -p "${DST}/Extensions/Images"
mkdir -p "${DST}/Models/User"
mkdir -p "${DST}/Models"
mkdir -p "${DST}/Utilities"
mkdir -p "${DST}/Views"

# Helper: safe_move <file> <dest-folder>
#  - if tracked in Git, use git mv
#  - else mv + git add
safe_move() {
  local srcfile="$1"
  local destdir="$2"
  local filename
  filename="$(basename "$srcfile")"
  if git ls-files --error-unmatch "$srcfile" &>/dev/null; then
    git mv "$srcfile" "$destdir/"
  else
    mv "$srcfile" "$destdir/"
    git add "$destdir/$filename"
  fi
}

# 2. Move Cache .swift
if [ -d "${SRC}/Cache" ]; then
  for f in "${SRC}/Cache"/*.swift; do
    [ -e "$f" ] && safe_move "$f" "${DST}/Cache"
  done
fi

# 3. Move Metadata .swift
if [ -d "${SRC}/Metadata" ]; then
  for f in "${SRC}/Metadata"/*.swift; do
    [ -e "$f" ] && safe_move "$f" "${DST}/Metadata"
  done
fi

# 4. Move Extensions .swift
for sub in AVFoundation FileManager Images; do
  if [ -d "${SRC}/Extensions/$sub" ]; then
    for f in "${SRC}/Extensions/$sub"/*.swift; do
      [ -e "$f" ] && safe_move "$f" "${DST}/Extensions/$sub"
    done
  fi
done

# 5. Move Models .swift (top-level + User)
if [ -d "${SRC}/Models" ]; then
  for f in "${SRC}/Models"/*.swift; do
    [ -e "$f" ] && safe_move "$f" "${DST}/Models"
  done
  if [ -d "${SRC}/Models/User" ]; then
    for f in "${SRC}/Models/User"/*.swift; do
      [ -e "$f" ] && safe_move "$f" "${DST}/Models/User"
    done
  fi
fi

# 6. Move Utilities .swift
if [ -d "${SRC}/Utilities" ]; then
  for f in "${SRC}/Utilities"/*.swift; do
    [ -e "$f" ] && safe_move "$f" "${DST}/Utilities"
  done
fi

# 7. Move Views .swift
if [ -d "${SRC}/Views" ]; then
  for f in "${SRC}/Views"/*.swift; do
    [ -e "$f" ] && safe_move "$f" "${DST}/Views"
  done
fi

# 8. Move the App entrypoint
if [ -f "${SRC}/UserMusicLibraryManagerApp.swift" ]; then
  safe_move "${SRC}/UserMusicLibraryManagerApp.swift" "${DST}"
fi

# 9. Clean up empty dirs under SRC
find "${SRC}" -type d -empty -delete

echo "🎉 Reorg done. Re-open Xcode, fix imports & remove any red refs."
