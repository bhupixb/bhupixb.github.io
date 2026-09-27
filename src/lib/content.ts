import { getCollection } from "astro:content"

export async function getPublished<C extends "blog" | "projects">(collection: C) {
  const entries = await getCollection(collection, ({ data }) => !data.draft)
  return entries.sort((a, b) => b.data.date.getTime() - a.data.date.getTime())
}
