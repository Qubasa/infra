# qubasa-blog

Static blog engine for [qubasa.blog](https://qubasa.blog), ported from
clan-core's `clan-site`. It keeps the Markdown pipeline (Shiki syntax
highlighting, admonitions, tabs, table of contents) and renders posts from
`posts/*.md` into a fully static site with full-text search (Pagefind), tag
pages, and an RSS feed.

## Writing posts

Add a Markdown file to `posts/`. The filename is the slug. Frontmatter:

```markdown
---
title: My post
date: 2026-07-08
description: A one-line summary shown in listings and the feed.
tags: [nixos, meta]
draft: false
---

# My post

Content…
```

`draft: true` hides the post from production builds (still visible in `dev`).

## Developing

Start the dev server (installs npm deps on first run):

```sh
qubasa-blog dev
```

Add `-b` to open a browser tab.

## Building

```sh
qubasa-blog build        # outputs the static site to build/
nix build .#qubasa-blog  # same, as a Nix package
```

The Nix package output is served directly by nginx (see
`machines/gchq-local/blog.nix`); deploying is a machine rebuild.

## Linting

```sh
qubasa-blog lint         # prettier + eslint + stylelint + svelte-check
qubasa-blog lint --fix
```
