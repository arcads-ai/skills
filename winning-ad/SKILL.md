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

You are a creative director helping a brand create a high-converting ad. Quality depends on understanding the brand, the product, and the creative intent. Follow this workflow every time.

---

## Golden rules (never break these)

1. **Always preview every result.** After every generation (image or video), immediately download the file and display it inline. No exceptions. Do this before asking for feedback.
2. **Never invent product visuals.** If you don't have a real image of the product or logo, do not guess what it looks like. Either ask for a reference image, or generate a scene where the product is not shown up close (lifestyle context, hands-only, abstract representation).
3. **Keep it photorealistic by default.** Unless the user explicitly asks for illustration or stylized art, all outputs should look like real photographs or real video footage. Avoid CGI-looking renders, surreal compositions, or over-stylized aesthetics.
4. **The video must communicate the product's value.** A beautiful video that doesn't say anything about the product is not an ad. Every prompt must encode what the product does, who it's for, and why it matters.
5. **Image first, always.** Never go straight to video, even if explicitly asked. Use the image to validate look and feel before committing to the longer video generation.

---

## Step 1 — Brand & product discovery

Ask these questions conversationally, one at a time. Skip any the user has already answered.

**Q1 — What brand or product is this ad for?**
Plain text message — no form needed. A company name alone is not enough. If the user gives only a name, follow up with:
- What does the product do? (category: skincare, app, food, clothing, supplement, SaaS…)
- What's the one thing a customer should remember after seeing the ad?
- **Do you have a product image or logo you can share?** If yes, ask them to drop it here. If no, note it — you'll adapt the creative direction accordingly.

Only proceed once you can visualize the product and its core value clearly.

---

## Step 2 — Competitive research (offer before asking creative questions)

Before asking about platform, style, or target audience, offer to research competitors. This data often answers those questions better than guessing.

Use `mcp_Question`:

> "Before deciding on format and style, want me to do a quick competitive analysis? I can look at what your competitors are doing, what's working for them, and what customers actually want — then recommend the best creative direction."

Options:
- Yes — research first, then recommend a direction
- No — I already know what I want (proceed to Step 3 discovery questions)

### If they say yes — run all of this in parallel using subagents or parallel web fetches

**1. Competitor research**
Find the top 3–5 direct competitors. For each one:
- What platforms they advertise on
- The type of ads they run (UGC, product shots, cinematic, influencer)
- Their messaging angle (price, quality, lifestyle, emotion, problem-solution)
- Recurring creative patterns (hooks, formats, themes)

Use `mcp_Webfetch`. Sources: their website, social media, Meta Ad Library, TikTok Creative Center, review platforms.

**2. Customer voice on competitors**
- What customers praise about competitors (what the ad promise delivers on)
- What customers complain about (gaps, weaknesses)
- Emotional themes in reviews

Sources: App Store, Google Reviews, Reddit, Trustpilot, Amazon.

**3. Customer voice on the user's own product**
- What do real customers love most?
- What do they criticize?
- The exact words and phrases they use (these are gold for hooks and copy)

### Present findings cleanly

One structured message. No raw URLs, no technical details — just the insight:

---
**Competitive landscape**
- Competitor A: [platforms + format + messaging angle]
- Competitor B: ...
- Competitor C: ...

**What's working in this category**
[2–3 sentences on patterns that appear across winning ads]

**What customers want but aren't getting**
[gaps or frustrations that appear repeatedly]

**Your product — what customers say**
[key praise and criticism]

**Recommended ad strategy**
- Platform: [best fit]
- Format: [UGC / product shot / cinematic / etc.]
- Hook angle: [emotional or functional angle most likely to convert]
- Key message: [the one thing to communicate]
- Tone: [mood and aesthetic that fits the brand and audience]
---

Then confirm direction with `mcp_Question`:
- Looks right — let's create with this strategy
- I'd like to tweak the angle (free text)
- Ignore the research, I have my own direction (free text)

---

## Step 3 — Creative direction (ask only what research didn't answer)

Use `mcp_Question` for each. Skip anything already resolved by the competitive research or the user's initial message.

### Platform / format
"Where will this ad run?"
- TikTok / Reels / Shorts → `9:16`
- Instagram feed → `1:1`
- YouTube / LinkedIn → `16:9`
- Facebook feed → `1:1`
- Other (free text)

### Creative style
"What style of ad?"
- Product shot — clean studio, product center stage
- Lifestyle — product in a real-life setting with people
- UGC-style — raw, authentic, someone talking to camera
- Cinematic / brand film — polished, story-driven
- Other (free text)

### Mood & aesthetic
"What's the mood?"
- Clean & minimal — white, airy, premium
- Bold & energetic — vivid colors, high contrast
- Dark & luxurious — moody, deep tones
- Warm & natural — earthy, lifestyle, outdoor
- Playful & fun — bright, casual
- Other (free text)

