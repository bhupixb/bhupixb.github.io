import { defineCollection } from "astro:content"
import { glob } from "astro/loaders"
import { z } from "astro/zod"

const work = defineCollection({
  loader: glob({ base: "./src/content/work", pattern: "**/*.md" }),
  schema: z.object({
    company: z.string(),
    role: z.string().optional(),
    dateStart: z.coerce.date(),
    dateEnd: z.union([z.coerce.date(), z.string()]),
  }),
})

const blog = defineCollection({
  loader: glob({ base: "./src/content/blog", pattern: "**/*.{md,mdx}" }),
  schema: ({ image }) => z.object({
    title: z.string(),
    summary: z.string(),
    image: image().optional(),
    date: z.coerce.date(),
    tags: z.array(z.string()),
    draft: z.boolean().optional(),
  }),
})

const projects = defineCollection({
  loader: glob({ base: "./src/content/projects", pattern: "**/*.{md,mdx}" }),
  schema: z.object({
    title: z.string(),
    summary: z.string(),
    date: z.coerce.date(),
    tags: z.array(z.string()),
    draft: z.boolean().optional(),
    demoUrl: z.string().optional(),
    repoUrl: z.string().optional(),
  }),
})

export const collections = { work, blog, projects }
