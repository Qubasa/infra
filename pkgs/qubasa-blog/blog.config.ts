import pathutil from "node:path";

export const siteTitle = "qubasa.blog";
export const siteDescription = "Notes on NixOS, clan, and self-hosting.";
export const siteUrl = "https://qubasa.blog";
export const author = "Qubasa";
export const language = "en";

export const postsDir = pathutil.resolve(import.meta.dirname, "posts");

export const searchResultLimit = 20;
export const codeMinLineNumberLines = 4;
export const codeLightTheme = "catppuccin-latte";
export const codeDarkTheme = "catppuccin-macchiato";
export const maxTocDepth = 3;
export const copyButtonMessageDelay = 3000;
