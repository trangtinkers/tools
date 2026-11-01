# tools

Small scripts I use day to day.

## yt-playlist-defuddle.sh

Bulk-extracts every video in a YouTube playlist to Markdown using [defuddle](https://github.com/kepano/defuddle). Each video becomes one note with YAML frontmatter (title, author, published date, source, description) and a timestamped `## Transcript` section. Works well for dropping a playlist into an Obsidian vault.

### Requirements

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — `brew install yt-dlp`
- Node.js (defuddle runs via `npx`, no install needed)

### Usage

```bash
./yt-playlist-defuddle.sh <playlist-url> [output-dir] [lang]
```

| Argument | Default | Description |
| --- | --- | --- |
| `playlist-url` | required | Any YouTube playlist URL |
| `output-dir` | `./<playlist title>` | Where the notes are written |
| `lang` | `en` | Preferred transcript language (BCP 47, e.g. `fr`, `ja`) |

Set `DELAY` to change the pause between videos (default 2 seconds):

```bash
DELAY=5 ./yt-playlist-defuddle.sh "https://www.youtube.com/playlist?list=..." "Notes/My Course"
```

### Behaviour

- Files are named `NNN - Video Title.md`, keeping playlist order.
- Safe to re-run: videos that already have a non-empty note are skipped, so an interrupted run picks up where it left off.
- Deleted and private videos are skipped.
- A failed video doesn't stop the run; any partial file is removed and the failure is counted in the summary.

## grep-paragraphs.sh

Pulls every paragraph that mentions any of the given words out of a folder of Markdown files and writes them to one new Markdown file, grouped by source file. See [grep-paragraphs.md](grep-paragraphs.md) for options and examples.

```bash
./grep-paragraphs.sh -d ~/notes slice slicing
```
