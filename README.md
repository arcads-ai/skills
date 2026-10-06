# Arcads Skills

Shared Arcads skills for Claude and Codex/OpenAI.

## Skills

| Skill | Purpose |
| --- | --- |
| [ads](skills/ads/SKILL.md) | Plan and create ads from a marketing goal. |
| [amazon-listing-system](skills/amazon-listing-system/SKILL.md) | Create an Amazon listing image set from a product. |
| [animated-ad](skills/animated-ad/SKILL.md) | Create paper-collage animated ad scripts and prompts. |
| [cinematic-ads](skills/cinematic-ads/SKILL.md) | Create a cinematic, story-driven short film ad for an e-com product. |
| [clone-hook](skills/clone-hook/SKILL.md) | Adapt a reference video’s hook for your brand. |
| [clone-static-ad](skills/clone-static-ad/SKILL.md) | Adapt a static ad for your product. |
| [collage-motion](skills/collage-motion/SKILL.md) | Generate and animate paper-collage creatives. |
| [fpv-drone-path](skills/fpv-drone-path/SKILL.md) | Turn a drawn flight path into an FPV video. |
| [image-to-motion](skills/image-to-motion/SKILL.md) | Animate a still image into a motion graphic. |
| [media-router](skills/media-router/SKILL.md) | Route media requests to the appropriate Arcads tool. |
| [omniflash-restyle](skills/omniflash-restyle/SKILL.md) | Restyle talking-head footage using a reference edit. |
| [pixar-ad](skills/pixar-ad/SKILL.md) | Create a stylized 3D animated product ad. |
| [spy-competitor-ads](skills/spy-competitor-ads/SKILL.md) | Find competitor ads in the Meta Ad Library. |
| [static-to-motion](skills/static-to-motion/SKILL.md) | Turn a finished static ad into a short video. |
| [tsunami-soundstage](skills/tsunami-soundstage/SKILL.md) | Create a miniature-flood soundstage video prompt. |
| [viral-clone](skills/viral-clone/SKILL.md) | Recreate a reference video ad with a different product. |

## Build a plugin ZIP

Requires `jq` and `zip`. From the repository root, run:

```sh
sh scripts/build-plugin.sh
```

Choose **1 — Codex/OpenAI** or **2 — Claude**. The ZIP is saved to
`dist/arcads-<target>-<version>.zip`. Rebuilding the same target and version
replaces the existing ZIP.

The build includes the selected manifest, shared `skills/`, MCP configuration,
and referenced icons. Scripts and repository files are excluded.

## Updating a release

Edit skills in `skills/` and update the version in both manifests:

- `.codex-plugin/plugin.json` — OpenAI package identity and listing metadata.
- `.claude-plugin/plugin.json` — Claude package identity (`arcads`).

Keep their package names unchanged. Build the target ZIP, then upload it to
that platform. Building does not publish the plugin.
