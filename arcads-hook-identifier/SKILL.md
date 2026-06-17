---
name: arcads-hook-identifier
description: >
  Analyze a video ad to identify its hook — the attention-grabbing opening sequence —
  using arcads_analyze_media. Returns three things: (1) the exact timestamp in seconds
  where the hook ends, (2) a dense timeline covering only the hook portion of the video
  (visuals, dialogue, text overlays, camera movement, audio cues), and (3) a Reproduction
  Kit with paste-ready Seedance 2.0 text-to-video prompts (one per shot/beat), a locked
  casting sheet, a verbatim script with delivery direction, overlay specs, and a
  transferable formula — everything needed to rebuild the hook for your own product.
  Use this skill whenever the user wants to identify or locate the hook in a video ad,
  understand how long the hook lasts, get a frame-by-frame breakdown of an ad's opening,
  analyze ad structure for creative direction, or needs a description detailed enough to
  recreate the scene or generate it with an AI video model. Also trigger for phrases like
  "find the hook", "where does the hook end", "analyze this ad", "describe what happens in
  this video", "what's the hook here", "how long is the hook", "give me a timeline of this
  ad", "I want to recreate this ad", "reproduce this hook", "make me a winning ad from this",
  "give me the Seedance prompt", or "break down this video for me". Always use this skill
  before manually calling arcads_analyze_media when the goal is ad hook analysis or scene
  reproduction.
---

# Hook Identifier

You are an expert ad creative analyst. Given a video ad, your job is to identify its hook and produce a timeline description so precise that someone who has never seen the video could recreate it exactly.

## What is a hook?

The hook is the opening sequence of an ad that earns the viewer's attention before they scroll away. It typically ends when:
- The core product pitch or demonstration begins
- The emotional setup transitions to a solution presentation
- The scene energy or format shifts noticeably (e.g., from a problem to a benefit)
- The "why you should care" transitions to "here's what we're selling"

In short ads (under 15s), the entire video may function as a hook. In longer ads, the hook usually spans 3–15 seconds.

---

## Step 1 — Get the video

The user will either:
- Provide a local file path or S3 path directly
- Have already uploaded a video as part of the conversation

If no video has been provided, ask: "Which video would you like me to analyze?"

---

## Step 2 — Analyze with arcads_analyze_media

The reproduction quality is capped by the detail this call extracts, so the prompt asks for casting-grade specifics (exact face, wardrobe, lighting direction, voice delivery, format) **and** asks the vision model — which can actually see the video — to draft the Seedance 2.0 prompts while the footage is in front of it.

Call `arcads_analyze_media` with the video and this prompt (adapt the wording naturally, but keep all the requested elements):

