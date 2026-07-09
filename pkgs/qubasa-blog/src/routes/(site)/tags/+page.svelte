<script lang="ts">
  import type { PageProps } from "./$types.ts";
  import { resolve } from "$app/paths";

  const { data }: PageProps = $props();
</script>

<svelte:head>
  <title>Tags</title>
</svelte:head>

<h1>Tags</h1>

<ul class="tags">
  {#each data.tags as { tag, count } (tag)}
    <li>
      <a href={resolve("/tags/[tag]", { tag })}>#{tag}</a>
      <span class="count">{count}</span>
    </li>
  {:else}
    <li>No tags yet.</li>
  {/each}
</ul>

<style>
  .tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    padding: 0;
    list-style: none;
  }

  .tags > li {
    display: flex;
    gap: 0.4rem;
    align-items: center;
    padding: 0.4rem 0.75rem;
    background: var(--content-bg-color);
    border: 1px solid var(--toc-border-color);
    border-radius: 999px;
  }

  .tags a {
    text-decoration: none;
  }

  .count {
    color: var(--toc-title-fg-color);
    font-size: 13px;
  }
</style>
