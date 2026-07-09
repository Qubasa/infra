<script lang="ts">
  import { siteTitle } from "$config";
  import { resolve } from "$app/paths";
  import Search from "$lib/components/Search.svelte";
</script>

<header class="site-header" data-pagefind-ignore>
  <a class="brand" href={resolve("/")}>{siteTitle}</a>
  <nav>
    <a href={resolve("/")}>Home</a>
    <a href={resolve("/tags")}>Tags</a>
  </nav>
  <Search />
</header>

<style>
  .site-header {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem 1.5rem;
    align-items: center;
    padding-block: 1rem;
    margin-block-end: 2rem;
    border-block-end: 1px solid var(--heading-border-color);
  }

  .brand {
    font-weight: 700;
    font-size: 1.25rem;
    text-decoration: none;
    color: inherit;
  }

  nav {
    display: flex;
    gap: 1rem;
    margin-inline-end: auto;
  }

  nav a {
    text-decoration: none;
  }
</style>
