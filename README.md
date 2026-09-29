# Arcads Skills

A Claude plugin for making ads that convert with [Arcads](https://arcads.ai). It gives Claude skills to research competitor ads, clone winning hooks and static ads for your brand, and send any image or video request to the right Arcads tool.

The plugin connects Claude to the Arcads MCP server (`https://mcp.arcads.ai`), which runs all image, video, and audio generation.

## Skills

| Skill | What it does |
|---|---|
| **`spy-competitor-ads`** | Finds and downloads your competitors' top ads from the Meta Ad Library: videos, statics, or both. If you don't name any competitors, it finds some and asks you to confirm the list. |
| **`clone-hook`** | Breaks down the hook of a video ad (timeline, casting, script, captions), then remakes it for your brand with Seedance 2.0. Each run produces two variants. If you don't provide a video, it gets one through `spy-competitor-ads`. |
| **`clone-static-ad`** | Remakes a static image ad for your product. It keeps the original's composition, lighting, palette, typography, and copy structure. Each run produces three variants. If you don't provide a reference ad, it gets one through `spy-competitor-ads`. |
| **`media-router`** | The default entry point for any other request to generate or edit media: "generate an image of…", "remove the background", "add captions", "translate this ad", "upscale this video", and so on. It reads the live Arcads tool list, picks the best tool, and runs it from start to finish. When one of the skills above fits better, it hands off to that skill. |

You can call the skills directly with `/arcads:<skill-name>`, for example `/arcads:clone-hook`, or just describe what you want and let `media-router` pick.

## Requirements

- **An Arcads account.** Generation uses your Arcads credits.
- **Claude Code** or another Claude client that supports plugins and MCP servers.
- **A browser automation MCP** (only for `spy-competitor-ads`), such as [Claude in Chrome](https://claude.com/chrome), Playwright, or Chrome DevTools. The Meta Ad Library renders with JavaScript, so it can't be scraped without a browser.

## Setup

### 1. Install the plugin

In Claude Code, add this repository as a marketplace, then install the plugin:

```
/plugin marketplace add arcads-ai/skills
/plugin install arcads@arcads
```

### 2. Connect the Arcads MCP

The plugin comes with an `.mcp.json` that registers the Arcads MCP server:

```json
{
  "mcpServers": {
    "arcads": {
      "type": "http",
      "url": "https://mcp.arcads.ai"
    }
  }
}
```

After you install, run `/mcp`, select **arcads**, and sign in with your Arcads account.

### 3. (Optional) Connect a browser

To use `spy-competitor-ads`, or to let `clone-hook` and `clone-static-ad` find reference ads on their own, connect a browser automation MCP such as the Claude in Chrome extension.

### 4. Try it

```
/arcads:spy-competitor-ads video ads for my brand, Acme Skincare
```

```
Clone the hook of ~/Downloads/competitor-ad.mp4 for my app
```

```
Generate a product shot of my serum on a marble counter
```

## Repository layout

```
.claude-plugin/
  plugin.json        # Plugin manifest
  marketplace.json   # Marketplace entry
.mcp.json            # Arcads MCP server config
skills.json          # Skill index (names, descriptions, raw URLs)
skills/
  clone-hook/SKILL.md
  clone-static-ad/SKILL.md
  media-router/SKILL.md
  spy-competitor-ads/SKILL.md
```

## License

MIT
