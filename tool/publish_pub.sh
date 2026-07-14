#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT_DIR/pubspec.yaml"
LOCKFILE="$ROOT_DIR/pubspec.lock"
PUBSPEC_BACKUP="$(mktemp)"
LOCKFILE_BACKUP="$(mktemp)"
HAD_LOCKFILE=0

restore_files() {
  cp "$PUBSPEC_BACKUP" "$PUBSPEC"
  if [[ "$HAD_LOCKFILE" == "1" ]]; then
    cp "$LOCKFILE_BACKUP" "$LOCKFILE"
  else
    rm -f "$LOCKFILE"
  fi
  rm -f "$PUBSPEC_BACKUP" "$LOCKFILE_BACKUP"
}

cp "$PUBSPEC" "$PUBSPEC_BACKUP"
if [[ -f "$LOCKFILE" ]]; then
  HAD_LOCKFILE=1
  cp "$LOCKFILE" "$LOCKFILE_BACKUP"
fi
trap restore_files EXIT

perl -0pi -e 's/^\s+cupertino_icons:\s*\S+\n//m; s/\n  assets:\n(?:    - .+\n)+/\n/s' "$PUBSPEC"

cd "$ROOT_DIR"
PUB_HOSTED_URL="${PUBLISH_PUB_HOSTED_URL:-https://pub.dev}" dart pub publish "$@"
