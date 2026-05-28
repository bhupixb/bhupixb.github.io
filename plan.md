You are working in my Astro personal website repo: https://github.com/bhupixb/bhupixb.github.io

Goal:
Redesign the website into a polished, dark-first technical editorial portfolio/blog for a backend + infrastructure engineer. Keep the current Astro setup, content collections, blog/projects functionality, routing, SEO, RSS, sitemap, and existing content. Do NOT migrate to a new theme. Improve typography, layout, visual hierarchy, spacing, and component styling.

Important constraints:
- Make this an incremental redesign, not a rewrite.
- Preserve all existing routes and content.
- Preserve markdown/MDX blog support.
- Preserve dark/light mode if already present.
- Avoid heavy animation libraries.
- Avoid large UI frameworks.
- Avoid unnecessary dependencies.
- Do not introduce React/Solid/Vue unless already used in the project and needed.
- Keep the site fast and static-friendly.
- Run the existing build/typecheck/lint commands if present.
- If any command fails due to unrelated existing issues, explain clearly.

Design direction:
Create a clean technical editorial aesthetic inspired by Linear / Vercel / Supabase docs / high-quality engineering blogs.

Visual style:
- Dark-first
- Calm, sharp, premium
- Technical but not boring
- Minimal gradients
- Subtle radial glow behind hero
- Optional subtle grid/noise background
- Card-based sections
- 1px borders
- Soft hover states
- Good spacing and typography
- No heavy particle effects or flashy animations

Preferred palette:
- Background: #08090A
- Surface/card: #111318
- Elevated card: #151821
- Border: #23262F
- Text: #EDEEF0
- Muted text: #9CA3AF
- Accent: #38BDF8
- Secondary accent: #A3E635

Typography:
Use a better font system.
Preferred:
- Headings: Space Grotesk
- Body: Inter
- Code: JetBrains Mono

Implementation:
1. Inspect current package manager and dependencies.
2. If fontsource is already used, add:
   - @fontsource/inter
   - @fontsource/space-grotesk
   - @fontsource/jetbrains-mono
   Otherwise use the project’s existing font-loading style if there is one.
3. Update Tailwind config/theme tokens if this project uses Tailwind config.
4. Replace the current font stack:
   - font-sans => Inter
   - font-display => Space Grotesk
   - font-mono => JetBrains Mono
5. Ensure global CSS has good defaults:
   - dark background
   - smooth text rendering
   - better selection color
   - readable prose styles
   - code block styling
   - link hover styling

Homepage redesign:
Restructure the homepage into these sections:

1. Hero
   Replace generic intro with a stronger engineering-positioned hero.

   Suggested copy:
   “Backend & Infrastructure Engineer”

   Supporting text:
   “I build reliable backend systems, Kubernetes platforms, and production-grade Java services. I write about backend engineering, infrastructure, distributed systems, and practical software craftsmanship.”

   Add skill chips:
   Java, Spring Boot, PostgreSQL, Kubernetes, Docker, AWS, Flink, OpenAPI

   Add CTA buttons:
   - Read technical notes
   - View projects
   - GitHub

2. What I work on
   Add 4 cards:
   - Backend Engineering
     Java, Spring Boot, REST APIs, service design, OpenAPI
   - Infrastructure
     Docker, Kubernetes, Helm, ArgoCD, CI/CD
   - Data & Streaming
     Flink, Airflow, Trino, production data jobs
   - Security Curiosity
     Android, networking, web security, practical debugging notes

3. Featured / Recent Writing
   Keep using existing blog data.
   Improve blog card layout:
   - date
   - title
   - one-line description
   - tags if available
   - reading time if already available
   - hover border/accent effect

4. Featured / Recent Projects
   Keep using existing project data.
   Improve cards:
   - title
   - description
   - tags/tech if available
   - external links if available
   - subtle hover state

5. Technical Stack
   Replace plain text stack with categorized groups:
   - Languages: Java, Python, Bash, C++
   - Backend: Spring Boot, REST, OpenAPI, PostgreSQL
   - Infrastructure: Docker, Kubernetes, Helm, ArgoCD, Jenkins
   - Data: Flink, Airflow, Trino
   Adjust based on existing content; do not invent too much if current data differs.

6. Contact / Social
   Make social links visually cleaner.
   Use simple icon/text links if icons already exist.
   Do not add an icon dependency unless the project already has one.

Component work:
- Create or improve reusable components where helpful:
  - SectionHeading
  - Pill/Tag
  - Card
  - CTAButton
  - WorkAreaCard
  - BlogCard
  - ProjectCard
- Keep components simple Astro components unless the existing project already uses another component model.

Navigation:
- Keep existing nav routes.
- Make nav visually cleaner:
  - sticky or simple top nav
  - translucent dark background
  - border bottom
  - clear active/hover states
- Preserve mobile responsiveness.

Blog/article pages:
Improve readability:
- Better max width
- Better line height
- Better headings
- Better code blocks
- Better inline code
- Better blockquotes
- Better tables if present
- Better link styling
- Preserve all existing markdown behavior

Responsive behavior:
- Mobile-first
- Hero should look good on mobile
- Cards should stack on mobile
- Use 2-column or 3-column grids on desktop where appropriate
- Avoid horizontal overflow

Accessibility:
- Keep good contrast
- Preserve semantic headings
- Buttons/links must have visible focus states
- Do not rely only on color for meaning

Performance:
- Avoid large background images.
- Avoid client-side JS unless needed.
- Keep animations CSS-only and minimal.
- No unnecessary npm packages.

Concrete implementation steps:
1. Inspect:
   - package.json
   - astro.config.*
   - tailwind.config.*
   - src/layouts
   - src/pages/index.astro
   - src/components
   - src/styles or global CSS
   - content collections
2. Identify current homepage components and data sources.
3. Implement the visual redesign.
4. Update fonts.
5. Update global styles and Tailwind theme.
6. Verify all pages compile.
7. Run formatting if project supports it.
8. Run build.
9. Provide a final summary with:
   - files changed
   - design changes made
   - commands run
   - any follow-up manual checks

Do not:
- Replace the site with AstroWind or another full template.
- Delete existing content.
- Break blog/project routes.
- Add a CMS.
- Add animation-heavy libraries.
- Add shadcn/ui, Flowbite, DaisyUI, or similar.
- Make the site look like a generic SaaS landing page.
- Overuse gradients.
- Overuse emojis.
- Change personal details unless already present in content.

Acceptance criteria:
- Homepage feels like a polished engineering portfolio.
- Typography is noticeably better.
- Blog and project cards look premium.
- Mobile layout is clean.
- Existing content still works.
- `npm run build` or the repo’s equivalent build command passes.
- The diff is focused and reviewable.