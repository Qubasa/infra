import type { PageLoad } from "./$types.ts";
import { posts } from "$lib/generated/posts.ts";

export const load: PageLoad = (): { posts: typeof posts } => ({ posts });
