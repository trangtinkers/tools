#!/usr/bin/env bash
# Bulk-extract every video in a YouTube playlist to Markdown using defuddle.
# Each video becomes one note (frontmatter + transcript).
#
# Usage: ./yt-playlist-defuddle.sh <playlist-url> [output-dir] [lang]
#   output-dir  defaults to ./<playlist title>
#   lang        preferred transcript language, e.g. en (default: en)
#
# Requires: yt-dlp, node/npx (defuddle is run via npx).

set -euo pipefail

PLAYLIST_URL="${1:?Usage: $0 <playlist-url> [output-dir] [lang]}"
LANG_CODE="${3:-en}"
DELAY="${DELAY:-2}"   # seconds between requests, to be gentle with YouTube

command -v yt-dlp >/dev/null || { echo "yt-dlp not found (brew install yt-dlp)"; exit 1; }
command -v npx    >/dev/null || { echo "npx not found (install Node.js)"; exit 1; }

# Make a string safe for a filename (strip / \ : * ? " < > | and trim).
sanitize() {
  printf '%s' "$1" | tr -d '/\\:*?"<>|' | tr -s ' ' | sed 's/^ *//; s/ *$//' | cut -c1-120
}

if [[ -n "${2:-}" ]]; then
  OUT_DIR="$2"
else
  PL_TITLE=$(yt-dlp --flat-playlist --playlist-items 0 --print "%(playlist_title)s" "$PLAYLIST_URL" 2>/dev/null | head -1 || true)
  [[ -z "$PL_TITLE" || "$PL_TITLE" == "NA" ]] && PL_TITLE="youtube-playlist"
  OUT_DIR="./$(sanitize "$PL_TITLE")"
fi
mkdir -p "$OUT_DIR"

echo "Fetching playlist entries..."
ENTRIES=$(yt-dlp --flat-playlist --print "%(playlist_index)s	%(id)s	%(title)s" "$PLAYLIST_URL")
TOTAL=$(printf '%s\n' "$ENTRIES" | grep -c . || true)
echo "Found $TOTAL videos -> $OUT_DIR"

ok=0; skipped=0; failed=0
while IFS=$'\t' read -r idx id title; do
  [[ -z "$id" ]] && continue
  # Skip deleted/private placeholders
  if [[ "$title" == "[Deleted video]" || "$title" == "[Private video]" ]]; then
    echo "[$idx/$TOTAL] skip (unavailable): $id"; ((skipped++)) || true; continue
  fi

  file="$OUT_DIR/$(printf '%03d' "$idx") - $(sanitize "$title").md"
  if [[ -s "$file" ]]; then
    echo "[$idx/$TOTAL] exists, skipping: $title"; ((skipped++)) || true; continue
  fi

  echo "[$idx/$TOTAL] $title"
  if npx -y defuddle parse "https://www.youtube.com/watch?v=$id" \
       --markdown --frontmatter --lang "$LANG_CODE" -o "$file" 2>/dev/null && [[ -s "$file" ]]; then
    ((ok++)) || true
  else
    echo "   ! failed: $id"; rm -f "$file"; ((failed++)) || true
  fi
  sleep "$DELAY"
done <<< "$ENTRIES"

echo "Done. extracted=$ok skipped=$skipped failed=$failed  ($OUT_DIR)"
