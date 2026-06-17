# Arcads Skills

Reusable AI skills for creating high-converting ads with [Arcads](https://arcads.ai).

This repository is published as a **Claude Code plugin** *and* as a multi-tool skill bundle (opencode, Cursor, Codex). Pick whichever path fits your environment.

## One-liner install (all platforms)

```bash
curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash
```

This auto-detects your installed tools and installs skills in the right place for each one. Only skill folders are copied — no repo metadata.

---

## Platform-specific instructions

### Claude Code (plugin)

This repo is a Claude Code plugin marketplace. Install from inside Claude Code:

```shell
/plugin marketplace add arcads-ai/skills
/plugin install arcads@arcads
```

After install, the 4 skills are available namespaced under `arcads`:

- `arcads:spy-competitor-ads`
- `arcads:clone-hook`
- `arcads:clone-static-ad`
- `arcads:media-router`

The plugin also bundles the **Arcads MCP server** (`https://mcp.arcads.ai`), which exposes the `arcads_*` tools (`arcads_generate_image`, `arcads_generate_video_seedance_20`, `arcads_analyze_media`, `arcads_get_upload_url`, `arcads_get_asset`, `arcads_watch_asset`, etc.) that the skills call. It uses OAuth — after install, run `/mcp` once and follow the browser flow to authenticate. Tokens are stored securely and refreshed automatically.

Update later with `/plugin marketplace update arcads` then `/plugin update arcads@arcads`.

To test a local checkout before publishing:

```bash
claude --plugin-dir /path/to/skills
```

---

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
for skill in spy-competitor-ads clone-hook clone-static-ad media-router; do
  cp -r /tmp/arcads-skills/skills/$skill ~/.agents/skills/
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

### Claude Code (standalone skills, no plugin)

If you don't want to use the plugin manifest, skills placed in `~/.claude/skills/` are also auto-loaded.

```bash
git clone --depth 1 https://github.com/arcads-ai/skills.git /tmp/arcads-skills
mkdir -p ~/.claude/skills
for skill in spy-competitor-ads clone-hook clone-static-ad media-router; do
  cp -r /tmp/arcads-skills/skills/$skill ~/.claude/skills/
done
rm -rf /tmp/arcads-skills
```

Or use the one-liner installer at the top — it copies skill folders to `~/.agents/skills/` which Claude Code also picks up automatically.

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


| Skill                                                            | Description                                                                                               |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| [spy-competitor-ads](./skills/spy-competitor-ads/SKILL.md)       | Find and download top competitor ads from the Meta Ad Library — videos by default, statics on request     |
| [clone-hook](./skills/clone-hook/SKILL.md)                       | Identify a video ad's hook AND clone it for your brand in one flow (auto-sources a video if none given)   |
| [clone-static-ad](./skills/clone-static-ad/SKILL.md)             | Clone a static (image) ad for your brand using arcads_generate_image, preserving layout/copy structure    |
| [media-router](./skills/media-router/SKILL.md)                   | Smart router: dynamically picks the best Arcads MCP tool for any generate/edit/repurpose image or video   |


---

## Machine-readable manifest

`[skills.json](./skills.json)` lists all skills with their raw file URLs. Use it for programmatic discovery or custom integrations.

```
https://raw.githubusercontent.com/arcads-ai/skills/main/skills.json
```

---

## Install options


| Env var      | Values                                         | Default            |
| ------------ | ---------------------------------------------- | ------------------ |
| `TARGET`     | `opencode`, `claude`, `cursor`, `codex`, `all` | auto-detected      |
| `SKILLS_DIR` | Any path                                       | `~/.agents/skills` |


Examples:

```bash
# Only install for Cursor in the current project
TARGET=cursor curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash

# Install to a custom directory
SKILLS_DIR=~/my-skills curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash
```

