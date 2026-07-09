import type { Post } from "./posts.ts";
import * as config from "#config";
import * as sveltemd from "@clan.lol/svelte-md";
import { opendir, readFile } from "node:fs/promises";
import pathutil from "node:path";

const DEV = process.env["MODE"] !== "production";

export async function readPosts(): Promise<Post[]> {
  const posts: Post[] = [];
  let entries;
  try {
    entries = await opendir(config.postsDir);
  } catch {
    return posts;
  }
  for await (const dirent of entries) {
    if (!dirent.isFile() || !dirent.name.endsWith(".md")) {
      continue;
    }
    const filename = pathutil.join(config.postsDir, dirent.name);
    const slug = dirent.name.slice(0, -".md".length);
    // eslint-disable-next-line no-await-in-loop
    const post = await compilePost(filename, slug);
    if (post) {
      posts.push(post);
    }
  }
  posts.sort((a, b) => b.date.localeCompare(a.date));
  return posts;
}

export async function compilePost(
  filename: string,
  slug: string,
): Promise<Post | undefined> {
  const source = await readFile(filename, { encoding: "utf8" });
  const output = await sveltemd.compile(source, {
    root: config.postsDir,
    filename,
    codeLightTheme: config.codeLightTheme,
    codeDarkTheme: config.codeDarkTheme,
    minLineNumberLines: config.codeMinLineNumberLines,
    maxTocDepth: config.maxTocDepth,
    variables: {
      siteTitle: config.siteTitle,
      author: config.author,
    },
  });
  const fm = output.frontmatter;
  if (fm["draft"] === true && !DEV) {
    return undefined;
  }
  const title = typeof fm["title"] === "string" ? fm["title"] : output.title;
  return {
    slug,
    title,
    date: normalizeDate(fm["date"]),
    description:
      typeof fm["description"] === "string" ? fm["description"] : "",
    tags: normalizeTags(fm["tags"]),
    markup: output.markup,
    toc: fm["toc"] === false ? [] : output.toc,
    svelteComponents: [...output.svelteComponents].sort(),
  };
}

function normalizeDate(value: unknown): string {
  if (value instanceof Date) {
    return value.toISOString().slice(0, 10);
  }
  if (typeof value === "string") {
    return value;
  }
  return "";
}

function normalizeTags(value: unknown): readonly string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((tag): tag is string => typeof tag === "string");
}
