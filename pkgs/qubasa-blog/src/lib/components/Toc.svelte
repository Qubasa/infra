<script lang="ts">
  import type { TocItem, TocItems } from "@clan.lol/svelte-md";

  const { items }: { items: TocItems } = $props();

  let activeId: string | undefined = $state();

  $effect(() => {
    const headings = [
      ...document.querySelectorAll<HTMLElement>(
        "article :is(h1, h2, h3, h4, h5, h6)[id]",
      ),
    ];
    if (headings.length === 0) {
      return;
    }
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            activeId = entry.target.id;
          }
        }
      },
      { rootMargin: "0px 0px -75% 0px", threshold: 1 },
    );
    for (const heading of headings) {
      observer.observe(heading);
    }
    return (): void => observer.disconnect();
  });
</script>

{#if items.length !== 0}
  <nav aria-label="Table of contents" data-pagefind-ignore>
    <p class="title">On this page</p>
    {@render tree(items)}
  </nav>
{/if}

{#snippet tree(items: TocItems)}
  <ol>
    {#each items as item (item.id)}
      {@render branch(item)}
    {/each}
  </ol>
{/snippet}

{#snippet branch(item: TocItem)}
  <li>
    <a class:active={item.id === activeId} href={`#${item.id}`}>{item.label}</a>
    {#if item.children.length !== 0}
      {@render tree(item.children)}
    {/if}
  </li>
{/snippet}

<style>
  nav {
    font-size: 14px;
  }

  .title {
    margin: 0 0 0.5em;
    color: var(--toc-title-fg-color);
    font-weight: 600;
  }

  ol {
    padding: 0;
    margin: 0;
    list-style: none;
  }

  ol ol {
    padding-inline-start: 0.9em;
  }

  a {
    display: block;
    padding: 4px 10px;
    color: var(--toc-fg-color);
    text-decoration: none;
    border-inline-start: 2px solid var(--toc-indent-guide-color);
  }

  a:hover {
    color: var(--toc-highlighted-fg-color);
    border-inline-start-color: var(--toc-highlighted-indent-guide-color);
  }

  a.active {
    color: var(--toc-highlighted-fg-color);
    background: var(--toc-highlighted-bg-color);
    border-inline-start-color: var(--toc-highlighted-indent-guide-color);
  }
</style>