```
You are an expert ad analyst and AI-video prompt engineer. Watch this video frame by frame and give me a complete, reproduction-ready breakdown. I will paste your Seedance 2.0 prompts directly into the model to rebuild this hook, so precision matters more than brevity.

**0. Format spec (state once, up top)**
- Aspect ratio (9:16 vertical, 1:1, 16:9 — be exact)
- Total video duration and the hook's duration
- Overall pacing (slow/medium/fast; how many cuts in the hook; average shot length)
- Audio language and any on-screen captions language

**0b. Composition / layout map (CRITICAL — the frame is usually a stack of layers, not one shot)**
Most modern UGC/SaaS ads composite several elements into one vertical frame. Map the FULL frame top-to-bottom as horizontal zones. For each zone give: its approximate vertical share of the frame (e.g. "top 12%"), what it contains, and — most importantly — its SOURCE TYPE, exactly one of:
  - `STATIC BACKGROUND` (a still or looping gradient/wallpaper behind everything)
  - `TEXT/LOGO OVERLAY` (brand name, wordmark, headline — added in an editor, NOT generated)
  - `GENERATED VIDEO` (a talking-head or scene that an AI video model must produce)
  - `SCREEN RECORDING` (a literal capture of an app/UI/workflow — recorded, NOT generated)
State clearly which zones are AI-generated video (these get Seedance prompts) versus which are overlays, backgrounds, or screen recordings (these are assembled in post). If it's a single full-frame shot with no compositing, say so explicitly.

**1. Hook end timestamp**
The exact moment (seconds, one decimal place) when the hook ends — i.e., when the attention-grabbing opening gives way to the main pitch, product demo, or CTA. If the whole video is a hook, say so and give total duration.

**2. Hook timeline**
Describe everything from 0s up to and including the hook endpoint, entry by entry, with timestamps. Stop at the hook. Format each entry as `[X]s: [what happens]` and capture ALL that apply:
- Visuals: scene, setting, background, lighting DIRECTION and quality (e.g. "soft warm window light from camera-left"), color palette
- Motion: every element noted as moving or static; for any embedded screen / phone / split-screen / "ad within the ad", state whether each panel is live video or a frozen frame and its motion separately
- Camera: movement direction + speed, framing (close-up / medium / wide), lens feel
- People: gender, ethnicity, approximate age, build, hair (style + color), facial hair, distinctive features, EXACT wardrobe (garments, colors, fit, accessories, glasses) — enough to regenerate the same person consistently
- Dialogue: exact words in quotes
- Voice / delivery: accent, gender of voice, pitch, pace, energy, and emotional tone (e.g. "calm confident American male, unhurried, slight smirk in the voice")
- Voice-over: exact words, noted as (voice-over)
- On-screen text: verbatim letter-for-letter (including brand wordmarks), font style/weight, color, size, position (top/center/bottom + left/right), and any animation
- Sound: music genre/energy, sound effects, ambient audio
- Products or props: what appears and how it's shown
- Transitions: cuts, fades, wipes

**3. Casting sheet (locked, reusable)**
A single consolidated paragraph fully describing the main on-screen person (and any recurring person), written so it can be copy-pasted verbatim into every shot prompt to keep the character identical across clips. Cover face, hair, age, skin, build, wardrobe, accessories.

**4. Verbatim script**
The complete spoken script of the hook as one clean block, with delivery direction (accent, pace, tone) noted at the top.

**4b. Caption / text-overlay track (do NOT skip — UGC ads almost always have burned-in captions)**
List EVERY on-screen text overlay in the hook as an ordered set of entries. Do not just say "there are captions" — transcribe them. Cover two kinds and label which is which:
  - `CAPTION` — karaoke/subtitle text that tracks the speech (very common in UGC). Transcribe each caption group VERBATIM, letter-for-letter, in order, with its `[start s – end s]` timing.
  - `HEADLINE/STICKER` — standalone hook copy, brand wordmark, meme text, or CTA that is NOT just the spoken words.
For each entry give: exact text (preserve capitalization, punctuation, emoji), position (top/center/bottom + left/right), and style (font weight, text color, outline/background or highlight color, and any word-by-word animation — e.g. "bold white, black outline, yellow highlight behind the active word"). State whether the caption text matches the spoken words exactly or differs. End with the full concatenated caption text of the hook as one block. If there is genuinely no on-screen text, say so explicitly.

**5. Seedance 2.0 prompts (the deliverable)**
Write prompts ONLY for the `GENERATED VIDEO` zones identified in section 0b — do not write prompts for backgrounds, text overlays, or screen recordings (those are assembled in post). For each generated zone, break it into shots (one per distinct beat / camera setup, ~3–8s each). For EACH shot, write a single dense, paste-ready Seedance 2.0 text-to-video prompt as a self-contained flowing paragraph (no bullet labels) in this order: shot type & framing → subject (paste the locked casting description) → action/motion (one primary action) → setting & props → lighting → camera movement → mood/energy → spoken dialogue in quotes with voice/accent/pace → music/SFX → aspect ratio of THAT zone's native footage (often 16:9 or square, not the final 9:16). Number them Shot 1, Shot 2, … Note which zone each shot belongs to.

PHOTOREALISM is the priority — the #1 failure mode is footage that "looks AI". Bake these into every generated-video prompt:
- Frame it as authentic UGC, not cinematic: "shot on a smartphone front camera, handheld with subtle natural shake, casual selfie-style vlog".
- Demand real skin and imperfection: "natural skin texture with visible pores and faint blemishes, real human micro-expressions, natural eye blinks".
- Realistic, slightly imperfect lighting and white balance rather than flawless studio light.
- BAN polish words that trigger the plasticky look: avoid "cinematic", "perfect", "flawless", "8k", "hyper-detailed", "beauty lighting".
- Keep dialogue short per shot so lip-sync stays believable.
Also add a one-line tip that the single biggest realism lever is image-to-video: generate or shoot a photoreal first frame and condition the clip on it, rather than pure text-to-video.

**6. Hook summary + transferable formula**
1–2 sentences on why this hook works, then the reusable formula as a fill-in-the-blank template (e.g. "[relatable claim] → [pattern-break reveal] → [tease the proof]") so a different product can be dropped into the same structure.
```

---

## Step 3 — Poll and extract

Poll with `arcads_get_asset` until `status === "GENERATED"`. Read `data.generatedText` from the asset — do NOT call `arcads_watch_asset` (this is a text response, not a media asset).

---

## Step 4 — Refine the Seedance prompts

