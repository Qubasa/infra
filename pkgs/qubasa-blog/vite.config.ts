import { defineConfig } from "vite";
import posts2routes from "./support/vite-plugin-posts2routes.ts";
import pagefind from "@clan.lol/vite-plugin-pagefind";
import * as siteConfig from "./blog.config.ts";
import { sveltekit } from "@sveltejs/kit/vite";
import svg from "@poppanator/sveltekit-svg";
import value from "vite-plugin-value";

export default defineConfig(() => {
  return {
    server: {
      host: "127.0.0.1",
      watch: {
        // .direnv/flake-inputs contains the whole nixpkgs tree, so watching it
        // exhausts inotify handles and stalls the dev server.
        ignored: [
          "**/.direnv",
          "**/.direnv/**",
          "**/build",
          "**/build/**",
          "**/.svelte-kit",
          "**/.svelte-kit/**",
        ],
      },
      fs: {
        allow: ["./packages"],
      },
    },
    preview: {
      host: "127.0.0.1",
    },
    plugins: [
      posts2routes(),
      sveltekit(),
      svg({
        svgoOptions: {
          plugins: ["removeXMLNS"],
        },
      }),
      value({
        specifier: "$config",
        value: siteConfig,
      }),
      pagefind({
        pluginInstance: "blog",
        siteDir: "build",
        staticDir: "static",
        assetsDir: "build",
        bundleDir: "_pagefind",
        base: "/",
      }),
    ],
  };
});
