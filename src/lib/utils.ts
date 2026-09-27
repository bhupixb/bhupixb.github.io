export function formatDate(date: Date) {
  return Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(date)
}

export function formatIsoDate(date: Date) {
  return date.toISOString().slice(0, 10)
}

export function formatMonthYear(input: Date | string) {
  if (typeof input === "string") return input
  return Intl.DateTimeFormat("en-US", { month: "short", year: "numeric" }).format(input)
}

export function readingTime(text: string = "") {
  const wordCount = text.split(/\s+/).filter(Boolean).length
  return `${Math.max(1, Math.round(wordCount / 200))} min read`
}
