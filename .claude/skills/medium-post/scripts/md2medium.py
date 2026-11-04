#!/usr/bin/env python3
"""Convert a blog post (Astro markdown/MDX) into HTML that pastes cleanly into Medium.

Usage: md2medium.py <post/index.md|mdx> <out.html>

Handles: frontmatter title, ##/### headings, paragraphs, fenced code, ordered and
unordered lists (one level of nesting), blockquotes, links, bold, italic, inline
code, footnotes (moved to a "Notes" list at the end), tables (rendered as a code
block, since Medium has no tables), <details>/<summary> (unwrapped), and MDX
import/JSX lines (dropped). Local images are dropped and listed on stderr so
they can be uploaded to Medium by hand.
"""
import html
import re
import sys


def inline(text, footnotes_order):
    parts = re.split(r"(`[^`]+`)", text)
    out = []
    for part in parts:
        if part.startswith("`") and part.endswith("`") and len(part) > 1:
            out.append("<code>" + html.escape(part[1:-1], quote=False) + "</code>")
            continue
        t = html.escape(part, quote=False)
        t = re.sub(r"\[\^([^\]]+)\]", lambda m: _fnref(m.group(1), footnotes_order), t)
        t = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', t)
        t = re.sub(r"(?<![\"'(])(https?://[^\s<)]+)", r'<a href="\1">\1</a>', t)
        t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
        t = re.sub(r"(?<![*\w])\*([^*\n]+)\*(?![*\w])", r"<em>\1</em>", t)
        t = re.sub(r"(?<![\w])_([^_\n]+)_(?![\w])", r"<em>\1</em>", t)
        out.append(t)
    return "".join(out)


def _fnref(key, order):
    if key not in order:
        order.append(key)
    return "<sup>[" + str(order.index(key) + 1) + "]</sup>"


def main(src_path, out_path):
    src = open(src_path, encoding="utf-8").read()
    title = ""
    m = re.match(r"^---\n(.*?)\n---\n", src, re.S)
    if m:
        fm, src = m.group(1), src[m.end():]
        t = re.search(r'^title:\s*["\']?(.*?)["\']?\s*$', fm, re.M)
        title = t.group(1) if t else ""

    lines = src.split("\n")
    footnote_defs = {}
    body = []
    for line in lines:
        fd = re.match(r"^\[\^([^\]]+)\]:\s*(.*)$", line)
        if fd:
            footnote_defs[fd.group(1)] = fd.group(2)
        elif re.match(r"^\s*import .* from ", line):
            continue
        elif re.match(r"^\s*<(?!details|/details|summary)[A-Z][\w.]*[\s/>]", line):
            continue  # MDX component
        else:
            body.append(line)

    fn_order = []
    out = ["<h1>" + html.escape(title) + "</h1>"] if title else []
    para = []
    dropped_images = []

    def flush():
        if para:
            out.append("<p>" + inline(" ".join(para), fn_order) + "</p>")
            para.clear()

    i = 0
    n = len(body)
    while i < n:
        line = body[i]
        s = line.strip()

        if s.startswith("```"):
            flush()
            i += 1
            code = []
            while i < n and not body[i].strip().startswith("```"):
                code.append(body[i])
                i += 1
            out.append("<pre>" + html.escape("\n".join(code), quote=False) + "</pre>")
            i += 1
            continue

        if s.startswith("|") and i + 1 < n and re.match(r"^\s*\|[\s:|-]+\|\s*$", body[i + 1]):
            flush()
            rows = []
            while i < n and body[i].strip().startswith("|"):
                if not re.match(r"^\s*\|[\s:|-]+\|\s*$", body[i]):
                    rows.append([c.strip() for c in body[i].strip().strip("|").split("|")])
                i += 1
            widths = [max(len(r[c]) for r in rows if c < len(r)) for c in range(len(rows[0]))]
            text = "\n".join(
                "  ".join(r[c].replace("`", "").replace("**", "").ljust(widths[c]) for c in range(len(r)))
                .rstrip() for r in rows
            )
            out.append("<pre>" + html.escape(text, quote=False) + "</pre>")
            continue

        img = re.match(r"^!\[([^\]]*)\]\(([^)]+)\)\s*$", s)
        if img:
            flush()
            src_url = img.group(2)
            if src_url.startswith("http"):
                out.append('<figure><img src="%s" alt="%s"><figcaption>%s</figcaption></figure>'
                           % (src_url, html.escape(img.group(1)), html.escape(img.group(1))))
            else:
                dropped_images.append(src_url)
                out.append("<p><em>[Image: " + html.escape(src_url) + "]</em></p>")
            i += 1
            continue

        h = re.match(r"^(#{1,4})\s+(.*)$", s)
        if h:
            flush()
            level = 3 if len(h.group(1)) <= 3 else 4
            out.append("<h%d>%s</h%d>" % (level, inline(h.group(2), fn_order), level))
            i += 1
            continue

        if re.match(r"^(\d+\.|[-*])\s+", s) and not line.startswith("   "):
            flush()
            ordered = bool(re.match(r"^\d+\.", s))
            items = []
            while i < n:
                l = body[i]
                if re.match(r"^(\d+\.|[-*])\s+", l):
                    items.append([re.sub(r"^(\d+\.|[-*])\s+", "", l.strip()), []])
                elif re.match(r"^\s{2,}[-*]\s+", l) and items:
                    items[-1][1].append(re.sub(r"^\s*[-*]\s+", "", l))
                elif l.strip() and l.startswith("  ") and items:
                    items[-1][0] += " " + l.strip()
                elif l.strip() == "" and i + 1 < n and re.match(r"^(\d+\.|[-*])\s+", body[i + 1]):
                    pass
                else:
                    break
                i += 1
            tag = "ol" if ordered else "ul"
            html_items = ""
            for text, sub in items:
                subhtml = "<ul>" + "".join("<li>" + inline(x, fn_order) + "</li>" for x in sub) + "</ul>" if sub else ""
                html_items += "<li>" + inline(text, fn_order) + subhtml + "</li>"
            out.append("<%s>%s</%s>" % (tag, html_items, tag))
            continue

        if s.startswith(">"):
            flush()
            quote = []
            while i < n and body[i].strip().startswith(">"):
                quote.append(body[i].strip().lstrip(">").strip())
                i += 1
            out.append("<blockquote>" + inline(" ".join(quote), fn_order) + "</blockquote>")
            continue

        if re.match(r"^</?details>|^<summary>", s):
            flush()
            sm = re.match(r"^<summary>(.*)</summary>$", s)
            if sm:
                out.append("<p><strong>" + re.sub(r"<[^>]+>", "", sm.group(1)) + "</strong></p>")
            i += 1
            continue

        if s == "" or s == "---":
            flush()
        else:
            para.append(s)
        i += 1
    flush()

    if fn_order:
        out.append("<h4>Notes</h4>")
        out.append("<ol>" + "".join(
            "<li>" + inline(footnote_defs.get(k, ""), []) + "</li>" for k in fn_order) + "</ol>")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write('<meta charset="utf-8">' + "\n".join(out))
    for img in dropped_images:
        print("upload by hand: " + img, file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
