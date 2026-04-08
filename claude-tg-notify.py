#!/usr/bin/env python3
"""claude-tg-notify: Send Claude Code hook notifications via telegram-send."""
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


def extract_text(value):
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, list):
        parts = []
        for item in value:
            if isinstance(item, str):
                parts.append(item)
                continue
            if not isinstance(item, dict):
                continue
            text = item.get("text") or item.get("content")
            if isinstance(text, str):
                parts.append(text)
        return "\n".join(part.strip() for part in parts if part.strip())
    if isinstance(value, dict):
        for key in ("text", "content", "message"):
            text = extract_text(value.get(key))
            if text:
                return text
    return ""


def get_last_message(transcript_path: Path, max_chars=500):
    if not transcript_path or not transcript_path.is_file():
        return ""

    for line in reversed(transcript_path.read_text(errors="replace").splitlines()):
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        text = extract_text(event.get("last_assistant_message"))
        if not text:
            text = extract_text(event.get("content"))
        if not text:
            text = extract_text(event.get("message"))
        if not text:
            text = extract_text(event.get("data", {}))
        if text:
            return text[:max_chars]

    return ""


def main():
    raw = sys.stdin.read()
    home = get_user_home()

    conf = home / ".config" / "telegram-send.conf"
    if not conf.is_file():
        return

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = {}

    event = sys.argv[1] if len(sys.argv) > 1 else data.get("hook_event_name", "unknown")
    cwd = data.get("cwd") or ""
    reason = data.get("reason") or data.get("error") or ""
    transcript = data.get("transcript_path") or data.get("transcriptPath") or ""

    last_msg = extract_text(data.get("last_assistant_message"))
    if not last_msg and transcript:
        last_msg = get_last_message(Path(transcript))

    msg = f"[Claude] {event}"
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