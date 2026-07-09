import type { PageLoad } from "./$types.ts";
import { posts } from "$lib/generated/posts.ts";

export interface TagCount {
  readonly tag: string;
  readonly count: number;
}

export const load: PageLoad = (): { tags: TagCount[] } => {
  const counts = new Map<string, number>();
  for (const post of posts) {
    for (const tag of post.tags) {
      counts.set(tag, (counts.get(tag) ?? 0) + 1);
    }
  }
  const tags = [...counts.entries()]
    .map(([tag, count]) => ({ tag, count }))
    .sort((a, b) => a.tag.localeCompare(b.tag));
  return { tags };
};
