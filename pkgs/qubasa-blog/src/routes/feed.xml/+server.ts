import type { RequestHandler } from "./$types.ts";
import {
  language,
  siteDescription,
  siteTitle,
  siteUrl,
} from "$config";
import { posts } from "$lib/generated/posts.ts";

export const prerender = true;

export const GET: RequestHandler = () => {
  const items = posts
    .map((post) => {
      const url = `${siteUrl}/blog/${post.slug}/`;
      const parts = [
        `      <title>${escapeXml(post.title)}</title>`,
        `      <link>${url}</link>`,
        `      <guid isPermaLink="true">${url}</guid>`,
      ];
      if (post.date) {
        parts.push(
          `      <pubDate>${new Date(post.date).toUTCString()}</pubDate>`,
        );
      }
      if (post.description) {
        parts.push(
          `      <description>${escapeXml(post.description)}</description>`,
        );
      }
      for (const tag of post.tags) {
        parts.push(`      <category>${escapeXml(tag)}</category>`);
      }
      return `    <item>\n${parts.join("\n")}\n    </item>`;
    })
    .join("\n");

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${escapeXml(siteTitle)}</title>
    <link>${siteUrl}</link>
    <atom:link href="${siteUrl}/feed.xml" rel="self" type="application/rss+xml" />
    <description>${escapeXml(siteDescription)}</description>
    <language>${language}</language>
${items}
  </channel>
</rss>
`;

  return new Response(xml, {
    headers: { "content-type": "application/rss+xml; charset=utf-8" },
  });
};

function escapeXml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}
