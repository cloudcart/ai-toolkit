---
name: cloudcart-cli-install
description: "Install the CloudCart CLI (@cloudcart/cli, binary `cloudcart`) on the user's machine. Use when the user wants to: install cloudcart cli, set up cloudcart cli, get cloudcart cli running, fix cloudcart command not found, install cloudcart developer tools, install the cloudcart command-line tool, npm install cloudcart, brew install cloudcart, instalirai cloudcart cli, instalirai cloudcart, cloudcart cli setup. This skill ONLY installs the CLI; for catalog work (connecting the store, products, prices, inventory), use cloudcart-product-management after this."
compatibility: Claude Code, Claude Desktop, Cursor, OpenAI Codex, Gemini CLI, VS Code Copilot
context: fork
maintainer: CloudCart
metadata:
  author: CloudCart
  version: "0.1.0"
---

Install the CloudCart CLI (`@cloudcart/cli`, binary `cloudcart`) on the user's machine.

**Core principle:** State what you're about to install in one short sentence, then run the install command. Don't pause for confirmation — the user has already opted in by invoking this skill — but never run installs invisibly. If you can already run `cloudcart`, skip straight to the confirmation block.

---

## Step 1 — Detect the OS

Look for `darwin` (macOS), `linux`, or `win`/`windows` in system context. The OS determines the preferred installer in Step 3.

---

## Step 2 — Check whether the CLI is already installed

Run:

```
cloudcart version
```

- Exit 0 → CLI is present. Read the printed version, then jump to **Step 5 — Confirm**.
- Command not found / non-zero exit → continue to Step 3.

---

## Step 3 — Install the CLI

State in one sentence what you're installing and why (e.g., "Installing the CloudCart CLI so you can manage your store from here."), then run the OS-appropriate command.

### macOS — prefer Homebrew

```
brew tap cloudcart/tap && brew install cloudcart
```

If `brew` is not available, fall back to npm.

### Linux / Windows / fallback — npm

```
npm install -g @cloudcart/cli@latest
```

If the user prefers a different package manager, the equivalents are:

```
pnpm add -g @cloudcart/cli@latest
yarn global add @cloudcart/cli@latest
bun add -g @cloudcart/cli@latest
```

Use them only if the user asks or if `npm` itself isn't available.

### Neither npm nor brew available

Tell the user:

"You'll need Node.js 20 or newer first. Download the LTS from https://nodejs.org, then come back and we'll continue."

Stop and wait for them to confirm Node is installed before retrying.

---

## Step 4 — Verify

Run `cloudcart version` again. Confirm the binary works and that the user is on Node 20+ (the CLI requires it). If the install command exited zero but `cloudcart version` still fails, surface the install command's stderr output exactly as printed and stop.

---

## Step 5 — Confirm

In one sentence, confirm what was installed and the version (e.g., "CloudCart CLI 0.3.3 is ready."). Then offer the next step:

"Next, you can:

1. Run `cloudcart auth login` to connect a store yourself.
2. Tell me to set up or connect your store, and I'll walk you through it."

If the user wants the guided path, hand off to the `cloudcart-product-management` skill — it connects the store and takes it from there.

---

## Behavioral rules

- Never construct or modify install commands — only the ones in this file.
- Never silently retry a failed install. Surface the exact error and stop.
- Don't surface developer concepts (oclif, plugins, transitive deps) when speaking to a non-technical user.
- If `cloudcart version` already works, do not re-install. Confirm the existing version and continue.
- Upgrades use the same command as fresh installs (`npm install -g @cloudcart/cli@latest` or `brew upgrade cloudcart`).
