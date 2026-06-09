# Arcads Skills

Reusable AI skills for creating high-converting ads with [Arcads](https://arcads.ai).

## One-liner install (all platforms)

```bash
curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash
```

This auto-detects your installed tools and installs skills in the right place for each one.

---

## Platform-specific instructions

### opencode

**Option A — URL-based (no clone needed)**

Add to `~/.config/opencode/opencode.json`:

```json
{
  "skills": {
    "urls": ["https://raw.githubusercontent.com/arcads-ai/skills/main/skills.json"]
  }
}
```

**Option B — Clone and reference by path**

```bash
git clone https://github.com/arcads-ai/skills.git ~/.agents/skills/arcads
```

opencode automatically scans `~/.agents/skills/` — no config change needed.

**Option C — Add path explicitly**

```json
{
  "skills": {
    "paths": ["~/.agents/skills/arcads"]
  }
}
```

Restart opencode after any config change.

---

### Claude Code

Skills placed in `~/.claude/skills/` are auto-loaded.

```bash
git clone https://github.com/arcads-ai/skills.git ~/.claude/skills/arcads
```

Or use the one-liner above — it clones to `~/.agents/skills/arcads` which Claude Code also picks up automatically.

---

### Cursor

The installer writes `.cursor/rules/arcads-<skill>.mdc` files in your current project directory.

```bash
# Run from your project root
curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | TARGET=cursor bash
```

Or install manually — copy the content of any `SKILL.md` into a new file under `.cursor/rules/`.

---

### GitHub Copilot / Codex

The installer appends skill content to `AGENTS.md` and `.github/copilot-instructions.md` in your project.

```bash
# Run from your project root
curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | TARGET=codex bash
```

---

## Available skills

| Skill | Description |
|---|---|
| [winning-ad](./winning-ad/SKILL.md) | Step-by-step workflow for creating high-converting ads: discovery → image → video → enhancements |

---

## Machine-readable manifest

[`skills.json`](./skills.json) lists all skills with their raw file URLs. Use it for programmatic discovery or custom integrations.

```
https://raw.githubusercontent.com/arcads-ai/skills/main/skills.json
```

---

## Install options

| Env var | Values | Default |
|---|---|---|
| `TARGET` | `opencode`, `claude`, `cursor`, `codex`, `all` | auto-detected |
| `SKILLS_DIR` | Any path | `~/.agents/skills` |

Examples:

```bash
# Only install for Cursor in the current project
TARGET=cursor curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash

# Install to a custom directory
SKILLS_DIR=~/my-skills curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash
```
