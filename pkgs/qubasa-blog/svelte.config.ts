import type { Config } from "@sveltejs/kit";
import adapter from "@sveltejs/adapter-static";
import { fileURLToPath } from "node:url";

const svelteConfig: Config = {
  kit: {
    adapter: adapter({
      pages: "build",
      assets: "build",
      strict: true,
    }),
    alias: {
      "~": fileURLToPath(new URL("src", import.meta.url)),
    },
    typescript: {
      config(config) {
        config["include"] = [
          ...(config["include"] as string[]),
          "../*.ts",
          "../packages/**/*.ts",
          "../support/**/*.ts",
        ];
        const compOpts = config["compilerOptions"] as Record<string, unknown>;
        config["compilerOptions"] = {
          ...compOpts,
          paths: {
            ...(compOpts["paths"] as Record<string, unknown>),
            $config: ["../blog.config.ts"],
          },
        };
      },
    },
  },
};

export default svelteConfig;
