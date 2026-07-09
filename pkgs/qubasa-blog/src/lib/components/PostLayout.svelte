<script lang="ts">
  import type { TocItems } from "@clan.lol/svelte-md";
  import type { Snippet } from "svelte";
  import { formatDate } from "$lib/posts.ts";
  import { mount } from "svelte";
  import { resolve } from "$app/paths";
  import CopyButton from "$lib/components/CopyButton.svelte";
  import Toc from "$lib/components/Toc.svelte";

  const {
    title,
    date,
    tags,
    toc,
    children,
  }: {
    title: string;
    date: string;
    tags: readonly string[];
    toc: TocItems;
    children: Snippet;
  } = $props();

  let article: HTMLElement | undefined = $state.raw();

  $effect(() => {
    if (!article) {
      return;
    }
    for (const pre of article.querySelectorAll<HTMLElement>("pre.shiki")) {
      if (pre.dataset["copyMounted"] !== undefined) {
        continue;
      }
      pre.dataset["copyMounted"] = "";
      mount(CopyButton, { target: pre });
    }
  });
</script>

<svelte:head>
  <title>{title}</title>
</svelte:head>

<div class="wrapper">
  <article bind:this={article} data-pagefind-body>
    <header class="post-header">
      <h1>{title}</h1>
      <p class="meta">
        {#if date}<time datetime={date}>{formatDate(date)}</time>{/if}
        {#if tags.length !== 0}
          <span class="tags">
            {#each tags as tag (tag)}
              <a href={resolve("/tags/[tag]", { tag })}>#{tag}</a>
            {/each}
          </span>
        {/if}
      </p>
    </header>
    {@render children()}
  </article>
  {#if toc.length !== 0}
    <aside class="toc">
      <Toc items={toc} />
    </aside>
  {/if}
</div>

<style>
  .wrapper {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: 2.5rem;
    align-items: start;
  }

  article {
    min-inline-size: 0;
  }

  .post-header h1 {
    margin-block: 0 0.3em;
  }

  .meta {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    align-items: baseline;
    margin-block: 0 2.5rem;
    color: var(--toc-title-fg-color);
    font-size: 14px;
  }

  .tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
  }

  .tags a {
    text-decoration: none;
  }

  .toc {
    display: none;
  }

  @media (--docs-desktop) {
    .wrapper {
      grid-template-columns: minmax(0, 1fr) 240px;
    }

    .toc {
      display: block;
      position: sticky;
      inset-block-start: 1.5rem;
    }
  }
</style>
