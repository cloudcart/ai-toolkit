#!/usr/bin/env bash
# Session-start hint for the project-setup skill.
#
# Runs as a Claude Code SessionStart hook (startup, clear). Looks only at the
# shape of the current folder and, when the project is not set up, prints a few
# lines of context for the agent so it can offer `cloudcart-plugin:project-setup`
# in one sentence. It never starts the interview, never writes to the project,
# never reads file contents beyond a line count, never touches the network.
#
# What it prints, by folder shape:
#   empty folder (or only .git)                  -> hint, every start
#   code, no CLAUDE.md                           -> hint once per folder
#   CLAUDE.md without the kit's fingerprint      -> hint once per folder, with the facts (audit mode)
#   full kit (TASKS.md + project skills/notes)   -> nothing
#   the home directory                           -> nothing
#
# Turn off with CLOUDCART_SETUP_HINTS=0. Stamps for "once per folder" live in
# ${CLAUDE_PLUGIN_DATA}/setup-hints/ (falls back to ~/.cloudcart-ai-toolkit),
# which survives plugin updates. Exit status is always 0: a hint must never
# block a session from starting.

set -u

[ "${CLOUDCART_SETUP_HINTS:-1}" = "0" ] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
[ "$ROOT" = "$HOME" ] && exit 0
[ -d "$ROOT" ] || exit 0

DATA="${CLAUDE_PLUGIN_DATA:-${CLOUDCART_WIKI_HOME:-$HOME/.cloudcart-ai-toolkit}}"
STAMPS="$DATA/setup-hints"

has() { [ -e "$ROOT/$1" ]; }
hint_once() {
  # $1 = kind; prints the rest of stdin once per (folder, kind)
  mkdir -p "$STAMPS" 2>/dev/null || { cat; return; }
  key="$(printf '%s' "$ROOT" | cksum | cut -d' ' -f1)-$1"
  [ -e "$STAMPS/$key" ] && { cat >/dev/null; return; }
  : > "$STAMPS/$key"
  cat
}

SKILL='cloudcart-plugin:project-setup'
HOWTO="Offer it in one sentence, in the user's language, only if their first message does not already say what they want. Do not start it on your own."

# --- full kit: nothing to say -------------------------------------------------
if has TASKS.md && { has .claude/skills/project-manager/SKILL.md || has notes/README.md; }; then
  exit 0
fi

# --- empty folder: a new project ----------------------------------------------
entries="$(ls -A "$ROOT" 2>/dev/null | grep -v -x -E '\.git|\.DS_Store|\.claude' | head -1)"
if [ -z "$entries" ]; then
  cat <<TXT
The folder is empty. The $SKILL skill turns a new project into a specification, CLAUDE.md, TASKS.md and BUGS.md through a guided interview, then installs the project skills and the notes layer. $HOWTO
TXT
  exit 0
fi

# --- code without CLAUDE.md ---------------------------------------------------
if ! has CLAUDE.md; then
  hint_once no-claude-md <<TXT
This folder has files but no CLAUDE.md. The $SKILL skill can read the code and the stack first, then interview only for what the code does not answer, and leave a specification, CLAUDE.md, TASKS.md and BUGS.md. $HOWTO
TXT
  exit 0
fi

# --- CLAUDE.md exists, but the kit's fingerprint is missing: audit mode -------
lines="$(wc -l < "$ROOT/CLAUDE.md" 2>/dev/null | tr -d ' ')"
missing=""
has TASKS.md || missing="$missing TASKS.md,"
has BUGS.md || missing="$missing BUGS.md,"
{ has specification.md || has spec.md || has SPEC.md; } || missing="$missing specification,"
has .claude/skills/project-manager/SKILL.md || missing="$missing project skills,"
has notes/README.md || missing="$missing notes/,"
has .claude/hooks/harvest.sh || missing="$missing harvest hooks,"
missing="${missing%,}"
hint_once audit <<TXT
CLAUDE.md exists (${lines:-?} lines). Missing:${missing:- nothing obvious}. The $SKILL skill has an audit mode: it reads what exists, compares it with the kit (decisions with their reasons, platform limits, tasks anchored to a spec, open questions, the work cycle, project skills, notes and hooks) and proposes what to add as a list you approve item by item, without overwriting anything. $HOWTO Do not audit on your own.
TXT
exit 0
