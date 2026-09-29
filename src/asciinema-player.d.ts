declare module "asciinema-player" {
  type PlayerOptions = {
    cols?: number
    rows?: number
    autoplay?: boolean
    loop?: boolean | number
    speed?: number
    theme?: string
    poster?: string
  }

  export function create(
    source: string,
    container: HTMLElement,
    options?: PlayerOptions,
  ): unknown
}
