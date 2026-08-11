#!/usr/bin/env bash
# Sync the CloudCart platform wiki to a stable, host-neutral location on disk.
#
# Source: https://github.com/cloudcart/platform-wiki (public, anonymous clone).
# Only the wiki/ pages are installed — the plugin ships its own navigation skill
# rather than depending on the upstream one, which can change independently.
#
# Lands at ~/.cloudcart-ai-toolkit/wiki (override with $CLOUDCART_WIKI_HOME) so
# every AI host — Claude Code, Cursor, Codex, Gemini CLI — reads one path.
#
# Modes:
#   --background   fork a detached sync and return immediately (SessionStart hook)
#   --ensure       sync only if the wiki is missing; exits nonzero if unavailable
#   --force        re-download now, ignoring the freshness window
#   (no flag)      sync if missing, or if the window elapsed and upstream moved
#
# Exit status is 0 in --background mode no matter what: a failed sync must never
# block a session from starting.

set -u

REPO="${CLOUDCART_WIKI_REPO:-https://github.com/cloudcart/platform-wiki}"
BRANCH="${CLOUDCART_WIKI_BRANCH:-master}"
CC_HOME="${CLOUDCART_WIKI_HOME:-$HOME/.cloudcart-ai-toolkit}"
TTL_HOURS="${CLOUDCART_WIKI_TTL_HOURS:-24}"

WIKI_DIR="$CC_HOME/wiki"
STAMP="$CC_HOME/.wiki-version"
LAST_CHECK="$CC_HOME/.wiki-last-check"
LOG="$CC_HOME/.wiki-sync.log"
LOCK="$CC_HOME/.wiki-sync.lock"

MODE="${1:-}"

log() { printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >>"$LOG" 2>/dev/null; }

fresh_enough() {
  [ -f "$LAST_CHECK" ] || return 1
  now=$(date +%s)
  last=$(cat "$LAST_CHECK" 2>/dev/null || echo 0)
  case "$last" in (*[!0-9]*|'') last=0 ;; esac
  [ $(( (now - last) / 3600 )) -lt "$TTL_HOURS" ]
}

# --- background mode: re-exec detached, return control instantly ---------------
if [ "$MODE" = "--background" ]; then
  mkdir -p "$CC_HOME" 2>/dev/null
  # Skip the fork entirely when nothing is due — keeps session start free.
  if [ -f "$WIKI_DIR/index.md" ] && fresh_enough; then
    exit 0
  fi
  nohup "$0" --detached >/dev/null 2>&1 &
  exit 0
fi

mkdir -p "$CC_HOME" 2>/dev/null || { echo "cannot create $CC_HOME" >&2; exit 1; }

have_wiki() { [ -f "$WIKI_DIR/index.md" ]; }
installed()  { cat "$STAMP" 2>/dev/null || echo ""; }

# --- single-flight lock (atomic mkdir; stale locks expire after 30 min) --------
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -d "$LOCK" ]; then
    lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
    if [ "$lock_age" -gt 1800 ]; then
      rm -rf "$LOCK" 2>/dev/null
      mkdir "$LOCK" 2>/dev/null || exit 0
    else
      log "another sync is running"
      # --ensure promises the wiki is usable on exit 0. When the session-start
      # sync still holds the lock, wait for it rather than reporting a success
      # we cannot back — the caller would read a missing index.md.
      if [ "$MODE" = "--ensure" ]; then
        waited=0
        while [ "$waited" -lt 180 ]; do
          have_wiki && exit 0
          [ -d "$LOCK" ] || break
          sleep 2
          waited=$((waited + 2))
        done
        have_wiki && exit 0
        echo "CloudCart wiki is still downloading. Try again in a moment." >&2
        exit 1
      fi
      exit 0
    fi
  fi
fi
trap 'rm -rf "$LOCK" "${TMP:-}" 2>/dev/null' EXIT INT TERM

# --- decide whether there is anything to do -----------------------------------
case "$MODE" in
  --ensure) have_wiki && exit 0 ;;
  --force)  ;;
  *)        have_wiki && fresh_enough && exit 0 ;;
esac

command -v git >/dev/null 2>&1 || {
  log "git is not installed"
  have_wiki && exit 0
  echo "CloudCart wiki unavailable: git is not installed on this machine." >&2
  exit 1
}

# Cheap remote check before paying for a clone: one request, no repo download.
if [ "$MODE" != "--force" ] && have_wiki; then
  remote_sha="$(GIT_TERMINAL_PROMPT=0 git ls-remote "$REPO" "refs/heads/$BRANCH" 2>/dev/null | cut -f1)"
  if [ -n "$remote_sha" ]; then
    date +%s >"$LAST_CHECK"
    if [ "git:$remote_sha" = "$(installed)" ]; then
      log "already at ${remote_sha%${remote_sha#???????}}… — nothing to do"
      exit 0
    fi
  fi
fi

TMP="$(mktemp -d "$CC_HOME/.wiki-tmp.XXXXXX")" || exit 1

log "cloning $REPO#$BRANCH"
# Never prompt: an interactive credential prompt inside a hook would hang.
if ! GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=echo \
     git clone --depth 1 --single-branch --branch "$BRANCH" \
     "$REPO" "$TMP/repo" >>"$LOG" 2>&1; then
  log "clone failed"
  date +%s >"$LAST_CHECK"   # back off so we do not retry on every session
  have_wiki && exit 0
  echo "CloudCart wiki unavailable: could not clone $REPO." >&2
  exit 1
fi

if [ ! -f "$TMP/repo/wiki/index.md" ]; then
  log "clone succeeded but wiki/index.md is missing — refusing to install"
  have_wiki && exit 0
  echo "CloudCart wiki unavailable: $REPO has no wiki/index.md." >&2
  exit 1
fi

NEW_VERSION="git:$(git -C "$TMP/repo" rev-parse HEAD 2>/dev/null)"

# --- atomic swap --------------------------------------------------------------
swap() {  # swap <source> <destination>
  src="$1"; dst="$2"
  [ -e "$src" ] || return 0
  rm -rf "$dst.old" 2>/dev/null
  [ -e "$dst" ] && mv "$dst" "$dst.old" 2>/dev/null
  if mv "$src" "$dst" 2>/dev/null; then
    rm -rf "$dst.old" 2>/dev/null
    return 0
  fi
  # restore the previous copy rather than leaving the caller with nothing
  [ -d "$dst.old" ] && mv "$dst.old" "$dst" 2>/dev/null
  return 1
}

if swap "$TMP/repo/wiki" "$WIKI_DIR"; then
  printf '%s' "$NEW_VERSION" >"$STAMP"
  date +%s >"$LAST_CHECK"
  log "installed $NEW_VERSION ($(find "$WIKI_DIR" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') pages)"
else
  log "swap failed; kept previous wiki"
  exit 1
fi
