# Thalium's Blog

A small, dark-themed personal blog built with [Astro](https://astro.build), Tailwind CSS and Cloudflare Workers. Live at [blog.thethalium.ch](https://blog.thethalium.ch).

## Commands

| Command           | Action                                    |
| :---------------- | :---------------------------------------- |
| `npm install`     | Install dependencies                      |
| `npm run dev`     | Start local dev server at `localhost:4321`|
| `npm run build`   | Build the production site to `./dist/`    |
| `npm run preview` | Preview the build locally                 |
| `npm run check`   | Type-check the project (`astro check`)    |

## Writing a post

Add a Markdown file to `src/content/blog/`. The filename (without `.md`) becomes the URL slug.

```markdown
---
title: My Post Title
pubDate: 2026-10-08
description: One-sentence summary shown on the index page and in SEO/RSS.
author: Thalium        # optional, defaults to "Thalium"
tags: [linux, rust]    # optional
draft: false           # optional, true hides it from the site and RSS
---

Your content here.
```

## Translations

Posts can be translated by creating a copy with a two-letter locale suffix, e.g.
`my-post.md` (English, default) and `my-post.de.md` (German). Each language must be a
separate file; posts with the same base slug are linked as translations of each other.

## Deployment

Deployed as a static site on Cloudflare Workers via `wrangler` (see `wrangler.jsonc`).
