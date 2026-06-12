# Arcads Skills

Reusable AI skills for creating high-converting ads with [Arcads](https://arcads.ai).

## One-liner install (all platforms)

```bash
curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash
```

This auto-detects your installed tools and installs skills in the right place for each one. Only skill folders are copied — no repo metadata.

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

**Option B — Clone and copy skill folders manually**

```bash
git clone --depth 1 https://github.com/arcads-ai/skills.git /tmp/arcads-skills
mkdir -p ~/.agents/skills
for skill in winning-ad spy-competitor-ads hook-identifier hook-cloner winning-hook-pipeline; do
  cp -r /tmp/arcads-skills/$skill ~/.agents/skills/
done
rm -rf /tmp/arcads-skills
```

opencode automatically scans `~/.agents/skills/` — no config change needed.

**Option C — Add path explicitly**

```json
{
  "skills": {
    "paths": ["~/.agents/skills"]
  }
}
```

Restart opencode after any config change.

---

### Claude Code

Skills placed in `~/.claude/skills/` are auto-loaded.

```bash
git clone --depth 1 https://github.com/arcads-ai/skills.git /tmp/arcads-skills
mkdir -p ~/.claude/skills
for skill in winning-ad spy-competitor-ads hook-identifier hook-cloner winning-hook-pipeline; do
  cp -r /tmp/arcads-skills/$skill ~/.claude/skills/
done
rm -rf /tmp/arcads-skills
```

Or use the one-liner above — it copies skill folders to `~/.agents/skills/` which Claude Code also picks up automatically.

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
| [spy-competitor-ads](./spy-competitor-ads/SKILL.md) | Find and download the top 5 highest-performing competitor video ads from the Meta Ad Library |
| [hook-identifier](./hook-identifier/SKILL.md) | Analyze a video ad to identify its hook — returns the end timestamp and a reproduction-ready timeline |
| [hook-cloner](./hook-cloner/SKILL.md) | Clone a competitor's hook for your brand using Seedance 2.0, preserving structure while swapping identity |
| [winning-hook-pipeline](./winning-hook-pipeline/SKILL.md) | End-to-end pipeline: spy on competitors → identify the best hook → clone it for your brand |

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
