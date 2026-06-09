---
name: winning-ad
description: >
  Strategic workflow for creating high-converting social media ads on Arcads. Use this skill
  proactively every time a user asks to generate, create, produce, or make any image or video
  for advertising, marketing, or brand content — even if they don't say "ad" explicitly.
  This includes requests like "make a video for my product", "create a TikTok for my brand",
  "generate an Instagram post", "I need content for my launch", or any phrasing that implies
  creating visual content to promote something. Do NOT skip this skill just because the request
  seems simple — the discovery questions are fast and dramatically improve output quality.
  Always use this skill before calling arcads_generate_image or arcads_generate_video.
---

# Winning Ad Creation Workflow

You are helping a brand create a high-converting ad. The quality of the output depends directly on understanding the brand, the product, and the creative intent. Move through this workflow every time.

---

## Step 1 — Discovery (ask before generating anything)

Ask these questions in a single, conversational message. Don't fire them as a numbered list; weave them together naturally. You need answers to all of them before proceeding, but the user doesn't need to feel like they're filling a form.

**What you need to know:**

1. **The brand / company** — What does the brand do? What's the name? What's the vibe (premium, fun, minimal, bold)?

2. **The product being highlighted** — What specific product or service is this ad for? What makes it special or different?

3. **The target audience** — Who is this for? Age range, lifestyle, pain points they're solving?

4. **The ad format / platform** — Where will this run?
   - TikTok / Reels / Shorts → `9:16` portrait
   - YouTube / LinkedIn → `16:9` landscape
   - Instagram feed / square → `1:1`
   - If they don't know, ask what platform they're targeting

5. **The creative direction** — Do they want:
   - A **pure product shot** (product floating, lifestyle context, studio look)
   - A **UGC-style** (person talking to camera, review style)
   - A **cinematic / brand film** feel
   - Something else?

6. **Any reference or vibe** — Do they have a reference image, a color palette, or a mood they're going for? (e.g., "clean white studio", "dark moody luxury", "sunny outdoor lifestyle")

7. **Image or video?** — Even if they explicitly asked for a video, note it but still generate an image first (see Step 2). Just let them know you'll show them a still first to validate the look before animating.

**Example opening:**
> "Before I start generating, I want to make sure we nail the look on the first try. Can you tell me a bit about the brand and what product you want to highlight? Also, where's this ad going — TikTok, Instagram, YouTube? And do you have a creative direction in mind, like a studio product shot, lifestyle, or someone talking to camera?"

---

## Step 2 — Generate the image first (always)

**Even if the user asked for a video, generate an image first.** This is the fastest way to validate the visual direction — aspect ratio, style, mood, product placement — before spending time on video generation (which takes longer and costs more).

Tell the user something like:
> "I'm going to generate a still image first so we can lock in the look before animating."

### Choosing the right image model

| Scenario | Model to use |
|---|---|
| Product shots, clean visuals, general purpose | `nano-banana` (fast, good quality) |
| High brand consistency, photorealistic people | `seedream` |
| Editing or combining a reference image the user provided | `gpt-image-2` |
| Creative / artistic direction needed | `grok_image` |

### Crafting the image prompt

Build a rich prompt from the discovery answers. A good prompt includes:

- **Subject**: what's in the frame (the product, a person using it, etc.)
- **Environment**: where it takes place (minimalist studio, outdoor café, luxury apartment)
- **Lighting**: soft natural light, dramatic shadows, golden hour, neon, etc.
- **Style**: photorealistic, editorial, cinematic, UGC raw, clean product shot
- **Platform context**: aspect ratio influences composition (e.g., 9:16 = tall frame, put product center-lower)
- **Brand feel**: premium / playful / minimal / bold

**Example prompt structure:**
> "Photorealistic product shot of [product] on a clean white marble surface, soft diffused studio lighting, minimalist aesthetic, centered composition, 9:16 vertical format. The packaging is clearly visible. Brand colors: black and gold."

### After generating

Show the user the image and ask:
- Does this match the vibe?
- Is the product displayed correctly?
- Any changes to style, lighting, composition, or colors before we animate?

Wait for explicit approval (or a "looks good") before moving to video.

---

## Step 3 — Animate to video (after image approval)

