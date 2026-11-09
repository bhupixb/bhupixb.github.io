---
name: explainer
description: Add a standalone HTML explainer (usually a Claude artifact) to the site under /explainer/, with a context box, metadata and favicon so it explains itself to a public reader. Each explainer keeps its own theme. Use when the user wants to publish, add or import an HTML explainer, primer, artifact or interactive page, or fix up an existing one.
---

# Explainers

Explainers are self-contained HTML pages that Claude built for the user while they were learning something. They live outside the Astro blog:

| Path | What it is |
|---|---|
| `public/explainer/<slug>.html` | One explainer. Astro copies it to `/explainer/<slug>.html` as is, with no layout around it. |
| `src/pages/explainer/index.astro` | The `/explainer/` list. Reads each file's `<title>` and meta tags at build time. |

**Each explainer keeps its own theme.** There is no shared stylesheet, and that is deliberate: a shared theme was tried and dropped because it made the pages look worse. Don't restyle a page to match the other explainers or the main site. Any new element (such as the context box) is styled with the page's own CSS variables and fonts.

## Adding an explainer

1. **Read the whole source file first.** Then copy it to `public/explainer/<slug>.html`, using a short kebab-case slug such as `gcp-psc-step-by-step`.

2. **Add the head block** right after the `<meta name=viewport …>` tag in `<head>`:
   ```html
   <meta name="description" content="One or two sentences: the problem and what the page shows.">
   <meta name="note:date" content="YYYY-MM-DD">
   <meta name="note:tags" content="gcp, networking">
   <meta name="author" content="Bhupendra Yadav">
   <link rel="icon" type="image/svg+xml" href="/favicon.svg">
   <link rel="icon" type="image/png" sizes="48x48" href="/favicon.png">
   <link rel="apple-touch-icon" href="/apple-touch-icon.png">
   ```
   Nothing wraps the page, so without the icon links the browser tab shows no logo. Change the `<title>` to a clear name, which the index page shows.

3. **Add the context box** as the first child of the main content column. A reader arriving from a search or a shared link must understand the page without the chat it came from:
   ```html
   <aside class="about" aria-label="About this explainer">
     <div class="meta"><a href="/explainer/">&larr; Explainers</a><span>Bhupendra Yadav</span><span>Mon YYYY</span><a href="/">bhupixb.github.io</a></div>
     <dl>
       <dt>The problem</dt>
       <dd>The situation and why it is hard. Concrete, 2 to 4 sentences.</dd>
       <dt>What this page is</dt>
       <dd>What the page does and how to use it. Then say where it came from, e.g. "Claude built it for me while I was learning X."</dd>
       <dt>Words used below</dt>   <!-- only if the page uses "we", company names or jargon -->
       <dd>…</dd>
       <dt>Assumes</dt>
       <dd>What the reader should already know.</dd>
     </dl>
   </aside>
   ```
   Style it in the page's own `<style>` with the page's variables, so it looks native: a surface background, a border, a 4px left border in the page's accent color, small uppercase `dt` labels, and muted text for `.meta`. For example:
   ```css
   .about { background: var(--surface); border: 1px solid var(--line); border-left: 4px solid var(--accent); border-radius: 8px; padding: 14px 16px; display: grid; gap: 8px; font-size: 15px; }
   .about .meta { font-size: 13px; color: var(--muted); display: flex; flex-wrap: wrap; gap: 4px 14px; }
   .about .meta a { color: var(--muted); }
   .about dl { margin: 0; display: grid; gap: 6px; }
   .about dt { font-size: 12px; font-weight: 600; letter-spacing: .06em; text-transform: uppercase; color: var(--muted); }
   .about dd { margin: 0 0 4px; max-width: 72ch; }
   ```
   Rename the variables to whatever the page calls them, and match its border radius and label font.

4. **Clean up the content:**
   - Remove or replace `claude.ai/artifact/…` links, which public readers can't open. Link official docs instead.
   - Code that uses `window.claude.*` or other artifact runtime features doesn't work here. Remove it or tell the user.
   - **No third-party requests.** The site is privacy-focused. If the page loads Google Fonts or anything else from a CDN, self-host it. For fonts: fetch the Google Fonts CSS with a browser User-Agent, download the `latin` woff2 files into `public/explainer/fonts/` (reuse files that are already there), replace the `<link>` tags with `@font-face` rules pointing at `/explainer/fonts/…`, and add the font to `public/explainer/fonts/README.md` with its license. Afterwards, `grep -n 'https://' public/explainer/<slug>.html` should show only plain `<a href>` links.
   - Link named tools and projects to their homepage or repo.
   - End the `<footer>` with links to further reading and `More <a href="/explainer/">explainers</a>`.
   - Never say the user made or wrote the page. Say Claude built it for them.
   - If the page describes the user's employer's internals (they work at Yugabyte), point that out and let them decide what is fine to publish.

5. **Verify,** as described below.

## Verify

```bash
npm run build                      # must end with "Complete!" and 0 errors
npx astro preview --port 4329 &    # serves dist/
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$C" --headless=new --hide-scrollbars --virtual-time-budget=4000 --window-size=1280,2200 \
  --screenshot=<scratchpad>/shot.png http://localhost:4329/explainer/<slug>.html
```
Look at the screenshot. The context box should sit on top and look native to the page, and the rest of the page should look exactly as it did before. Also check the `/explainer/` list. Headless Chrome won't render narrower than about 500px, so to check phone width, screenshot a scratch page that loads the explainer in a `<iframe style="width:375px">`. Stop the preview server when done.

Commit only the explainer files, and don't push unless asked. A push to `main` deploys the site.
