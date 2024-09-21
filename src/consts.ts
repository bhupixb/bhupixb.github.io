import type { Site, Page, Links, Socials } from "@types"

// Global
export const SITE: Site = {
  TITLE: "Bhupendra Yadav",
  DESCRIPTION: "Welcome to my personal blog for developers.",
  AUTHOR: "Bhupendra yadav",
}

// Work Page
export const WORK: Page = {
  TITLE: "Work",
  DESCRIPTION: "Places I have worked as a Software Engineer.",
}

// Blog Page
export const BLOG: Page = {
  TITLE: "Blog",
  DESCRIPTION: "Writing on topics I am passionate about in Software Engineering.",
}

// Projects Page 
export const PROJECTS: Page = {
  TITLE: "Projects",
  DESCRIPTION: "Recent projects I have worked on.",
}

// Search Page
export const SEARCH: Page = {
  TITLE: "Search",
  DESCRIPTION: "Search all posts and projects by keyword.",
}

// Links
export const LINKS: Links = [
  { 
    TEXT: "Home", 
    HREF: "/", 
  },
  { 
    TEXT: "Work", 
    HREF: "/work", 
  },
  { 
    TEXT: "Blog", 
    HREF: "/blog", 
  },
  { 
    TEXT: "Projects", 
    HREF: "/projects", 
  },
]

// Socials
export const SOCIALS: Socials = [
  { 
    NAME: "Email",
    ICON: "email", 
    TEXT: "engineerbhupixb@gmail.com",
    HREF: "mailto:engineerbhupixb@gmail.com",
  },
  { 
    NAME: "Github",
    ICON: "github",
    TEXT: "bhupixb",
    HREF: "https://github.com/bhupixb"
  },
  { 
    NAME: "LinkedIn",
    ICON: "linkedin",
    TEXT: "bhupixb",
    HREF: "https://www.linkedin.com/in/bhupixb/",
  },
  { 
    NAME: "Twitter",
    ICON: "twitter-x",
    TEXT: "bhupixb",
    HREF: "https://twitter.com/bhupixb",
  },
  { 
    NAME: "Medium",
    ICON: "medium",
    TEXT: "not-afraid",
    HREF: "https://not-afraid.medium.com/",
  },
]