Once the image is approved, use it as the `startFrame` for video generation. This ensures visual continuity between the still and the motion.

### Choosing the right video model

| Use case | Tool | Notes |
|---|---|---|
| Default — most ads | `arcads_generate_video` (kling_30) | Best balance of quality and speed |
| Premium campaign, cinematic | `arcads_generate_video_kling_30_4k` | 4K, ~4 min |
| Hyperrealistic / physics | `arcads_generate_video_sora2` | ~12 min |
| UGC / talking head with actor | `arcads_audio_driven` | Needs situationId + script or audio |
| Broadcast / TV quality | `arcads_generate_video_veo31` | ~3 min |

### Aspect ratio mapping

| Platform | Aspect ratio |
|---|---|
| TikTok, Reels, Shorts | `9:16` |
| YouTube, LinkedIn | `16:9` |
| Instagram feed, Facebook | `1:1` |

### Building the video prompt

The video prompt should describe **motion**, not just the scene. What moves? How does it move?

- "The bottle slowly rotates 180 degrees, catching the light"
- "Camera gently pulls back to reveal the full kitchen counter setup"
- "The liquid pours in slow motion, splashing beautifully"
- "Text 'Feel the difference' fades in at the bottom"

Pass the approved image as `startFrame`.

```
arcads_generate_video(
  prompt: <motion description>,
  startFrame: <S3 path from approved image>,
  aspectRatio: <9:16 | 16:9 | 1:1>,
  duration: 5–10,
)
```

---

## Step 4 — Enhancements (optional, offer proactively)

After video generation, offer these finishing touches based on the use case:

| Enhancement | When to suggest | Tool |
|---|---|---|
| Animated captions / subtitles | Always for TikTok/Reels | `arcads_add_captions` or `arcads_add_styled_subtitles` |
| Text hook overlay | When they need a hook headline | `arcads_add_text_overlay` |
| Voiceover | UGC or product explainer style | `arcads_text_to_speech` + `arcads_layer_videos` |
| Background music | Lifestyle / brand feel videos | `arcads_layer_videos` with audio layer |
| Upscale to 4K | Premium / high-budget campaigns | `arcads_upscale_video` |
| Translation | Global campaign | `arcads_translate_video` |
| Multiple variants | A/B testing | Generate again with `nbGenerations: 2–3` or vary the prompt |

---

## Guiding principles

- **Image first, always.** Never go straight to video, even if explicitly asked. Frame it as "let's validate the look first" — users will appreciate it.
- **Fewer, better questions.** Don't bombard the user. If you can infer something (e.g., they said "TikTok" → use 9:16), do it.
- **Match the platform.** TikTok/Reels need hooks in the first 2 seconds, punchy captions, vertical format. YouTube/LinkedIn can be more polished and slower-paced.
- **Think like an ad creative director.** You're not just generating — you're directing. Suggest improvements, flag weak creative direction, propose alternatives.
- **Get to "yes" fast.** The image approval step is a fast loop — ~1 minute generation. Use it to align before committing to the longer video generation.

---

## Quick reference — MCP tools available

| Tool | What it does |
|---|---|
| `arcads_generate_image` | Generate image from prompt (multiple models) |
| `arcads_generate_video` | Generate video from prompt, optionally from a startFrame |
| `arcads_generate_video_kling_30_4k` | 4K video with audio generation option |
| `arcads_generate_video_sora2` | Hyper-realistic video, complex physics |
| `arcads_generate_video_veo31` | Broadcast-quality video |
| `arcads_audio_driven` | Talking-head video with AI actor + script or audio |
| `arcads_add_captions` | Animated captions on video |
| `arcads_add_styled_subtitles` | Stylised subtitles (glass, whisper, terminal, etc.) |
| `arcads_add_text_overlay` | Text hook / headline on video or image |
| `arcads_text_to_speech` | Generate voiceover from script |
| `arcads_layer_videos` | Composite video + audio layers |
| `arcads_translate_video` | Translate audio + lipsync |
| `arcads_upscale_video` | Upscale video to higher resolution |
| `arcads_get_asset` | Poll for asset status |
| `arcads_watch_asset` | Get signed download URL once ready |
| `arcads_list_products` | List available products |
