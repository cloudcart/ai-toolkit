#!/usr/bin/env bash
# Turn on marketplace auto-update for this toolkit, once.
#
# Runs as a Claude Code SessionStart hook. Claude Code leaves auto-update off
# for third-party marketplaces, so a plugin that ships fixes weekly would sit
# unused on the installed version. This sets `autoUpdate: true` on the
# cloudcart-ai-toolkit entry in the user's settings so the toolkit keeps itself
# current.
#
# It writes AT MOST ONCE, ever, and records that it did. If the user later turns
# auto-update off — in /plugin or by hand — the stamp keeps this from switching
# it back on at the next session. A hook that re-asserted the value every start
# would be fighting the person who owns the file.
#
# Opt out before the first run with CLOUDCART_AUTO_UPDATE=0.
#
# Prints one line, only on the run that changes something, so the agent can
# mention it once. Exit status is always 0: this must never block a session.

set -u

[ "${CLOUDCART_AUTO_UPDATE:-1}" = "0" ] && exit 0

SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
MARKETPLACE="${CLOUDCART_MARKETPLACE:-cloudcart-ai-toolkit}"
DATA="${CLAUDE_PLUGIN_DATA:-${CLOUDCART_WIKI_HOME:-$HOME/.cloudcart-ai-toolkit}}"
STAMP="$DATA/auto-update-set"

[ -e "$STAMP" ] && exit 0
[ -f "$SETTINGS" ] || exit 0

python3 -I - "$SETTINGS" "$MARKETPLACE" "$STAMP" <<'PY' || exit 0
import json, os, sys, tempfile

settings, marketplace, stamp = sys.argv[1], sys.argv[2], sys.argv[3]

try:
    with open(settings) as fh:
        data = json.load(fh)
except Exception:
    sys.exit(0)                      # unreadable or mid-write: leave it alone

entry = data.get("extraKnownMarketplaces", {}).get(marketplace)
if not isinstance(entry, dict):
    sys.exit(0)                      # installed in another scope; not ours to guess
if "autoUpdate" in entry:
    # Already decided, either way. Record that so we never look again.
    try:
        os.makedirs(os.path.dirname(stamp), exist_ok=True)
        open(stamp, "w").close()
    except Exception:
        pass
    sys.exit(0)

entry["autoUpdate"] = True

# Write via a temp file in the same directory, then replace: a crash or a full
# disk must not leave the user with a truncated settings file.
directory = os.path.dirname(settings) or "."
try:
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".settings-", suffix=".json")
    with os.fdopen(fd, "w") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    os.replace(tmp, settings)
except Exception:
    try:
        os.unlink(tmp)
    except Exception:
        pass
    sys.exit(0)

try:
    os.makedirs(os.path.dirname(stamp), exist_ok=True)
    open(stamp, "w").close()
except Exception:
    pass

print(
    "The CloudCart toolkit set itself to update automatically "
    "(auto-update for the cloudcart-ai-toolkit marketplace). Mention this once, "
    "in one short sentence, and that it can be turned off in /plugin under "
    "Marketplaces."
)
PY
exit 0
