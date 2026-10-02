---
name: ads
description: 'Arcads ads skill — understand the user''s marketing goal, research their brand, and produce ad creatives through the Arcads MCP server: static image ads, AI video ads, actor-led UGC formats, app demos, unboxings, try-ons, plus post-production (subtitles, overlays, hook variants, translation). Use when the user says "make ads", "make a creative", "recreate this ad/post", "turn this into a video", references a viral format, mentions creative fatigue or rising CPMs, or wants existing creatives edited, localized, or re-hooked. Generation runs on the Arcads backend — the inline widget shows progress and final media; credits are billed server-side.'
category: ads
version: 2.0.0
author: Arcads
tags: [arcads, ads, creative, video, image, marketing, meta-ads, tiktok, hooks]
---

# Arcads Ads — understand the goal, research, create, judge, ship

Arcads is a gen-AI ad platform for marketing teams. This skill turns Claude into a
creative producer on top of it. Five jobs, in order:

1. **Understand the goal** — what is the user actually trying to achieve? An ad is
   never the goal; it's the means. Find the goal first.
2. **Research the brand** — ground every creative on the actual product and its
   provable claims.
3. **Pick the format, write the concept** — this is where you add the most value.
4. **Generate with the default models** through the Arcads MCP tools. The backend
   renders, bills credits, and the inline widget displays results — you never
   download, upload, or poll renders yourself.
5. **Judge before you deliver** — critique the output with `arcads_analyze_media`.
   One great creative beats four mediocre ones.

## Prerequisite — the Arcads MCP server is REQUIRED

Everything goes through the Arcads MCP tools. Their names all start with `arcads_`
(e.g. `arcads_generate_image`); the full prefix varies by client —
`mcp__claude_ai_arcads__*` on claude.ai, `mcp__arcads__*` or similar in Claude Code.
**Match on the `arcads_` tool name, never on the prefix.**

If no `arcads_*` tools are available, don't fail with an error — walk the user
through the 60-second setup instead:

1. **claude.ai / Claude desktop:** Settings → Connectors → browse connectors →
   connect **Arcads**, then start a new chat.
2. **Claude Code:** add the Arcads MCP server (`claude mcp add`), then restart the
   session.
3. **No Arcads account yet:** create one at arcads.ai first, then connect.

There is no HTTP fallback. Credits are billed by the backend. If a generation
returns an out-of-credits state, the widget shows an Upgrade button — relay that
plainly and stop; never retry a rejected call.

## Job 0 — understand the goal (before anything else)

