# grep-paragraphs.sh

Collects every paragraph (a block of text between blank lines) that contains any of the given words from the Markdown files in a directory, and writes them to one new Markdown file. Each match is grouped under a `## <filename>` heading, so you can see where it came from. This works well for pulling every passage on a topic out of a folder of transcripts or notes.

### Requirements

- GNU awk (`gawk`). It ships with most Linux distros. On macOS, run `brew install gawk`.

### Usage

```bash
./grep-paragraphs.sh [options] WORD [WORD...]
```

| Option | Default | Description |
| --- | --- | --- |
| `-d DIR` | `.` | Directory to search |
| `-o FILE` | `DIR/matches_<words>.md` | Output file |
| `-r` | off | Search subdirectories too |
| `-w` | off | Whole words only (`slice` won't match `slices`) |
| `-c` | off | Case-sensitive (case is ignored by default) |
| `-h` | | Show help |

A paragraph matches if it contains **any** of the words. Quote a phrase to search for it as one term.

```bash
# Every paragraph mentioning slice, slices, sliced or slicing
./grep-paragraphs.sh slice slicing

# Whole-word search for a phrase or a word in another folder
./grep-paragraphs.sh -d ~/notes -w "dual number" infinitesimal

# Search a whole tree and choose the output file
./grep-paragraphs.sh -r -o ~/all-quaternions.md quaternion
```

### Behaviour

- Words are matched literally, so `x^n` or `a.b` work as typed, with no regex escaping needed.
- Files are processed in sorted order, and paragraphs keep the order they have in each file.
- Safe to re-run: `matches_*.md` files and the output file are never searched, so earlier results don't feed back into new ones.
- A summary is printed to stderr when it finishes, e.g. `32 paragraphs from 9 files`.
