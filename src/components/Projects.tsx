import type { CollectionEntry } from "astro:content"
import { createEffect, createSignal, For } from "solid-js"
import ArrowCard from "@components/ArrowCard"
import { cn } from "@lib/utils"

type Props = {
  tags: string[]
  data: CollectionEntry<"projects">[]
}

export default function Projects({ data, tags }: Props) {
  const [filter, setFilter] = createSignal(new Set<string>())
  const [projects, setProjects] = createSignal<CollectionEntry<"projects">[]>([])

  createEffect(() => {
    setProjects(data.filter((entry) => 
      Array.from(filter()).every((value) => 
        entry.data.tags.some((tag:string) => 
          tag.toLowerCase() === String(value).toLowerCase()
        )
      )
    ))
  })

  function toggleTag(tag: string) {
    setFilter((prev) => 
      new Set(prev.has(tag) 
        ? [...prev].filter((t) => t !== tag) 
        : [...prev, tag]
      )
    )
  }

  return (
    <div class="grid grid-cols-1 gap-8 sm:grid-cols-3">
      <div class="col-span-3 sm:col-span-1">
        <div class="sticky top-24">
          <div class="mb-3 text-xs font-semibold uppercase tracking-[0.16em] text-zinc-500 dark:text-ink-300">Filter</div>
          <ul class="flex flex-wrap gap-2 sm:flex-col">
            <For each={tags}>
              {(tag) => (
                <li>
                  <button onClick={() => toggleTag(tag)} class={cn("w-full rounded-md px-3 py-2", "whitespace-nowrap overflow-hidden overflow-ellipsis", "flex items-center gap-2", "border border-black/10 bg-white/65 text-zinc-700 dark:border-white/10 dark:bg-white/[0.04] dark:text-ink-300", "hover:border-sky-400/50 hover:text-zinc-950 dark:hover:border-accent-sky/50 dark:hover:text-ink-100", "transition-colors duration-300 ease-in-out", filter().has(tag) && "border-sky-400/60 text-zinc-950 dark:border-accent-sky/60 dark:text-ink-100")}>
                    <svg class={cn("size-5 fill-black/50 dark:fill-white/50", "transition-colors duration-300 ease-in-out", filter().has(tag) && "fill-black dark:fill-white")}>
                      <use href={`/ui.svg#square`} class={cn(!filter().has(tag) ? "block" : "hidden")} />
                      <use href={`/ui.svg#square-check`} class={cn(filter().has(tag) ? "block" : "hidden")} />
                    </svg>
                    {tag}
                  </button>
                </li>
              )}
            </For>
          </ul>
        </div>
      </div>
      <div class="col-span-3 sm:col-span-2">
        <div class="flex flex-col">
          <div class="mb-3 text-xs font-semibold uppercase tracking-[0.16em] text-zinc-500 dark:text-ink-300">
            SHOWING {projects().length} OF {data.length} PROJECTS
          </div>
          <ul class="flex flex-col gap-3">
            {projects().map((project) => (
              <li>
                <ArrowCard entry={project} />
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  )
}
