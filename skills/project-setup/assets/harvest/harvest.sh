#!/bin/bash
# harvest.sh — harvests notes from the session transcript, in slices, before compaction.
#
# Called by the hooks in .claude/settings.json:
#   harvest.sh stop          — after every turn: if the transcript grew by HARVEST_SLICE_BYTES, harvest the new slice
#   harvest.sh precompact    — before compaction: harvest the remainder
#   harvest.sh sessionstart  — after compaction: tell the agent what is waiting in notes/_inbox/
#   harvest.sh job …         — internal: the harvest itself, run in the background
#
# The hook reads JSON from stdin (session_id, transcript_path) and exits at once; the harvest runs as a separate process.
# The transcript on disk is append-only and compaction deletes nothing from it, so there is no race with compaction.
# The result goes only to notes/_inbox/. Only the agent writes to notes/ (principle 17).
#
# Settings through the environment: HARVEST_SLICE_BYTES (1500000), HARVEST_MIN_BYTES (20000), HARVEST_MODEL (sonnet), CLAUDE_BIN.
# Requires bash and python3. Works on macOS (bash 3.2, no flock/setsid) and Linux.

set -u
MODE="${1:-stop}"

# Recursion guard: the child `claude -p` never harvests, even if its hooks are enabled.
[ -n "${HARVEST_CHILD:-}" ] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
HOOKS="$ROOT/.claude/hooks"
STATE_DIR="$ROOT/.claude/harvest-state"
INBOX="$ROOT/notes/_inbox"
LOG="$STATE_DIR/harvest.log"
SLICE_BYTES="${HARVEST_SLICE_BYTES:-1500000}"
MIN_BYTES="${HARVEST_MIN_BYTES:-20000}"
MODEL="${HARVEST_MODEL:-sonnet}"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")}"
PY="$(command -v python3 2>/dev/null || true)"

mkdir -p "$STATE_DIR" "$INBOX"
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { echo "$(now) $*" >> "$LOG"; }

[ -n "$PY" ] || { log "python3 is missing — harvest disabled"; exit 0; }

# ---------- job: the harvest itself (in the background) ----------
if [ "$MODE" = "job" ]; then
  SESSION="$2"; TRANSCRIPT="$3"; FROM="$4"; TO="$5"; LOCK="$6"; STATE="$7"
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT
  TMP="$(mktemp -d)"
  "$PY" -I "$HOOKS/harvest_filter.py" "$TRANSCRIPT" "$FROM" "$TO" | head -c 400000 > "$TMP/slice.txt"
  if [ ! -s "$TMP/slice.txt" ]; then log "$SESSION L$FROM-L$TO → empty slice"; rm -rf "$TMP"; exit 0; fi
  {
    cat "$HOOKS/harvest_prompt.md"
    echo; echo "## Notes index (notes/INDEX.md)"; cat "$ROOT/notes/INDEX.md" 2>/dev/null || echo "_none_"
    echo; echo "## Principles in CLAUDE.md (headings only)"; grep -E '^### [0-9]+\.' "$ROOT/CLAUDE.md" 2>/dev/null || echo "_none_"
    echo; echo "## Transcript slice (session $SESSION, lines $FROM–$TO)"; cat "$TMP/slice.txt"
  } > "$TMP/prompt.md"

  OUT="$(cd "$ROOT" && HARVEST_CHILD=1 "$CLAUDE_BIN" -p \
        --model "$MODEL" --output-format text --max-turns 3 \
        --disallowedTools "Read,Write,Edit,Bash,Glob,Grep,WebFetch,WebSearch,Task,Agent,NotebookEdit" \
        --append-system-prompt "Do not use tools — everything you need is in the message. Answer only in the format from the instructions, no preamble." \
        --settings '{"disableAllHooks": true}' --no-session-persistence \
        < "$TMP/prompt.md" 2>>"$LOG")"
  RC=$?
  if [ $RC -ne 0 ]; then
    # failure (offline, rate limit, error) — roll the marker back so the slice is not lost
    echo "$((FROM-1))" > "$STATE"
    log "$SESSION L$FROM-L$TO → error rc=$RC, marker rolled back"
    rm -rf "$TMP"; exit 0
  fi
  # strip outer ``` fences if the model wrapped the answer
  OUT="$(printf '%s\n' "$OUT" | sed -e '1{/^```/d;}' -e '${/^```$/d;}')"
  FIRST="$(printf '%s\n' "$OUT" | grep -m1 -v '^[[:space:]]*$')"
  case "$FIRST" in
    NOTHING*|"") log "$SESSION L$FROM-L$TO → nothing" ;;
    *)
      FILE="$INBOX/$(date +%Y%m%d-%H%M)-$(printf '%s' "$SESSION" | cut -c1-8)-L$FROM-L$TO.md"
      { echo "<!-- harvest: session $SESSION, lines $FROM–$TO, $(now), model $MODEL. Merged by the agent into notes/, then deleted. -->"
        printf '%s\n' "$OUT"; } > "$FILE"
      log "$SESSION L$FROM-L$TO → $(basename "$FILE")" ;;
  esac
  rm -rf "$TMP"; exit 0
