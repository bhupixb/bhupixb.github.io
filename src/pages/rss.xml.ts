import rss from "@astrojs/rss"
import type { APIContext } from "astro"
import { SITE } from "@consts"
import { getPublished } from "@lib/content"

export async function GET(context: APIContext) {
  const items = [...(await getPublished("blog")), ...(await getPublished("projects"))]
    .sort((a, b) => b.data.date.getTime() - a.data.date.getTime())

  return rss({
    title: SITE.TITLE,
    description: SITE.DESCRIPTION,
    site: context.site ?? "",
    items: items.map((item) => ({
      title: item.data.title,
      description: item.data.summary,
      pubDate: item.data.date,
      link: `/${item.collection}/${item.id}/`,
    })),
  })
}
