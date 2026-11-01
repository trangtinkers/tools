#!/usr/bin/env bash
# Collect every paragraph (block of text between blank lines) that contains
# any of the given words from the .md files in a directory, into one .md file.
#
# Usage: grep-paragraphs.sh [options] WORD [WORD...]
#   -d DIR   directory to search (default: current directory)
#   -o FILE  output file (default: DIR/matches_<words>.md)
#   -r       search subdirectories too
#   -w       whole words only ("slice" won't match "slices")
#   -c       case-sensitive (default: ignore case)
#   -h       show this help
#
# Examples:
#   grep-paragraphs.sh slice slicing
#   grep-paragraphs.sh -d ~/notes -w "dual number" infinitesimal
#   grep-paragraphs.sh -r -o ~/out.md quaternion

set -euo pipefail

usage() { sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit "${1:-0}"; }

dir=. out= recursive= whole= ignorecase=1
while getopts ':d:o:rwch' opt; do
  case $opt in
    d) dir=$OPTARG ;;
    o) out=$OPTARG ;;
    r) recursive=1 ;;
    w) whole=1 ;;
    c) ignorecase=0 ;;
    h) usage ;;
    *) usage 1 >&2 ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -gt 0 ]] || usage 1 >&2
[[ -d $dir ]] || { echo "Not a directory: $dir" >&2; exit 1; }

# Build one regex from the words, escaping regex metacharacters so each
# word is matched literally: word1|word2|...
pattern=
for w in "$@"; do
  w=$(printf '%s' "$w" | sed 's/[][\.^$*+?(){}|/]/\\&/g')
  [[ $whole ]] && w="\\<$w\\>"
  pattern+="${pattern:+|}$w"
done

if [[ -z $out ]]; then
  name=$(printf '%s_' "$@" | tr -cs '[:alnum:]_-' '_' | sed 's/_*$//')
  out="$dir/matches_$name.md"
fi

depth=(-maxdepth 1)
[[ $recursive ]] && depth=()

# Skip earlier results (and the output file itself) so they aren't re-searched.
exclude=(! -name 'matches_*.md')
[[ -e $out ]] && exclude+=(! -samefile "$out")

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

find "$dir" "${depth[@]}" -type f -name '*.md' "${exclude[@]}" -print0 | sort -z |
  PATTERN=$pattern xargs -0 -r gawk -v ic="$ignorecase" '
    BEGIN { RS = ""; IGNORECASE = ic; pat = ENVIRON["PATTERN"] }
    FNR == 1 { printed = 0 }
    $0 ~ pat {
      if (!printed) { print "## " FILENAME "\n"; printed = 1; files++ }
      print $0 "\n"; n++
    }
    END { printf "%d paragraphs from %d files\n", n, files > "/dev/stderr" }
  ' > "$tmp"

mv "$tmp" "$out"
trap - EXIT
echo "Wrote $out" >&2
