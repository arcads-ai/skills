---
name: winning-hook-pipeline
description: >
  End-to-end pipeline: find the top-performing competitor ads, identify the best hook,
  and clone it for the user's brand — all in one flow. Orchestrates three skills in
  sequence: spy-competitor-ads → hook-identifier → hook-cloner. Use this skill whenever
  the user wants to do all three steps together: "clone winning hooks from competitors
  for my brand", "find what's working in my category and adapt it", "spy on competitors
  and recreate their best hook", "I want to take a winning ad hook and make it mine",
  "find competitor hooks and clone them", "what are competitors running and can we make
  something like it", or any phrasing that implies the full research-to-production
  workflow. Trigger this before any of the individual skills when the intent covers more
  than one phase of the pipeline.
---

# Winning Hook Pipeline

This skill orchestrates three specialized skills back-to-back. Your job is to run them in order, handle the handoffs between them cleanly, and make sure the right data flows from each step into the next.

The three acts:
1. **Find** — `spy-competitor-ads` discovers and downloads the top 5 competitor videos
2. **Identify** — `hook-identifier` extracts the hook from the chosen video
3. **Clone** — `hook-cloner` recreates the hook for the user's brand

---

## Act 1 — Find winning ads

Load the `spy-competitor-ads` skill:

```
mcp_Skill("spy-competitor-ads")
```

Follow its instructions completely. It handles brand discovery, competitor research, Meta Ad Library scraping, ranking, and presenting the top 5 videos with a brief.

**Handoff**: After the 5 ads are presented, do not offer the standard spy-competitor-ads next-step menu. Instead, ask with `mcp_Question`:

> "Which of these hooks do you want to clone for your brand?"

Options: the 5 competitor names (e.g., "BrandX — #1", "BrandY — #2", …) plus "Pick the best one for me".

If the user says "pick the best one for me", choose the #1 ranked ad (highest impressions). Once a video is selected, proceed to Act 2 with its local file path (`/tmp/spy-ad-<rank>-<competitor>.mp4`).

---

## Act 2 — Identify the hook

Load the `hook-identifier` skill:

```
mcp_Skill("hook-identifier")
```

Pass it the video file path from Act 1. Follow its instructions — it calls `arcads_analyze_media` and returns:
- Hook end timestamp
- Frame-by-frame timeline of the hook
- Why the hook works

**Handoff**: Keep the full hook analysis in context. You'll pass it directly to Act 3 — the user does not need to do anything between these two steps.

---

## Act 3 — Clone for the user's brand

Load the `hook-cloner` skill:

```
mcp_Skill("hook-cloner")
```

The hook analysis from Act 2 is already in context — `hook-cloner` will pick it up automatically (it handles the "hook-identifier output already in conversation" entry point). Follow its instructions: collect brand info, adapt the script, generate with Seedance 2.0.

**Note on brand info**: if the user already described their brand during Act 1 (spy-competitor-ads asks for brand + category), carry that context forward. `hook-cloner` should skip questions already answered.

---

## Between acts — no unnecessary pauses

Don't ask "ready to move on?" between acts. The flow is:
- Act 1 ends → immediately ask which video to clone
- Video selected → immediately run Act 2 (no confirmation needed)
- Act 2 ends → immediately start Act 3 (hook analysis is in context, no user action needed)

The user started this because they want the full pipeline. Every extra confirmation is friction.
