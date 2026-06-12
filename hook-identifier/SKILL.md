---
name: hook-identifier
description: >
  Analyze a video ad to identify its hook — the attention-grabbing opening sequence —
  using arcads_analyze_media. Returns two things: (1) the exact timestamp in seconds
  where the hook ends, and (2) a dense, reproduction-ready timeline covering only the
  hook portion of the video (visuals, dialogue, text overlays, camera movement, audio cues).
  Use this skill whenever the user wants to identify or locate the hook in a video ad,
  understand how long the hook lasts, get a frame-by-frame breakdown of an ad's opening,
  analyze ad structure for creative direction, or needs a description detailed enough to
  recreate the scene. Also trigger for phrases like "find the hook", "where does the hook
  end", "analyze this ad", "describe what happens in this video", "what's the hook here",
  "how long is the hook", "give me a timeline of this ad", "I want to recreate this ad",
  or "break down this video for me". Always use this skill before manually calling
  arcads_analyze_media when the goal is ad hook analysis or scene reproduction.
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

Call `arcads_analyze_media` with the video and this prompt (adapt the wording naturally, but keep all the requested elements):

```
You are an expert ad analyst. Watch this video carefully and give me a complete breakdown.

I need two things:

**1. Hook end timestamp**
Identify the exact moment (in seconds, one decimal place) when the "hook" ends — i.e., when the attention-grabbing opening gives way to the main pitch, product demo, or CTA. If the entire video is a hook, state that and give the total duration.

**2. Hook timeline**
Describe everything that happens from 0s up to and including the hook endpoint, entry by entry, with timestamps. Stop at the hook — do not describe anything after it. Each entry should be dense enough that someone who has never seen the video could recreate that exact moment.

Format each entry as:
  [X]s: [what happens]

For every entry, capture ALL of the following that apply:
- Visuals: scene, setting, background, lighting, color palette
- Camera: movement direction and speed, framing (close-up, wide shot, etc.)
- People: gender, approximate age, clothing, expression, what they do
- Dialogue: exact words spoken, in quotes
- Voice-over: exact words, noted as (voice-over)
- On-screen text: exact words, font style if notable, position on screen (top/center/bottom, left/right)
- Sound: music genre/energy, sound effects, ambient audio
- Products or props: what appears, how it's shown
- Transitions: cuts, fades, wipes

The goal: a director, actor, and set designer should be able to recreate the hook using only your timeline. Stop describing once the hook ends — what comes after is irrelevant.

**3. Hook summary**
In 1–2 sentences: what makes this hook effective (or why it isn't working)?
```

---

## Step 3 — Poll and extract

Poll with `arcads_get_asset` until `status === "GENERATED"`. Read `data.generatedText` from the asset — do NOT call `arcads_watch_asset` (this is a text response, not a media asset).

---

## Step 4 — Format and present

Parse the AI response and present the result in this structure:

```
**Hook ends at:** X.Xs

**Timeline (hook only):**
0s: [description]
...
X.Xs: [Hook ends — what begins next]

**Why the hook works:** [1–2 sentence analysis]
```

Keep the timeline entries as vivid prose. The hook endpoint should come first — it's the most actionable piece of information. The timeline covers only the hook — nothing after it. Example output:

```
Hook ends at: 9.8s

Timeline (hook only):
0s: Beach scene. Camera pans slowly left to right across calm ocean waves. Gentle ambient sea sounds only. Peaceful, inviting tone — feels more like a travel vlog than an ad.
5s: A man (early 30s, navy t-shirt, relaxed smile) walks into frame from the left. Looks directly at camera and says: "Hey you! Welcome to Arcads."
9s: Man exits frame. A woman's voice-over says: "Ask a demo!" Subtle whoosh sound effect.
9.8s: [Hook ends — product demonstration begins]

Why the hook works: The unexpected calm beach opening creates pattern interruption — viewers don't expect an ad to open like a travel vlog, so they keep watching to find out what's happening.
```

---

## Quality bar for timeline entries

Ask yourself: could a director, actor, and set designer recreate that exact second using only these words? If yes, it's good.

Checklist:
- Position of text overlays: "center screen", "bottom-left corner", "top third" — not just "on screen"
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
