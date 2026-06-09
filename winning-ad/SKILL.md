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

## Step 1 — Discovery (ask questions one by one, with a form UI)

Ask each question **individually**, one at a time, in sequence. Do not bundle questions together. After each answer, move to the next one.

For every question, use the `mcp_Question` tool to render a form with selectable options. Always include an "Other" option so the user can write a free-text answer if none of the choices fit. Phrase each question conversationally, as if you're a creative director getting to know their project.

**The questions to ask, in order:**

### Q1 — Brand & product
"What brand or product is this ad for?"
- No predefined options here — this is always free text. Ask it as a plain conversational message (no form needed for this one).
- Once they answer, infer what you can (brand vibe, category) and move to Q2.

### Q2 — Platform / format
"Where will this ad run?"

Options:
- TikTok / Reels / Shorts → maps to `9:16`
- Instagram feed → maps to `1:1`
- YouTube / LinkedIn → maps to `16:9`
- Facebook feed → maps to `1:1`
- Other (free text)

### Q3 — Creative direction
"What style of ad do you want?"

Options:
- Product shot — clean studio, product center stage
- Lifestyle — product in a real-life setting with people
- UGC-style — raw, authentic, someone talking to camera
- Cinematic / brand film — polished, story-driven
- Other (free text)

### Q4 — Mood & vibe
"What's the mood or aesthetic you're going for?"

Options:
- Clean & minimal — white, airy, premium
- Bold & energetic — vivid colors, high contrast
- Dark & luxurious — moody, deep tones
- Warm & natural — earthy, lifestyle, outdoor
- Playful & fun — bright, pop art, casual
- Other (free text)

### Q5 — Target audience
"Who is this for?"

Options:
- Gen Z (18–24) — trends, authenticity, fast-paced
- Millennials (25–35) — lifestyle, aspirational
- Parents & families — trust, warmth, clarity
- Professionals / B2B — polished, credible
- Fitness & wellness enthusiasts
- Other (free text)

**Skip questions where the user has already given you the answer** in their initial message. Infer what you can, ask only what's missing.

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

### After generating — always preview the result

Once the asset is ready (`arcads_get_asset` returns status `GENERATED`), call `arcads_watch_asset` to get the signed URL and **display the image inline** so the user can see it immediately without leaving the conversation.

Then use `mcp_Question` to ask for approval with clear options:

"How does this look?"
- Looks great — let's animate it
- Looks good but I'd like a small change (free text → ask what to change, regenerate)
- Not quite right — let's try a different direction (free text → ask what's off, go back and revise)

Do not move to video generation until the user selects "Looks great" or equivalent approval.

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

### After generating — always preview the result

Once the video asset is ready, call `arcads_watch_asset` and **display the video inline** using the signed URL so the user can watch it directly in the conversation.

Then use `mcp_Question` to gather feedback:

"What do you think of the video?"
- Love it — ready to use
- Looks good, want to add captions / text
- I'd like a different motion / camera move (free text → regenerate with revised prompt)
- Something feels off (free text → diagnose and suggest fix)

---

## Step 4 — Enhancements (optional, offer proactively)

After video generation, offer finishing touches. Use `mcp_Question` to let the user pick what they want to add:

"Want to add any finishing touches?"
- Add animated captions (great for TikTok/Reels)
- Add a text hook headline
- Add a voiceover
- Upscale to 4K
- Translate for another market
- Nothing, it's ready!
- Other (free text)

Once they choose, execute the enhancement, preview the result inline using `arcads_watch_asset`, and loop again if needed.

**Reference table:**

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
- **One question at a time.** Use `mcp_Question` for every choice moment — platform, style, mood, approval, feedback. Never combine multiple questions into one message. Never ask free-text questions when selectable options exist.
- **Always preview.** Every generated asset (image or video) must be shown inline via `arcads_watch_asset` before asking for feedback. Never ask "how does it look?" before displaying it.
- **Fewer, better questions.** Skip what you already know. If they said "TikTok" → infer 9:16 and don't ask again.
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
