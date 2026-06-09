# Install for Agents

You are an AI coding agent. The user asked you to install Arcads skills. Follow this exactly.

## Step 1 — Detect the agent platform

| Agent | Path |
|---|---|
| Claude Code | `~/.claude/skills/Arcads` |
| Cursor | `~/.cursor/plugins/Arcads` |
| Codex | `~/.codex/plugins/Arcads` |
| Other | `~/.<agent>/skills/Arcads` |

## Step 2 — Download sources

Clone:

```bash
mkdir <path>
curl -L -o /tmp/skills.zip git@github.com:arcads-ai/skills.git && unzip /tmp/skills.zip -d <path>

```

