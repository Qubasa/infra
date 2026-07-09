import type { TocItems } from "@clan.lol/svelte-md";

export interface PostMeta {
  readonly slug: string;
  readonly title: string;
  readonly date: string;
  readonly description: string;
  readonly tags: readonly string[];
}

export interface Post extends PostMeta {
  readonly markup: string;
  readonly toc: TocItems;
  readonly svelteComponents: readonly string[];
}

export function formatDate(date: string): string {
  if (!date) {
    return "";
  }
  const parsed = new Date(date);
  if (Number.isNaN(parsed.getTime())) {
    return date;
  }
  return parsed.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  });
}
