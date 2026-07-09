<script lang="ts">
  import type { PageProps } from "./$types.ts";
  import { formatDate } from "$lib/posts.ts";
  import { resolve } from "$app/paths";

  const { data }: PageProps = $props();
</script>

<svelte:head>
  <title>#{data.tag}</title>
</svelte:head>

<h1>Posts tagged #{data.tag}</h1>

<ul class="posts">
  {#each data.posts as post (post.slug)}
    <li>
      <a class="post-link" href={resolve("/blog/[slug]", { slug: post.slug })}>
        <h2>{post.title}</h2>
      </a>
      {#if post.date}
        <p class="meta">
          <time datetime={post.date}>{formatDate(post.date)}</time>
        </p>
      {/if}
      {#if post.description}<p class="description">{post.description}</p>{/if}
    </li>
  {/each}
</ul>

<style>
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
    margin-block: 0.4rem;
    color: var(--toc-title-fg-color);
    font-size: 14px;
  }

  .description {
    margin-block: 0.4rem 0;
  }
</style>
