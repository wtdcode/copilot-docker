#!/usr/bin/env python3
"""copilot-tg-notify: Send copilot hook notifications via telegram-send."""
import json
import os
import pwd
import socket
import subprocess
import sys
from pathlib import Path


def get_user_home():
    try:
        return Path(pwd.getpwuid(os.getuid()).pw_dir)
    except KeyError:
        return Path.home()


def get_last_message(transcript_path: Path, max_chars=500):
    if not transcript_path or not transcript_path.is_file():
        return ""
    for line in reversed(transcript_path.read_text().splitlines()):
        if "assistant.message" not in line and "assistant_message" not in line:
            continue
        try:
            event = json.loads(line)
            content = event.get("data", {}).get("content") or event.get("content", "")
            return content[:max_chars]
        except json.JSONDecodeError:
            continue
    return ""


def main():
    event = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    raw = sys.stdin.read()
    home = get_user_home()

    # Skip if telegram-send is not configured
    conf = home / ".config" / "telegram-send.conf"
    if not conf.is_file():
        return

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = {}

    cwd = data.get("cwd") or data.get("cwd", "")
    reason = data.get("stopReason") or data.get("hook_event_name", "")
    transcript = data.get("transcriptPath") or data.get("transcript_path", "")

    # sessionEnd doesn't include transcriptPath, derive from sessionId
    if not transcript:
        sid = data.get("sessionId") or data.get("session_id", "")
        if sid:
            candidate = home / ".copilot" / "session-state" / sid / "events.jsonl"
            if candidate.is_file():
                transcript = str(candidate)

    transcript_path = Path(transcript) if transcript else None
    last_msg = get_last_message(transcript_path)

    # Build notification
    msg = f"[Copilot] {event}"
    if reason:
        msg += f" ({reason})"
    msg += f" on {socket.gethostname()}"
    if cwd:
        msg += f" in {cwd}"
    if last_msg:
        msg += f"\n\nLast message:\n{last_msg}"

    subprocess.run(["telegram-send", msg], check=False)


if __name__ == "__main__":
    main()