fi

# ---------- hook modes: read JSON from stdin ----------
INPUT="$(cat)"
field() { printf '%s' "$INPUT" | "$PY" -I -c 'import json,sys
try: print(json.load(sys.stdin).get(sys.argv[1],"") or "")
except Exception: print("")' "$1" 2>/dev/null; }
SESSION="$(field session_id)"
TRANSCRIPT="$(field transcript_path)"

if [ "$MODE" = "sessionstart" ]; then
  # SessionStart stdout enters the agent's context
  FILES="$(ls "$INBOX"/*.md 2>/dev/null | grep -v '/README.md$' || true)"
  if [ -n "$FILES" ]; then
    echo "The context was compacted. Harvested notes are waiting in notes/_inbox/ — merge them into notes/ when the current task is finished (principle 17):"
    printf '%s\n' "$FILES" | sed 's|.*/|  - notes/_inbox/|'
  else
    echo "The context was compacted. notes/_inbox/ is empty. The current plan is in plans/ — read its journal before you continue."
  fi
  exit 0
fi

[ -n "$SESSION" ] && [ -f "$TRANSCRIPT" ] || exit 0
STATE="$STATE_DIR/$SESSION"
LAST_LINE=0; LAST_BYTES=0
[ -f "$STATE" ] && read -r LAST_LINE LAST_BYTES < "$STATE"
LAST_LINE="${LAST_LINE:-0}"; LAST_BYTES="${LAST_BYTES:-0}"
SIZE="$("$PY" -I -c 'import os,sys; print(os.path.getsize(sys.argv[1]))' "$TRANSCRIPT" 2>/dev/null || echo 0)"
NEW_BYTES=$((SIZE - LAST_BYTES))

if [ "$MODE" = "stop" ] && [ "$NEW_BYTES" -lt "$SLICE_BYTES" ]; then exit 0; fi
[ "$NEW_BYTES" -ge "$MIN_BYTES" ] || exit 0

# One harvest per session at a time. mkdir is atomic and exists everywhere (macOS has no flock).
LOCK="$STATE_DIR/$SESSION.lock"
mkdir "$LOCK" 2>/dev/null || exit 0

TOTAL_LINES="$(wc -l < "$TRANSCRIPT" | tr -d ' ')"
FROM=$((LAST_LINE + 1)); TO="$TOTAL_LINES"
[ "$TO" -ge "$FROM" ] || { rmdir "$LOCK"; exit 0; }
# the marker moves at once so the next hook doesn't take the same slice
echo "$TO $SIZE" > "$STATE"
log "$SESSION $MODE: slice L$FROM-L$TO ($NEW_BYTES bytes) → harvest in the background"

# A separate process session so it doesn't die with the hook; macOS has no setsid, hence python.
"$PY" -I -c 'import subprocess,sys
subprocess.Popen(sys.argv[1:], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)' \
  "$HOOKS/harvest.sh" job "$SESSION" "$TRANSCRIPT" "$FROM" "$TO" "$LOCK" "$STATE"
exit 0
