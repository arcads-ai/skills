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
- No predefined options here — always free text. Ask it as a plain conversational message (no form needed for this one).
- A company name alone is **not enough**. You need to understand the actual product. If the user only gives a brand name, follow up with the product detail questions below before moving to Q2.

**If product details are missing or vague, ask (one at a time, plain conversational messages):**

1. **What is the product?** — What does it do? What category is it (skincare, food, app, clothing, supplement, SaaS...)?
2. **What makes it special?** — Key benefit, differentiator, or the one thing the customer should remember after seeing the ad.
3. **Do you have a product image or visual reference?** — If yes, ask them to share it. If they do, use it as a `referenceImage` when generating. This dramatically improves product accuracy.

Only move to Q2 once you have enough to visualize the product clearly.

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

## Step 2 — Competitive research (optional, always offer)

After collecting the brand and product information, ask the user whether they want you to do a quick competitive research pass before generating anything. Use `mcp_Question`:

"Before we start creating, want me to do a quick competitive analysis? I can look at what competitors are doing, what's working for them, and what your customers are already saying — then give you a strategy recommendation."
- Yes, research first — give me the full picture
- No, let's go straight to generating

### If they say yes — run all of this in parallel

**1. Competitor research**
Search for the top 3–5 direct competitors of the product. For each one, try to find:
- What platforms they advertise on (TikTok, Instagram, YouTube, etc.)
- The type of ads they run (UGC, product shots, cinematic, influencer)
- Their apparent messaging angle (price, quality, lifestyle, emotion, problem-solution)
- Any notable creative patterns (hooks, formats, recurring themes)

Use `mcp_Webfetch` to search and pull data. Good sources: their own website, social media pages, ad libraries (Meta Ad Library, TikTok Creative Center if accessible), review sites.

**2. User feedback on competitors**
For each competitor found, look for:
- What customers praise (what the ad promise delivers on)
- What customers complain about (unmet expectations, product or brand weaknesses)
- Recurring emotional themes in reviews

Good sources: App Store reviews, Google reviews, Reddit, Trustpilot, Amazon reviews.

**3. User feedback on the brand's own product**
Search for reviews and feedback on the user's product specifically:
- What do customers love most?
- What do they criticize?
- What words and phrases do real customers use to describe it? (These are gold for ad copy and hooks.)

### Present findings cleanly

Summarize everything in a single, structured message. No technical details, no raw URLs — just the insight. Format example:

---
**Competitive landscape**
- Competitor A: focuses on Instagram Reels with UGC reviews, messaging around affordability
- Competitor B: runs cinematic YouTube ads, high-end lifestyle positioning
- Competitor C: TikTok-first, hook-driven, lots of before/after formats

**What's working in this market**
[2–3 sentences on recurring winning patterns]

**What customers want but aren't getting**
[gaps or frustrations that appear repeatedly in reviews]

**Your product — what customers say**
[key praise and criticism from real reviews]

**Recommended ad strategy**
Based on this, here's what I'd recommend for [product]:
- Platform: [best fit based on where competitors are winning or where there's a gap]
- Format: [UGC / product shot / cinematic / etc.]
- Hook angle: [the emotional or functional angle most likely to convert]
- Differentiator to highlight: [what sets this product apart from the competition]
---

Then use `mcp_Question` to confirm direction:

"Does this strategy feel right, or do you want to adjust the direction before we start?"
- Looks great — let's create the ad with this strategy
- I'd like to tweak the angle (free text)
- Ignore the research, I have my own direction (free text)

---

## Step 3 — Generate the image first (always)

**Even if the user asked for a video, generate an image first.** This is the fastest way to validate the visual direction — aspect ratio, style, mood, product placement — before spending time on video generation (which takes longer and costs more).

Tell the user something like "Working on a first visual — give me a moment." while generation runs. Do not mention model names, generation time estimates, or any technical step.

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

### After generating — always download and display the result

Once the asset is ready:
1. Call `arcads_watch_asset` to get the signed URL
2. Download the file to a local temp path (e.g. `/tmp/arcads-preview.<ext>`) using `curl -sL "<url>" -o /tmp/arcads-preview.jpg`
3. Display it using the `mcp_Read` tool on that local file path — this renders it as an inline preview next to the chat

Do not mention asset IDs, S3 paths, polling status, or any technical detail. Just say something like "Here's the first look:" and show the file.

Then use `mcp_Question` to ask for approval:

"How does this look?"
- Looks great — let's animate it
- Looks good but I'd like a small change (free text → ask what to change, regenerate)
- Not quite right — let's try a different direction (free text → ask what's off, go back and revise)

Do not move to video generation until the user selects "Looks great" or equivalent approval.

---

## Step 4 — Animate to video (after image approval)

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

### After generating — always download and display the result

Once the video is ready:
1. Call `arcads_watch_asset` to get the signed URL
2. Download to a local temp path: `curl -sL "<url>" -o /tmp/arcads-preview.mp4`
3. Display it using the `mcp_Read` tool on that local file path — this renders the video as an inline preview next to the chat

Never show asset IDs, processing status, or tool output. Just say something like "Here's your video:" and show the file.

Then use `mcp_Question` to gather feedback:

"What do you think of the video?"
- Love it — ready to use
- Looks good, want to add captions / text
- I'd like a different motion / camera move (free text → regenerate with revised prompt)
- Something feels off (free text → diagnose and suggest fix)

---

## Step 5 — Enhancements (optional, offer proactively)

After video generation, offer finishing touches. Use `mcp_Question` to let the user pick what they want to add:

"Want to add any finishing touches?"
- Add animated captions (great for TikTok/Reels)
- Add a text hook headline
- Add a voiceover
- Upscale to 4K
- Translate for another market
- Nothing, it's ready!
- Other (free text)

Once they choose, execute the enhancement silently, then download and display the result the same way (curl to `/tmp/`, read the local file). Never expose tool names, asset IDs, or processing steps — just the output. Loop again if needed.

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
- **Always download and preview.** For every generated asset, download it locally with `curl` and display it via `mcp_Read` so it renders next to the chat. Never ask "how does it look?" before displaying it.
- **No technical leakage.** Never expose asset IDs, S3 paths, model names, tool names, polling status, or processing time in the chat. The user's experience should feel like a creative conversation, not an API log.
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

---

## Polling strategy — wait first, then poll every minute

Never poll immediately after starting a generation. Each tool has a known expected duration. Wait that long before the first `arcads_get_asset` call, then retry every 60 seconds until status is `GENERATED`.

Use `sleep` to wait between calls:
```bash
sleep <seconds>  # wait before first poll
# then every 60s until GENERATED
```

| Tool / scenario | First poll after |
|---|---|
| Image — nano-banana, seedream, gpt-image | 60s |
| Image — grok_image | 20s |
| Image — upscale | 30s |
| Video — arcads_generate_video (kling_30) | 3 min |
| Video — arcads_generate_video_kling_30_4k | 4 min |
| Video — arcads_generate_video_sora2 | 12 min |
| Video — arcads_generate_video_veo31 | 3 min |
| Video — arcads_generate_video_seedance_15 | 4 min |
| Video — arcads_generate_video_grok | 2 min |
| Talking head — arcads_audio_driven | 7 min |
| Talking head — arcads_omnihuman | 11 min |
| Captions / subtitles / text overlay | 2 min |
| Stitch / trim / layer / extend | 1 min |
| Upscale video | 3 min |
| Translate video | 6 min |
| TTS / STS / voice isolate | 15s |
| Animate image | 7 min |