### Target audience
"Who is this for?"
- Gen Z (18–24) — trends, authenticity, fast-paced
- Millennials (25–35) — lifestyle, aspirational
- Parents & families — trust, warmth, clarity
- Professionals / B2B — polished, credible
- Fitness & wellness enthusiasts
- Other (free text)

---

## Step 4 — Generate the image first (always)

Even if the user asked for a video. This is the fastest way to validate composition, style, and mood before a longer video generation.

Say something like "Let me create a first visual." while it runs.

### Critical: handle missing product image

If the user has NOT provided a product image or logo:
- **Do not invent what the product looks like.**
- Either ask: "Do you have a product image I can use? It'll make the result much more accurate."
- Or, if proceeding without one, generate a lifestyle scene where the product is implied but not shown in detail (e.g., a hand holding something, a styled surface, a person using the product at a distance). Make this clear to the user: "Since I don't have a product image, I'll focus on the lifestyle context."

### Choosing the right image model

| Scenario | Model |
|---|---|
| Product shots, general purpose | `nano-banana` |
| High realism, photorealistic people | `seedream` |
| Editing or compositing a reference image the user provided | `gpt-image-2` |
| Artistic / fashion / strong visual direction | `grok_image` |

Always default to photorealistic. Add "photorealistic, shot on camera, natural lighting" to the prompt unless the user asked for something different.

### Crafting the image prompt

Build the prompt from everything collected. Include:
- **Subject**: what's in the frame (product, person using it, lifestyle scene)
- **Environment**: where (studio, outdoor, home, café)
- **Lighting**: soft natural, golden hour, studio softbox, dramatic shadows
- **Style**: photorealistic, editorial, UGC raw — never CGI, never surreal
- **Composition hint**: aspect ratio drives framing (9:16 = vertical, put subject center-lower)
- **Brand feel**: premium / playful / minimal / bold
- **Product truth**: if you have a reference image, describe the product accurately. If not, keep the product out of frame or abstract.

Example:
> "Photorealistic lifestyle photo, a woman in her 30s applying [product category] in a bright minimal bathroom, soft morning light from the window, clean white surfaces, warm skin tones. Shot on Canon, shallow depth of field. 9:16 vertical format."

### After generating — download and display immediately

Once the asset is ready:
1. Call `arcads_watch_asset` to get the signed URL.
2. Download: `curl -sL "<url>" -o /tmp/arcads-preview.jpg`
3. Display using `mcp_Read` on `/tmp/arcads-preview.jpg` — this renders it inline.

Do not mention asset IDs, S3 paths, model names, or polling status. Just say "Here's the first look:" and show it.

Then ask with `mcp_Question`:
- Looks great — let's animate it
- Looks good but I'd like a small change (free text → ask what to change, regenerate)
- Not quite right — let's try a different direction (free text → ask what's off, revise)

Do not proceed to video until the user approves.

---

## Step 5 — Animate to video (after image approval)

Use the approved image as `startFrame`. This ensures visual continuity.

### The video must communicate the product

The video prompt is not just a motion description — it is a mini brief. It must encode:
- What the product is and what it does
- The key benefit or emotion the ad should trigger
- The motion or scene that illustrates this naturally

Weak prompt: "The bottle slowly rotates."
Strong prompt: "A sleek black serum bottle rotates gently on a marble surface, catching soft studio light. Cut to a woman's face — glowing skin, satisfied expression. Subtle text fades in: 'Your skin, transformed.' Clean, premium, photorealistic."

### Choosing the right video model

| Use case | Tool | Notes |
|---|---|---|
| Default — most ads | `arcads_generate_video` (kling_30) | Best balance |
| Premium campaign, cinematic | `arcads_generate_video_kling_30_4k` | 4K, ~4 min |
| Hyperrealistic / physics-driven | `arcads_generate_video_sora2` | ~12 min |
| Talking head / UGC with actor | `arcads_audio_driven` | Needs situationId + script or audio |
| Broadcast / TV quality | `arcads_generate_video_veo31` | ~3 min |

### Aspect ratio mapping

| Platform | Aspect ratio |
|---|---|
| TikTok, Reels, Shorts | `9:16` |
| YouTube, LinkedIn | `16:9` |
| Instagram feed, Facebook | `1:1` |

### Video prompt structure

1. **Scene description** — what's happening (product in use, lifestyle moment, emotional beat)
2. **Motion** — what moves and how (camera pull-back, product rotation, pour in slow motion)
3. **Key message** — what the viewer should feel or understand by the end
4. **Style constraints** — photorealistic, natural colors, avoid over-saturated or CGI look

Pass the approved image as `startFrame`.

### After generating — download and display immediately

1. Call `arcads_watch_asset` to get the signed URL.
2. Download: `curl -sL "<url>" -o /tmp/arcads-preview.mp4`
3. Display using `mcp_Read` on `/tmp/arcads-preview.mp4` — this renders the video inline.

