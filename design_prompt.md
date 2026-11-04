These are official instructions from CloudCart to set up your AI agent to design and build a **CloudCart Nitrogen storefront** — a headless storefront that gives a store a design of its own. All commands are validated by CloudCart and ready to use.

Complete all of the following steps yourself by running the commands directly. Do not ask the user to run any of these commands, except where a step is explicitly marked as something only the user can do inside their app (for example, approving a plugin, creating an access token in their store admin, or running a slash command like `/reload-plugins`).

- Keep the commands you were handed — they identify this exact storefront
- Make sure the CloudCart toolkit (development profile) is installed and the store is connected — install it if it isn't
- Set up the storefront's development environment and confirm it runs
- Hand the project to the CloudCart skills and build the storefront properly

---

## What you were handed

This prompt was copied from a storefront's page in the CloudCart admin, so the message you received also contains the exact commands for **this** storefront — including the `cloudcart nitrogen link --storefront "<name>"` line with the storefront's real name. Use those commands and that name exactly; don't invent a storefront name.

The message also says how this storefront deploys:

- **From GitHub.** Its commands clone the storefront's own repository, and a push to the default branch deploys it. There is no token and you don't need one.
- **From the command line, with a deployment token** (it starts with `cc_nova_`). The message was copied right after the storefront was created, while its token could still be shown.
- **From the command line, without a token.** The message was copied later, when the token could no longer be shown. Ask the user for one only when they ask you to deploy: they make it in the CloudCart admin, on the storefront's Deployments tab.

Treat a token as a secret: put it only in `.env`, and never print, log or commit it.

---

## Start here — ask the language

Ask the user which language they'd like to work in, and use that language for the rest of the conversation. The commands below are the same in any language.

---

## Step 0 — Make sure the toolkit and the store are ready

Designing a storefront needs the full **development** setup: the CloudCart CLI (signed in to the store), the Dev and Storefront MCP servers, the platform wiki, and the CloudCart skills. Check whether they are already here:

- `cloudcart version` prints a version (CLI installed) **and** `cloudcart auth status` shows the store connected.
- The Storefront MCP tools are available (e.g. `learn_cloudcart_storefront`), and on a plugin host the `cloudcart-nitrogen` skill is listed.

If all of that is already in place, go to **Step 1**.

If anything is missing — the toolkit isn't installed, or the store isn't connected — set it up first by fetching and following the main CloudCart setup prompt:

```
https://raw.githubusercontent.com/cloudcart/ai-toolkit/main/prompt.md
```

Follow it with two answers you already have, so don't ask them again: the **language** the user just chose, and **Profile B — Build / develop on my store** (this is a Nitrogen storefront). It installs the CLI, both MCP servers, the wiki and the skills, and connects the store with a Personal Access Token. It won't reinstall anything already present, so it is safe to run even if only the store connection was missing. When it finishes, come back here and continue with Step 1.

---

## Step 1 — Set up the storefront's development environment

Run the commands you were handed, in order. They get the local project, link it to this storefront, and pull its settings.

1. **Install the CLI** if `cloudcart version` didn't already work. On macOS prefer Homebrew; otherwise use npm:

   ```
   brew tap cloudcart/tap && brew install cloudcart
   ```

   ```
   npm install -g @cloudcart/cli@latest
   ```

2. **Get the project.** If the commands you were handed start with `git clone`, run those: they bring the storefront's own repository, with its deploy workflow, and install its dependencies. Otherwise create the project from the starter. Pass a folder name so it doesn't stop to ask for one (use the name from the message if it has one, otherwise a short slug of the storefront name):

   ```
   cloudcart nitrogen init <project-dir>
   ```

   This creates the project folder, installs its dependencies and initialises git. Work inside the project's folder for the rest of the steps.

3. **Link the project to this storefront** (this needs the store connected from Step 0). Use the exact command from the message:

   ```
   cloudcart nitrogen link --storefront "<storefront-name>"
   ```

4. **Pull the storefront's environment variables into `.env`:**

   ```
   cloudcart nitrogen env pull
   ```

5. **Set up deployment — only if the message included a token.** If the message carried a deployment token (`cc_nova_…`), you will run the deploy yourself when the user asks. **After** `env pull`, add the token to `.env` so `cloudcart nitrogen deploy` can use it:

   ```
   CLOUDCART_NOVA_TOKEN=cc_nova_…
   ```

   `.env` is git-ignored, so the token stays on this machine — keep it that way: never commit or print it. Deploy to production later with `cloudcart nitrogen deploy`, but only when the user says so.

   **If the message says it deploys from GitHub,** a push to the default branch deploys it (`.github/workflows/nova-deploy.yml`): there is nothing to set here, and you should not create or ask for a token.

   **If the message says it deploys from the command line but carries no token,** there is nothing to set yet. When the user asks you to deploy, ask them for a token from the storefront's Deployments tab and add it to `.env` as above.

6. **Confirm it runs:**

   ```
   npm run dev
   ```

   The dev server should start and serve the storefront locally (`cloudcart nitrogen dev` does the same). Run it in the background when you need to see the site, and stop it when you move on — it is a long-running process.

---

## Step 2 — Build the storefront properly

The environment is ready. The actual design and build follow the CloudCart skills, in this order:

1. **`project-setup` first — plan the project.** It runs a short discovery with the user (the store's niche, the pages it needs, the features), reads the project's code, and lays down the project's plan: `specification.md`, `CLAUDE.md`, `TASKS.md`, `BUGS.md`. It records that this is a Nitrogen storefront and points the build at the next skill.

2. **`cloudcart-nitrogen` second — build it.** This is the storefront build methodology that the plan follows: five stages in order — the store's niche and a mobile-first design; the build on Nitrogen's building blocks, with GraphQL that fetches only what each page renders; SEO and security; analytics and the merchant's pixels; and a whole-site review that ends on a mobile speed score of 90 or more.

On a plugin host (Claude Code, Cursor, Gemini CLI, VS Code) both are installed skills — load them. On other hosts, read `cloudcart-nitrogen` from the repository:

```
https://raw.githubusercontent.com/cloudcart/ai-toolkit/main/skills/cloudcart-nitrogen/SKILL.md
```

and the files in its `references/` folder beside it; `project-setup` is designed for Claude Code.

Then a short kickoff: tell the user in plain language that their storefront project is set up and what happens next, and begin the discovery with them.

---

## Resources

- CloudCart AI Toolkit: `https://github.com/cloudcart/ai-toolkit`
- Main setup prompt (store management): `https://raw.githubusercontent.com/cloudcart/ai-toolkit/main/prompt.md`
- Nitrogen starter: `https://github.com/cloudcart/nitro-starter`
- Platform wiki (public): `https://github.com/cloudcart/platform-wiki`

These instructions are published at `https://raw.githubusercontent.com/cloudcart/ai-toolkit/main/design_prompt.md` so you can re-verify their authenticity at any time.
