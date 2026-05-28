import { formatDate } from "@lib/utils"
import type { CollectionEntry } from "astro:content"

type Props = {
  entry: CollectionEntry<"blog"> | CollectionEntry<"projects">
  pill?: boolean
}

export default function ArrowCard({entry, pill}: Props) {
    return (
      <a href={`/${entry.collection}/${entry.slug}`} class="editorial-card editorial-card-hover group flex items-center gap-4 p-5">
      <div class="w-full transition-colors duration-300 ease-in-out group-hover:text-zinc-950 dark:group-hover:text-ink-100">
        <div class="flex flex-wrap items-center gap-2">
          {pill &&
            <div class="rounded-full border border-black/10 px-2 py-0.5 text-xs font-semibold uppercase tracking-[0.12em] dark:border-white/10">
              {entry.collection === "blog" ? "post" : "project"}
            </div>
          }
          <div class="text-xs font-semibold uppercase tracking-[0.12em] text-zinc-500 dark:text-ink-300">
            {formatDate(entry.data.date)}
          </div>
        </div>
        <div class="mt-3 font-display text-lg font-semibold tracking-normal text-zinc-950 transition-colors duration-300 ease-in-out group-hover:text-sky-700 dark:text-ink-100 dark:group-hover:text-accent-sky">
          {entry.data.title}
        </div>

        <div class="mt-2 line-clamp-2 text-sm leading-6 text-zinc-600 dark:text-ink-300">
          {entry.data.summary}
        </div>
        <ul class="mt-4 flex flex-wrap gap-2">
          {entry.data.tags.map((tag:string) => (
            <li class="rounded-full bg-black/5 px-2.5 py-1 text-xs font-medium text-zinc-700 dark:bg-white/10 dark:text-ink-300">
              {tag}
            </li>
          ))}
        </ul>
      </div>
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="shrink-0 stroke-current text-zinc-400 transition-colors duration-300 ease-in-out group-hover:text-sky-600 dark:text-ink-300 dark:group-hover:text-accent-sky">
        <line x1="5" y1="12" x2="19" y2="12" class="scale-x-0 group-hover:scale-x-100 translate-x-4 group-hover:translate-x-1 transition-all duration-300 ease-in-out" />
        <polyline points="12 5 19 12 12 19" class="translate-x-0 group-hover:translate-x-1 transition-all duration-300 ease-in-out" />
      </svg>
    </a>
   )
}
