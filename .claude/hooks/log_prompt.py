#!/usr/bin/env python3
"""UserPromptSubmit hook: 사용자가 직접 쓴 프롬프트 본문만 PROMPTS.md 에 추가한다.

- stdin 으로 들어오는 hook 입력 JSON 의 `prompt` 필드만 사용한다.
  (플러그인/hook 이 덧붙이는 컨텍스트는 이 필드에 들어오지 않는다.)
- 혹시 본문에 섞여 들어온 시스템 태그 블록은 제거한다.
- stdout 에는 아무것도 쓰지 않는다. (UserPromptSubmit 의 stdout 은 모델 컨텍스트로 주입된다.)
- 어떤 경우에도 exit 0 — 기록 실패가 프롬프트 전송을 막으면 안 된다.
"""
import json
import os
import re
import sys

LOG_NAME = "PROMPTS.md"
HEADER = (
    "# Prompts\n\n"
    "이 과제를 진행하며 AI(Claude Code)에게 보낸 프롬프트 기록입니다.  \n"
    "`.claude/hooks/log_prompt.py` hook 이 내가 입력한 본문만 자동으로 추가하고,\n"
    "작업이 끝나면 프롬프트마다 구현 요소와 결과를 정리합니다.\n"
)

# 시스템·하네스가 끼워넣는 블록. 사용자가 쓴 문장이 아니므로 통째로 지운다.
NOISE_TAGS = (
    "system-reminder",
    "task-notification",
    "user-prompt-submit-hook",
    "local-command-stdout",
    "local-command-stderr",
    "local-command-caveat",
    "bash-stdout",
    "bash-stderr",
)
NOISE_RE = re.compile(
    r"<(?P<tag>%s)\b[^>]*>.*?</(?P=tag)>" % "|".join(NOISE_TAGS),
    re.DOTALL,
)


def clean(prompt: str) -> str:
    text = NOISE_RE.sub("", prompt)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def main() -> None:
    data = json.load(sys.stdin)
    prompt = data.get("prompt")
    if not isinstance(prompt, str):
        return
    body = clean(prompt)
    if not body:
        return

    root = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or os.getcwd()
    path = os.path.join(root, LOG_NAME)

    quoted = "\n".join((">" if not line else "> " + line) for line in body.split("\n"))
    entry = "\n---\n\n%s\n" % quoted

    is_new = not os.path.exists(path) or os.path.getsize(path) == 0
    with open(path, "a", encoding="utf-8") as f:
        if is_new:
            f.write(HEADER)
        f.write(entry)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
