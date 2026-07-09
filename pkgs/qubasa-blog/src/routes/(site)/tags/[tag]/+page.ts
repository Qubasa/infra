import type { EntryGenerator, PageLoad } from "./$types.ts";
import type { PostMeta } from "$lib/posts.ts";
import { error } from "@sveltejs/kit";
import { posts } from "$lib/generated/posts.ts";

export const entries: EntryGenerator = () => {
  const tags = new Set<string>();
  for (const post of posts) {
    for (const tag of post.tags) {
      tags.add(tag);
    }
  }
  return [...tags].map((tag) => ({ tag }));
};

export const load: PageLoad = ({
  params,
}): { tag: string; posts: readonly PostMeta[] } => {
  const tagged = posts.filter((post) => post.tags.includes(params.tag));
  if (tagged.length === 0) {
    error(404, `No posts tagged "${params.tag}"`);
  }
  return { tag: params.tag, posts: tagged };
};