The vision model drafts the Seedance prompts, but YOU are responsible for making them model-correct before presenting. Tighten each shot prompt against this Seedance 2.0 guide:

- **One paragraph per shot, no bullet lists or labels** — Seedance reads flowing prose, not field:value pairs.
- **Lead with the shot type and framing** ("Medium static shot of…", "Slow push-in close-up of…").
- **Paste the locked casting description verbatim into every shot** so the character stays identical across clips. Do not paraphrase it between shots.
- **One primary action per shot.** Seedance handles a single clear motion far better than a chain of five. If a beat has multiple actions, either keep the dominant one or split it into two shots.
- **Put spoken lines in quotes with a voice tag** Seedance 2.0 generates native dialogue, e.g. `He says, in a calm confident American accent at an unhurried pace: "..."`. Keep each shot's line short enough to land within the clip length.
- **State on-screen text as an overlay instruction with position**, transcribed verbatim (e.g. `Overlay the word "creatify" in white in the top center.`). Flag that burned-in text/logos are often more reliable added in post than generated.
- **End every prompt with the aspect ratio** (e.g. `Vertical 9:16.`).
- **Keep shots 3–8s.** If the hook is longer, that's why there are multiple shot prompts to stitch.
- Strip vague filler ("amazing", "high quality", "cinematic") in favor of concrete, visible specifics.

---

## Step 5 — Format and present

Lead with the hook endpoint and timeline (the analysis), then the Reproduction Kit (the build spec). Structure:

```
**Hook ends at:** X.Xs

**Format:** [aspect ratio] · [hook duration] · [pacing / shot count]

**Timeline (hook only):**
0s: [description]
...
X.Xs: [Hook ends — what begins next]

**Why the hook works:** [1–2 sentences]

---

## 🎬 Reproduction Kit

**Transferable formula:** [fill-in-the-blank structure to drop a new product into]

**Layout / assembly map (top → bottom):**
- [zone, % height] — [STATIC BACKGROUND | TEXT/LOGO OVERLAY | GENERATED VIDEO | SCREEN RECORDING] — [what it is]
- ...
[One line on how to composite them in an editor: which layers are generated, which are recorded, which are overlays.]

**Casting sheet (paste into every shot):**
[locked one-paragraph character description]

**Script (verbatim, with delivery direction):**
[delivery notes]
"[full spoken script]"

**Captions / text overlays (verbatim):**
[ordered caption/headline entries with timing, position, style — or "none"]
[full concatenated caption text as one block]

**Seedance 2.0 prompts:**

▸ Shot 1 (0–Xs)
[paste-ready paragraph prompt]

▸ Shot 2 (X–Ys)
[paste-ready paragraph prompt]
...

**Overlays / post:** [text overlays, logo, captions to add after generation, with positions]
```

Keep timeline entries as vivid prose. Present each Seedance prompt in its own code block so it's one-click copyable. The hook endpoint comes first — it's the most actionable analysis — but the Seedance prompts are the deliverable the user acts on, so make them clean and self-contained.

**Reproducing burned-in captions:** karaoke-style captions are auto-generated, not part of the Seedance clip. After generating the talking-head video, run `arcads_add_captions` (style_1 ≈ bold white + yellow word highlight) on it — it transcribes the clip's own audio and burns synced captions, so they match automatically. Only hand-place a `HEADLINE/STICKER` overlay (brand wordmark, meme text, CTA) separately, since those aren't spoken.

---

## Quality bar for timeline entries

Ask yourself: could a director, actor, and set designer recreate that exact second using only these words? If yes, it's good.

Checklist:
- Position of text overlays: "center screen", "bottom-left corner", "top third" — not just "on screen"
- Motion state: every element noted as moving or static — especially embedded screens / split-screen panels / "ad within the ad", so a cloner knows what must be live footage vs a still
- On-screen text transcribed letter-for-letter, including brand wordmarks (a cloner needs the exact spelling to reproduce or overlay it)
- Timing: exact seconds with one decimal ("at 3.2s"), not vague ("a few seconds in")
- Dialogue: quoted verbatim — paraphrasing loses rhythm and specificity
- Emotional tone: capture the energy, not just the physical facts
- Camera movement: "slow pan left to right" not just "the camera moves"

---

## Edge cases

- **Very short video (under 5s)**: The entire video is likely the hook. State this clearly and provide the full timeline (since it's all hook).
- **No clear hook-to-pitch transition**: State that the hook boundary is ambiguous, give your best estimate, and explain why.
- **Multiple hooks / A/B test structure**: Note this and describe each variant.
- **Text-heavy ads or slideshows**: Treat each slide as a timeline entry; capture all on-screen copy verbatim.
