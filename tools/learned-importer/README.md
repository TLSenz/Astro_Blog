# Learned Importer

A tiny native macOS app for adding notes to the **Things I Learned** section of the blog.

Drop in a Markdown file, give it a title, and the app writes a note with frontmatter to
`src/content/learned/`. The note shows up on `/learned` the next time the site is built.

## Build and install

```bash
cd tools/learned-importer
./build.sh
```

The app is built into `build/Learned Importer.app` and installed to
`~/Applications/Learned Importer.app`. Use `./build.sh --no-install` to skip the install step.

The build uses only the Xcode Command Line Tools (`swiftc`, `sips`, `iconutil`).

## Usage

1. Drop a `.md`/`.markdown` file onto the window (or press `⌘O`).
2. Check the title, summary, date, tags and slug. The title and summary are filled in
   automatically from the file's `# Heading` and first paragraph.
3. Press **Import Note** (`⌘↩`).

The file is written to `src/content/learned/<slug>.md`. Use **Reveal** in the footer to show it
in Finder. The blog folder is detected at build time; use **Change…** if the repository moves.

Enable **Commit and push after saving** if you want the app to run `git add`, `git commit` and
`git push` for the new note.

## Frontmatter produced

```markdown
---
title: "Short title"
date: 2026-11-12
summary: "One sentence shown on the list page."
tags: ["rust", "linux"]
source: "https://example.com"
---

The note body.
```

`summary`, `tags` and `source` are optional.

## Uninstall

```bash
rm -rf ~/Applications/"Learned Importer.app"
```
