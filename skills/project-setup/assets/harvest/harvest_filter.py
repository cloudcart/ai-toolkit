#!/usr/bin/env python3
"""Filter a slice of a Claude Code session transcript (JSONL) into compact text for the harvester.

Usage: harvest_filter.py <transcript.jsonl> <from_line> <to_line>
Prints: user messages, assistant text, tool names with short inputs, truncated tool results.
Skips thinking blocks and system reminders. Redacts things that look like secrets.
Every entry carries [L<line>] so a note can cite its source line.
"""
import json, re, sys

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9_\-]{10,}"),
    re.compile(r"ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}"),
    re.compile(r"(?i)(bearer\s+)[A-Za-z0-9_\-\.]{16,}"),
    re.compile(r"(?i)((?:api[_-]?key|secret|token|password|passwd|pwd)\s*[=:]\s*)[\"']?[^\s\"']{6,}"),
    re.compile(r"\b[0-9a-f]{40,}\b"),
]

def redact(s: str) -> str:
    for p in SECRET_PATTERNS:
        s = p.sub(lambda m: (m.group(1) if m.lastindex else "") + "[REDACTED]", s)
    return s

def trunc(s: str, n: int) -> str:
    s = s.replace("\n", "⏎")
    return s if len(s) <= n else s[:n] + f"…[+{len(s)-n}]"

def main():
    path, lo, hi = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    out = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for i, ln in enumerate(f, start=1):
            if i < lo:
                continue
            if i > hi:
                break
            try:
                d = json.loads(ln)
            except Exception:
                continue
            t = d.get("type")
            m = d.get("message") or {}
            c = m.get("content")
            if t == "user":
                if d.get("isCompactSummary"):
                    out.append(f"[L{i}] --- compaction ---")
                    continue
                blocks = [{"type": "text", "text": c}] if isinstance(c, str) else (c or [])
                for b in blocks:
                    if b.get("type") == "text":
                        txt = b["text"].strip()
                        # system insertions, not the user's words: reminders, slash commands, skill bodies, notifications
                        if txt.startswith(("<system-reminder>", "<local-command", "<command-name>", "<task-notification>",
                                           "Base directory for this skill:", "[SYSTEM NOTIFICATION")):
                            continue
                        out.append(f"[L{i}] USER: {redact(trunc(txt, 1500))}")
                    elif b.get("type") == "tool_result":
                        cc = b.get("content")
                        if isinstance(cc, list):
                            cc = " ".join(x.get("text", "") for x in cc if isinstance(x, dict))
                        out.append(f"[L{i}]   result: {redact(trunc(str(cc), 200))}")
            elif t == "assistant" and isinstance(c, list):
                for b in c:
                    bt = b.get("type")
                    if bt == "text":
                        out.append(f"[L{i}] AGENT: {redact(trunc(b['text'].strip(), 2000))}")
                    elif bt == "tool_use":
                        inp = b.get("input", {})
                        name = b.get("name", "?")
                        if name in ("Write", "Edit", "Read"):
                            summ = str(inp.get("file_path", ""))
                        elif name == "Bash":
                            summ = str(inp.get("description") or inp.get("command", ""))[:150]
                        else:
                            summ = json.dumps(inp, ensure_ascii=False)[:150]
                        out.append(f"[L{i}]   tool {name}: {redact(summ)}")
    sys.stdout.write("\n".join(out) + ("\n" if out else ""))

if __name__ == "__main__":
    main()
