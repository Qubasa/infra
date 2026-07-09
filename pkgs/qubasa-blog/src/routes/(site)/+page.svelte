<script lang="ts">
  import type { PageProps } from "./$types.ts";
  import { formatDate } from "$lib/posts.ts";
  import { resolve } from "$app/paths";
  import { siteDescription, siteTitle } from "$config";

  const { data }: PageProps = $props();
</script>

<svelte:head>
  <title>{siteTitle}</title>
  <meta name="description" content={siteDescription} />
</svelte:head>

<section class="intro">
  <h1>{siteTitle}</h1>
  <p>{siteDescription}</p>
</section>

<ul class="posts">
  {#each data.posts as post (post.slug)}
    <li>
      <a class="post-link" href={resolve("/blog/[slug]", { slug: post.slug })}>
        <h2>{post.title}</h2>
      </a>
      <p class="meta">
        {#if post.date}<time datetime={post.date}>{formatDate(post.date)}</time
          >{/if}
        {#each post.tags as tag (tag)}
          <a class="tag" href={resolve("/tags/[tag]", { tag })}>#{tag}</a>
        {/each}
      </p>
      {#if post.description}<p class="description">{post.description}</p>{/if}
    </li>
  {:else}
    <li class="empty">No posts yet.</li>
  {/each}
</ul>

<style>
  .intro {
    margin-block-end: 2.5rem;
  }

  .intro h1 {
    margin-block: 0 0.3em;
  }

  .posts {
    padding: 0;
    margin: 0;
    list-style: none;
  }

  .posts > li {
    padding-block: 1.5rem;
    border-block-start: 1px solid var(--heading-border-color);
  }

  .post-link {
    text-decoration: none;
    color: inherit;
  }

  .post-link h2 {
    margin-block: 0;
    border: 0;
    font-size: 1.5rem;
  }

  .post-link:hover h2 {
    color: var(--link-color);
  }

  .meta {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    align-items: baseline;
    margin-block: 0.4rem;
    color: var(--toc-title-fg-color);
    font-size: 14px;
  }

  .tag {
    text-decoration: none;
  }

  .description {
    margin-block: 0.4rem 0;
  }
</style>