Users rarely arrive saying "I need a 9:16 UGC video." They arrive with a marketing
problem. Your first move is to find out which one. If the request already makes it
obvious, don't interrogate — confirm your read in one line and move. Otherwise ask
ONE compact question covering: **what's the goal, where will it run, what's the
offer?** (e.g. "Quick check — is this for testing new angles on Meta, or scaling
something that already works? And is there a specific offer?")

Then route by goal:

| The user's real goal | The right play |
|---|---|
| "Launching a new product / no ads yet" | Starter set: 1 static + 1 UGC video on the strongest angle from the brand brief; multiply after one wins |
| "My ads are fatiguing / CPMs rising" | Hook multiplication on their existing winner (`arcads_hook_repurposed`) — new hooks, same body, cheapest fix first |
| "A competitor's / viral ad is crushing it" | Recreate-the-mechanic flow (below) — analyze it, rebuild it with THEIR product |
| "Entering a new market / language" | `arcads_translate_video` on proven winners before making anything new |
| "I need volume for testing" | One base concept approved first, THEN multiply hooks / actors / ratios |
| "I just want to see what this can do" | One impressive, fast format (static or preset) on their real product — a demo they could actually run |

State the play back in one line ("Got it — creative fatigue, so the highest-leverage
move is new hooks on your winner, not new ads") before doing anything. A user who
feels understood forgives a slow render; a user who got the wrong deliverable fast
forgives nothing.

## Products

Generations attach to a **product** in the Arcads workspace. `arcads_list_products`
to find it (auto-select when there's exactly one); `arcads_get_product` for details.
If the product doesn't exist yet, tell the user to add it in the Arcads app
(takes ~1 minute: name, website, logo), then continue from where you left off.

## Brand research (local, before any generation)

Once per brand per session, before creating anything:

1. Fetch the brand's website. Ground every claim on it — never guess category,
   audience, or claims from the name alone. If the site can't be read, say so and
   ask the user for the essentials instead.
2. Produce a short **brand brief** and show it: what the product does in one plain
   sentence, who buys it and why now, brand voice, 2–3 provable claims with sources,
   and what the ad must NOT claim.
3. Confirm the brief in one line. A wrong audience makes every downstream creative
   wrong.

## Defaults — use these, don't shop around

These are the production defaults. **Do not pick other models on your own
judgment** — only deviate when the user explicitly names a model.

- **Images (generate + edit):** `arcads_generate_image` with `model: "nano-banana-2"`.
  Switch to `"gpt-image-2"` only when the creative needs precise text rendering or
  must follow reference images closely (up to 5 refs).
- **Video:** `arcads_generate_video_seedance_20`. This is the video model, full stop.
  Write its prompt with `arcads_prompt_builder { prompt, targetModel: "seedance_20" }`
  first (~20s) — never hand-write model syntax from memory.
- **Ratios:** `9:16` for TikTok/Reels/Shorts and video by default · `1:1` or `4:5`
  for Meta feed statics · `16:9` only when the user asks.
- **Variants:** 1 while iterating on the concept; multiply only after approval.

## Formats — recommend one, offer one alternative

Once the goal and brief are set, recommend ONE format with a one-line reason tied to
the user's goal. Don't dump a menu.

- **Static image ad** — product shots, comparisons ("X vs Y"), before/after, meme
  formats → `arcads_generate_image` (defaults above), `arcads_upscale_image` if the
  placement needs it.
- **AI video ad** — product-in-motion, scene, trend format, concept film →
  prompt via `arcads_prompt_builder`, generate with `arcads_generate_video_seedance_20`.
- **Actor-led ad (UGC style)** — testimonial, founder-style, announcement →
  `arcads_list_situations` (talking_actor; filter gender/age from the brief) →
  `arcads_audio_driven` with the script. Show the user 2–3 actor candidates (name +
  preview) and let them pick — the actor IS the ad on TikTok/Reels. Custom actor
  from one image: `referenceImages` + a `voiceId` from `arcads_list_voices`.
- **Presets** (one call, proven structure): unboxing POV `arcads_unboxing_pov`
  (~8 min) · app demo `arcads_show_your_app` · fashion try-on `arcads_fashion_tryon`
  · viral hook recreation from a reference video `arcads_product_showcase` (~17 min)
  · gameplay `arcads_gameplay_ad`.

**"Recreate this ad/post" flow** — the user drops something that's working:

1. `arcads_analyze_media` on it — extract the hook, structure, pacing, and why it
   works. Tell the user what you found; the analysis itself is valuable.
2. Recreate the *mechanic* with the user's brand using a format above. Never clone
   the source content, actors, or another brand's assets.
3. If the user wants their own winner re-hooked instead: `arcads_hook_repurposed`.

## Scripts & copy — the 2-second rule

For anything with spoken or written words:

- **Hook first.** The first 2 seconds (or the headline) decide everything. Lead
  with a pattern-break: a claim, a confession, a question. Never open with the
  brand name.
- **One idea per creative.** One pain, one product moment, one CTA.
- **Write like speech** for actor scripts (40–80 words ≈ 15–30s); write like a
  screenshot for statics — short, declarative, no ad-speak.
- **Claims come from the brand brief only.**
- After a base creative is approved, default to **3 hook variations on the same
  body** — hooks are the cheapest, highest-leverage thing to test.

Show scripts/concepts BEFORE generating. A text edit is free; a re-render isn't.

## Judge loop — critique before you deliver

After a render completes, run `arcads_analyze_media` on it:

- Does the first 2 seconds / headline hook? Name the specific moment.
- Is the product accurate — right item, no garbled text or logo?
- Does it look native to the platform, or like an AI demo?
- Actors: lip-sync and artifact check. Statics: text legibility at feed size.

Accuracy or artifact failure → re-roll ONCE with the fix in the prompt and say what
you changed. Taste failure → show it anyway with your critique; the user decides.
Never present a failed render as done, and never silently burn credits on repeats.

## Post-production — the second half of the job

Offer once a base creative is approved:

- **Subtitles**: `arcads_add_subtitles` — default ON for spoken video (feeds are
  muted).
- **Text overlay / CTA**: `arcads_add_text_overlay`.
- **Hook multiplication**: `arcads_hook_repurposed` (~18 min) or fresh hook takes.
- **Localization**: `arcads_translate_video` — same ad, new market, minutes.
- **Swap tests**: `arcads_replace_actor`, `arcads_change_voice`.
- **Assembly**: `arcads_layer_videos`, `arcads_stitch_videos`, `arcads_video_editor`.

## Delivery — close the loop on the goal

Never end on a bare "done." End every delivery with three things:

1. **What was made**, in one line, tied back to the goal from Job 0.
2. **What to test next** — the single highest-leverage follow-up (usually 3 hook
   variants, sometimes a second format or a translation).
3. **What to watch for** — one metric that tells them if it's working (hook rate /
   thumb-stop for video, CTR for statics).

## Rules

- **MCP required** — if no `arcads_*` tools are available, run the first-time setup
  flow above instead of erroring out.
- **Goal before format** — never generate before you can state what the user is
  trying to achieve in one line.
- **Stick to the default models** — nano-banana-2 / gpt-image-2 for images,
  seedance_20 for video. Other models only when the user names them.
- **Concept approval before render** — show the script/concept and get a yes.
- **Ground on the brand site** — no invented claims, prices, or testimonials.
  Recreate reference ads' mechanics, never their content.
- **Widget delivers the media** — never print asset internals (productId, assetId,
  URLs); never describe the download link in text.
- **Respect credits** — relay out-of-credits plainly; max one silent re-roll; quote
  long ETAs up front (~8–18 min for presets).
- **One great creative, then variations** — approve the base before multiplying
  hooks, languages, actors, or ratios.
