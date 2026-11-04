---
name: medium-post
description: Cross-post a blog article from src/content/blog to Medium (copy as rich text and open a new Medium story in Brave), and make or render a cover image (SVG to PNG). Use when the user asks to post, share or copy an article to Medium, or to make a cover/hero image for a post.
---

# Medium cross-post and cover images

All scripts are in `.claude/skills/medium-post/scripts/`. Run them as they are; don't rewrite the conversion by hand.

## Copy a post to Medium

```bash
.claude/skills/medium-post/scripts/to-medium.sh src/content/blog/<post>/index.md
```

This converts the post to HTML, puts it on the clipboard as rich text, and opens https://medium.com/new-story in Brave's "Personal" profile. Tell the user to click the title field and press Cmd+V. Medium saves it as a draft. Never publish.

Things the user must do by hand, so mention them:
- Local images are replaced with `[Image: ./file.png]` placeholders (listed on stderr). Upload them in Medium.
- Tables become code blocks (Medium has no tables). Footnotes become a "Notes" list at the end.
- Tags are set when publishing.

## Cover image

Size 1400x788 (16:9). Save `cover.svg` next to the post, render it, then look at the PNG with Read before handing it over.

```bash
.claude/skills/medium-post/scripts/svg2png.sh src/content/blog/<post>/cover.svg
```

Run it with the sandbox disabled (headless Chrome needs the display). Output is `cover.png` at 2x (2800x1576). Medium doesn't accept SVG, so give the user the PNG (`open cover.png`, then Cmd+C in Preview).

Style used so far (see `src/content/blog/20-my-first-incident/cover.svg` as the reference):
- Dark background `#0b0f17` to `#141a24`, faint dot grid, soft colored radial glows.
- Small mono pill label on top (e.g. `INCIDENT · JUL 2025`), big bold sans title (76px, weight 800) with the key phrase in an accent color, gray subtitle.
- A row of 2-3 "cards" (rounded rect `#161b22`, stroke `#30363d`, drop shadow) that tell the story visually with real-looking code, joined by dotted arrows.
- One giant, very faint mono word in the background.
- GitHub-dark syntax colors: keys `#79c0ff`, strings `#a5d6ff`, numbers `#ffa657`, purple `#d2a8ff`, red `#f85149`, amber `#e3b341`, green `#3fb950`.

SVG gotchas:
- Leading spaces inside `<text>` collapse. Indent code with a larger `x`, not spaces.
- Keep text inside its card: monospace at 20px is about 12px per character.

## Adding the cover to the site

Put `image: "./cover.png"` in the post frontmatter (used for the Open Graph image) and, if wanted, `![alt](./cover.png)` after the intro. Run `npx astro build` before committing.

Commits in this repo must not have a Co-Authored-By line.
