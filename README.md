# bhupixb.github.io

Personal site and blog built with [Astro](https://astro.build/), based on the Astro Sphere theme.

## Requirements

- Node.js `22.13.1` or newer
- npm, using the committed `package-lock.json`

If you use `nvm`, run:

```bash
nvm use
```

## Install Dependencies

Use `npm ci` instead of `npm install` for local setup. `npm ci` installs exactly what is recorded in `package-lock.json` and fails if the lockfile and `package.json` disagree.

This repo commits an `.npmrc` with:

```ini
save-exact=true
min-release-age=7
```

`min-release-age=7` prevents npm from resolving package versions published less than seven days ago. That delay reduces exposure to freshly published malicious packages before the wider ecosystem has had time to detect and report them.

For the lowest supply chain risk, install without running package lifecycle scripts first:

```bash
npm ci --ignore-scripts
```

Then run the build:

```bash
npm run build
```

If the build fails because `sharp` did not install its native binary, rebuild only that package:

```bash
npm rebuild sharp
npm run build
```

Avoid running `npm install` during normal local setup. Use it only when intentionally changing dependencies, and review the resulting `package-lock.json` diff before committing.

## Run Locally

Start the local dev server:

```bash
npm run dev
```

Astro will print the local URL, usually:

```text
http://localhost:4321/
```

To expose the dev server on your local network:

```bash
npm run dev:network
```

## Build And Preview

Build the static site:

```bash
npm run build
```

Preview the production build locally:

```bash
npm run preview
```

## Supply Chain Safety Notes

- Prefer `npm ci --ignore-scripts` for fresh installs.
- Keep `min-release-age=7` or higher in `.npmrc`.
- Keep `package-lock.json` committed and review lockfile changes carefully.
- Do not install dependencies from untrusted branches without reading `package.json` changes first.
- Do not run unfamiliar `npm` scripts without checking `package.json`.
- Use `npm audit` as a signal, then verify issues before upgrading dependencies.
- When updating dependencies, prefer small focused updates over broad upgrades.

## Useful Checks

Check Astro types and build output:

```bash
npm run build
```

Inspect generated social metadata after a build:

```bash
grep -E 'og:|twitter:|canonical' dist/blog/11-minimal-mitv-launcher/index.html
```
