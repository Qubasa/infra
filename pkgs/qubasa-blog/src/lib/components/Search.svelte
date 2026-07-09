<script lang="ts">
  import type {
    Pagefind,
    PagefindSearchFragment,
  } from "@clan.lol/vite-plugin-pagefind";
  import { asset } from "$app/paths";
  import { browser } from "$app/environment";
  import { searchResultLimit } from "$config";

  let query = $state("");
  let results: readonly PagefindSearchFragment[] = $state.raw([]);
  let pagefind: Pagefind | undefined;

  if (browser) {
    (async (): Promise<void> => {
      pagefind = (await import(
        /* @vite-ignore */ asset("/_pagefind/pagefind.js")
      )) as Pagefind;
      await pagefind.options({ baseUrl: "/" });
      await pagefind.init();
    })();
  }

  $effect(() => {
    const q = query;
    (async (): Promise<void> => {
      if (!q || !pagefind) {
        results = [];
        return;
      }
      const search = await pagefind.debouncedSearch(q);
      if (!search) {
        return;
      }
      results = await Promise.all(
        search.results.slice(0, searchResultLimit).map((r) => r.data()),
      );
    })();
  });
</script>

<div class="search">
  <input
    type="search"
    placeholder="Search posts…"
    bind:value={query}
    aria-label="Search posts"
  />
  {#if query && results.length !== 0}
    <ol class="results">
      {#each results as result (result.url)}
        <li>
          <a href={result.url}>
            <span class="result-title">{result.meta["title"] ?? result.url}</span
            >
            <!-- eslint-disable-next-line svelte/no-at-html-tags -->
            <span class="excerpt">{@html result.excerpt}</span>
          </a>
        </li>
      {/each}
    </ol>
  {/if}
</div>

<style>
  .search {
    position: relative;
  }

  input {
    inline-size: 100%;
    max-inline-size: 16rem;
    padding: 6px 12px;
    color: var(--fg-color);
    background: var(--content-bg-color);
    border: 1px solid var(--toc-border-color);
    border-radius: 6px;
    font: inherit;
    font-size: 14px;
  }

  .results {
    position: absolute;
    inset-inline-end: 0;
    inset-block-start: calc(100% + 6px);
    z-index: 200;
    inline-size: min(24rem, 90vw);
    max-block-size: 70vh;
    padding: 6px;
    margin: 0;
    overflow-y: auto;
    list-style: none;
    background: var(--toc-bg-color);
    border: 1px solid var(--toc-border-color);
    border-radius: 8px;
    box-shadow: 0 6px 20px var(--toc-shadow-color);
  }

  .results a {
    display: block;
    padding: 8px 10px;
    color: inherit;
    text-decoration: none;
    border-radius: 6px;
  }

  .results a:hover {
    background: var(--toc-highlighted-bg-color);
  }

  .result-title {
    display: block;
    font-weight: 600;
  }

  .excerpt {
    display: block;
    color: var(--toc-title-fg-color);
    font-size: 13px;
  }
</style>