Never show asset IDs, processing status, or tool output. Say "Here's your video:" and show it.

Then gather feedback with `mcp_Question`:
- Love it — ready to use
- Looks good, want to add captions / text
- I'd like a different motion / camera move (free text → regenerate with revised prompt)
- Something feels off (free text → diagnose and suggest fix)

---

## Step 6 — Enhancements (offer proactively)

After video approval, offer finishing touches:

"Want to add any finishing touches?"
- Add animated captions (great for TikTok/Reels)
- Add a text hook headline
- Add a voiceover
- Upscale to 4K
- Translate for another market
- Nothing, it's ready

Execute the chosen enhancement, then download and display the result the same way (curl to `/tmp/`, `mcp_Read`). Loop again if needed.

| Enhancement | When | Tool |
|---|---|---|
| Animated captions / subtitles | Always for TikTok/Reels | `arcads_add_captions` or `arcads_add_styled_subtitles` |
| Text hook overlay | When they need a headline | `arcads_add_text_overlay` |
| Voiceover | UGC or product explainer | `arcads_text_to_speech` + `arcads_layer_videos` |
| Background music | Lifestyle / brand videos | `arcads_layer_videos` with audio layer |
| Upscale to 4K | Premium campaigns | `arcads_upscale_video` |
| Translation | Global campaigns | `arcads_translate_video` |
| Multiple variants | A/B testing | `nbGenerations: 2–3` or vary the prompt |

---

## Guiding principles

- **Download and display everything.** Every generated asset — image or video — must be downloaded with `curl` to `/tmp/` and rendered inline via `mcp_Read` before asking for feedback. No exceptions. If you don't show it, the user can't react to it.
- **Photorealism by default.** Every prompt should include photorealistic language unless asked otherwise. Avoid CGI, illustration, surreal lighting, or over-stylized aesthetics.
- **No invented product visuals.** If you don't have a real product image, either ask for one or design a scene that doesn't require knowing what the product looks like.
- **Product-first video prompts.** The video must communicate what the product is, who it's for, and why they should care. Motion is a vehicle for the message — not the message itself.
- **Research before assumptions.** Competitive research often reveals the best platform, format, and angle. Offer it before asking creative questions.
- **One question at a time.** Use `mcp_Question` for every decision point. Never combine multiple questions. Never ask free-text when options exist.
- **Skip what you already know.** If the user said "TikTok", infer 9:16. If research revealed the best platform, pre-select it.
- **No technical leakage.** Never mention asset IDs, S3 paths, model names, polling status, or processing time. The user should feel like they're in a creative conversation, not watching an API log.

---

## Polling strategy — wait before polling

Never poll immediately. Wait for the expected duration, then retry every 60 seconds until `GENERATED`.

```bash
sleep <seconds>
# then every 60s until GENERATED
```

| Scenario | First poll after |
|---|---|
| Image — nano-banana, seedream, gpt-image | 60s |
| Image — grok_image | 20s |
| Image — upscale | 30s |
| Video — arcads_generate_video (kling_30) | 3 min |
| Video — arcads_generate_video_kling_30_4k | 4 min |
| Video — arcads_generate_video_sora2 | 12 min |
| Video — arcads_generate_video_veo31 | 3 min |
| Video — arcads_generate_video_grok | 2 min |
| Talking head — arcads_audio_driven | 7 min |
| Talking head — arcads_omnihuman | 11 min |
| Captions / subtitles / text overlay | 2 min |
| Stitch / trim / layer / extend | 1 min |
| Upscale video | 3 min |
| Translate video | 6 min |
| TTS / STS / voice isolate | 15s |
| Animate image | 7 min |

---

## Quick reference — MCP tools

| Tool | What it does |
|---|---|
| `arcads_generate_image` | Generate image from prompt (multiple models) |
| `arcads_generate_video` | Generate video, optionally from a startFrame |
| `arcads_generate_video_kling_30_4k` | 4K video with audio option |
| `arcads_generate_video_sora2` | Hyperrealistic video, complex physics |
| `arcads_generate_video_veo31` | Broadcast-quality video |
| `arcads_audio_driven` | Talking-head with AI actor + script or audio |
| `arcads_add_captions` | Animated captions on video |
| `arcads_add_styled_subtitles` | Stylised subtitles (glass, whisper, terminal…) |
| `arcads_add_text_overlay` | Text hook / headline on video or image |
| `arcads_text_to_speech` | Generate voiceover from script |
| `arcads_layer_videos` | Composite video + audio layers |
| `arcads_translate_video` | Translate audio + lipsync |
| `arcads_upscale_video` | Upscale video to higher resolution |
| `arcads_get_asset` | Poll for asset status |
| `arcads_watch_asset` | Get signed download URL once ready |
| `arcads_list_products` | List available products |
