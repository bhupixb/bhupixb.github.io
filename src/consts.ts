export type Page = {
  TITLE: string
  DESCRIPTION: string
}

export const SITE = {
  TITLE: "Bhupendra Yadav",
  DESCRIPTION: "Bhupendra Yadav's blog. Notes on Postgres, backend, infrastructure and whatever I'm poking at.",
  AUTHOR: "Bhupendra Yadav",
}

export const WORK: Page = {
  TITLE: "Work",
  DESCRIPTION: "Places I have worked as a Software Engineer.",
}

export const BLOG: Page = {
  TITLE: "Blog",
  DESCRIPTION: "Writing on topics I am passionate about in Software Engineering.",
}

export const PROJECTS: Page = {
  TITLE: "Projects",
  DESCRIPTION: "Side projects I have worked on.",
}

export const LINKS = [
  { TEXT: "Home", HREF: "/" },
  { TEXT: "Blog", HREF: "/blog" },
  { TEXT: "Work", HREF: "/work" },
  { TEXT: "Projects", HREF: "/projects" },
]

export const SOCIALS = [
  { NAME: "Email", HREF: "mailto:engineerbhupixb@gmail.com" },
  { NAME: "GitHub", HREF: "https://github.com/bhupixb" },
  { NAME: "LinkedIn", HREF: "https://www.linkedin.com/in/bhupixb/" },
  { NAME: "Twitter", HREF: "https://twitter.com/bhupixb" },
  { NAME: "Medium", HREF: "https://not-afraid.medium.com/" },
]
