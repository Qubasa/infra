<script lang="ts">
  import { author, siteTitle } from "$config";
  import Header from "$lib/components/Header.svelte";

  const { children } = $props();
</script>

<div class="page">
  <Header />
  <main>
    {@render children()}
  </main>
  <footer data-pagefind-ignore>
    <p>© {new Date().getFullYear()} {author} · {siteTitle}</p>
  </footer>
</div>

<style>
  .page {
    inline-size: 100%;
    max-inline-size: 60rem;
    padding-inline: max(1.25rem, env(safe-area-inset-left));
    margin-inline: auto;
  }

  main {
    min-block-size: 60vh;
  }

  footer {
    padding-block: 2rem;
    margin-block-start: 3rem;
    color: var(--toc-title-fg-color);
    border-block-start: 1px solid var(--heading-border-color);
    font-size: 14px;
  }
</style>
