---
name: static-to-motion
description: 'Turn a finished static ad into short video for paid social on the Arcads MCP connector using Seedance 2.0. Reads the static, classifies its layout archetype, then offers two modes: SIMPLE, where the composition is preserved and only what would really move moves, elements revealed one beat at a time; and CREATIVE, where the static seeds one stated idea, with morph, scale violation, match cuts and camera moves allowed. Trigger when a user uploads a static ad, Meta static, product still, flatlay, shade chart, swatch layout or offer card and asks to animate it, make it move, turn it into a video or Reel, animate my statics, make this a video, or asks for a build-up or assemble-from-empty reveal. Also trigger when they want both a safe and a creative version to A/B test. Do NOT use for cloning a reference video with a swapped product (viral-clone), restyling raw footage (omniflash-restyle), or building ads from a product URL with no static (arcads-meta-ad-engine).'
---

# Static to Motion

Input: one finished static ad. Output: short video for paid social that either preserves that
static exactly or uses it as a seed for one clear idea.

The input is **already validated**: approved, tested, legally cleared. That is the whole reason
this pipeline exists and it sets the constraint that everything else follows from. Treat the
static as truth, not as a suggestion.

---

## Hard tool facts

Verified against the live schemas. Do not assume otherwise.

**`arcads_generate_video_seedance_20` has no `startFrame` and no `endFrame`.**
Only `referenceImages` (up to 3), `referenceVideos`, `referenceAudios`, `audioEnabled`,
`duration` 4-15, `aspectRatio` **16:9 or 9:16 only**, `resolution` up to 1080p,
`nbGenerations` 1-10. There is no way to hard-lock the first or last frame. Frame fidelity is
enforced downstream in QA, not upstream by a parameter.

**Escape hatch:** `arcads_generate_video_seedance_15` has `endFrame` and does **not** require
`startFrame`. It is the only model on the connector that accepts a target last frame alone.
Costs: 4-12s only, 1 reference image only, no `audioEnabled` param. Use only when a client
demands the exact approved end frame.

### Asset upload, exact sequence

```
1. arcads_get_upload_url(mimeType)
2. curl -X PUT -H "Content-Type: <mime>" --data-binary @file "<presignedUrl>"
   → must return HTTP 200. Retry up to 3 times.
3. arcads_register_image(imagePath: "external-api-temp-uploads/<uuid>.png")
4. reference it everywhere as "videoassets/<assetId>.png"
```

- Local filesystem paths **fail**. The MCP runs remotely.
- `external-api-temp-uploads/...` works for image generation but is **rejected by
  `seedance_20`** with `INVALID_REFERENCE_IMAGES`. Always register.
- A temp upload path **dies after one consumption**. PUT once per static, register immediately,
  then reuse the asset id for every downstream call.
- The S3 host intermittently returns `503 / DNS resolution failure`. Retry 3x; if it still
  fails, do Phase 0 locally and continue.

### Variants

Use `nbGenerations`. Never make the same call several times to get several outputs.

---

## PHASE 0 — Aspect fit

Seedance outputs 16:9 or 9:16 only. Real statics are 1:1, 4:5, 2:3. This always needs handling
and it is the step people skip.

**Never crop the sides.** Edge content is where shade names, prices, CTAs and composition
anchors live. Extend instead, and **put the extension at the bottom** where possible: it is the
caption and CTA safe zone on Meta and TikTok.

Decide by measuring, not by looking:

```
edge std = std of the outer 10px band, all four edges

1. edge std < 3                              → LOCAL PAD with the sampled background colour
                                                zero generation, original pixels intact
2. extension ≤ 15% AND the side being
   extended is low detail (out-of-focus
   floor, plain wall, sky, seamless sweep)    → LOCAL STRETCH
                                                stretch the last ~56 rows, blur ~1.2,
                                                match grain (sigma ≈ band std × 0.06),
                                                anchor row 0 of the new band to the original
                                                last row and decay the offset over ~50 rows
3. anything else                              → nano-banana-2 OUTPAINT
                                                prompt: preserve every existing element
                                                identically, add only above and below
```

**Never touch the original pixels.** Do not feather across the join into the source image.
Solve the seam entirely inside the new band.

Then run numeric QA and report the numbers:

```
original pixels preserved   must be True
seam abs diff               target < 3
band std new vs source      must be within ~1
final ratio                 target 0.5625 or 1.7778
```

If the letterboxed grey bars or a watermark are present, strip the bars before anything else.
A watermark means the asset belongs to someone else: usable as a style reference, not as a
shippable base. Say so once and move on.

---

## PHASE 1 — Read the static

**If the static is in context, read it yourself.** Only call `arcads_analyze_media` when the
static exists solely as an S3 path. Spending a minute and a generation to describe an image
already visible is waste.

Produce this, and show it to the operator:

```
archetype:      see table below
beats:          the ordered list of information units, each with id / element / position
motion_sources: things that would move in reality (light, air, liquid, fabric, breath, focus)
static_locks:   things that must never move, named explicitly
typography:     every text string, its position, and whether it is brand-critical
palette:        dominant colours plus accents
light:          direction, colour temperature, hardness
ratio:          source ratio and the Phase 0 decision taken
```

`static_locks` is the highest-leverage field. Seedance drifts by default. Naming the things
that must hold still, per beat, buys more fidelity than any other instruction.

### Archetype table

| Archetype | Beats | SIMPLE grammar |
|---|---|---|
| Multi-product lineup / flatlay | element count | each enters and settles, one cut per placement |
| Single hero product | 1 → borrow 3 | subject locked; animate light, shadow rotation, rack focus to label, dust or steam |
| Product in hand / model present | 2-3 | living photograph: breath, blink, grip adjust; cut between 2-3 scales of the same pose |
| Before / After split | 1 | animate the divider only, never the content |
| Copy-led offer card | text block count | background plate lives, type is stamped in on a hard cut, never animated |
| Ingredient / benefit callouts | callout count | product locked, callouts appear in order, one cut each |
| Shade chart / swatch list | row count | rows enter top to bottom, name appears with its row |
| UGC screenshot / testimonial | line count | line-by-line reveal, scroll, camera locked |
| Lifestyle scene, product embedded | 1-2 | product unmoving; curtain, steam, liquid, passing shadow; one push-in maximum |

---

## PHASE 2 — Mode fork

Ask with `ask_user_input_v0`. This is the only decision the operator must make, and it is where
their taste enters.

```
SIMPLE    fidelity is the goal. Ships against the approved creative.
CREATIVE  fidelity is the floor. One stated idea, executed hard.
BOTH      render both, operator picks.
```

If SIMPLE and the archetype has ≥ 2 elements, also ask: **unmanned placement or hand placement.**

---

## SIMPLE

> **Only animate what would move in reality. Anything that should be still stays still.
> The number of cuts equals the number of times new information appears.**

Light, air, liquid, breath, fabric and focus move. A solid object, once placed, never moves
again. Every beat declares what holds still.

### Tempo splits by type

```
placement type (objects being set down)   beat 1.8 - 2.0s   physical weight needs time
list type (rows, shades, callouts, copy)  beat 0.8 - 1.0s   information wants to be clipped
```

Same "reveal N things in order", double the tempo difference. Misjudging this is the difference
between premium and sluggish.

### Duration

```
unmanned:  T = 1.5 + N × beat + 1.0
hand mode: T = 1.2 + N × beat + 1.4     beats = N + 2
```

If T exceeds 15s, group elements two per beat or drop to unmanned. If N = 1, hand mode is
forbidden: it produces a 3 second ad. Borrow environment beats instead.

### The close

**Never make the hold its own shot.** The final element's shot simply continues as the completed
composition. No cut means no perceived freeze. 1.0 to 1.4s is enough to read it, and residual
motion is mandatory: drifting shadows, a swaying stem, the last settle. A frozen final frame
reads amateur instantly.

### Hand mode

- Lock the hand spec once in Phase 1 and paste the **identical string** into every beat:
  skin tone, nail length and finish, rings, sleeve or cuff. Unspecified means a different hand
  every cut.
- **The hand is never shown withdrawing.** It places, releases, and the shot cuts while the hand
  is still in frame. The cut does the exit. This removes the hardest motion entirely.
- **Every element gets placed by hand, including the last one.** Then one final handless beat.
  Skipping the last placement so the object simply appears breaks the rule the ad established.
- Final beat contains no hand, because the approved static contains no person.
- Add the hand negative block: `one hand only, never two, five fingers, natural anatomy,
  identical hand in every shot, no extra hands or arms, no faces`.

### SIMPLE constraints block

```
no morphing, no flickering, no added elements, no added text or logos,
no warped typography, no camera movement, no zoom, no speed ramps,
no reframing between shots, no scale change, no new subjects,
no freeze on the final frame
```

---

## CREATIVE

### The idea slot

CREATIVE fails when it is given a style instead of an idea. "Macro texture montage",
"light sweeps across", "the liquid keeps pouring" are styles. They produce competent, anonymous
wallpaper, which is worse than rough and memorable.

**Test: state the concept in one sentence with no reference to camera or lighting.** If it
cannot be said that way, it is not a concept. Reject it and generate another.

Passing examples:
- the fruit becomes the tint
- the product is a monument
- the drip becomes a lip
- the routine builds itself in the order you use it

### Concept axes

Pull from a real axis, not from the texture drawer.

```
metamorphosis      the ingredient becomes the product. The claim made literal.
scale violation    the product as architecture, or the world as miniature.
impossible physics gravity reverses, liquid climbs, the assembly runs backwards.
match cut          a shape in the static becomes the benefit: a drip becomes a glossy lip.
category transplant shoot it as food film, nature documentary, jewellery, architecture.
kinetic            the arrangement collapses and reassembles.
```

### CREATIVE constraints block

Only three locks. Everything else is permitted, and **morph and speed ramps are tools here,
not failure modes.** A twelve-item negative block is why the creative branch comes out as
wallpaper.

```
1. brand text spelled correctly in every frame, name the exact strings
2. packaging geometry intact, never deformed or relabelled
3. palette and lighting inherited from the reference
```

### The type protection trick

`Products appear only in the first shot.` The product is on screen only while pixel-anchored to
the reference; every later beat is abstract or a different subject with no packaging type to
mangle. This solves the packaging-text problem structurally, with no compositing, no layer
separation and no extra tools. Use it on any text-heavy static.

---

## PHASE 3 — Prompt format

Fixed order. **Word budget: under 100 for a single continuous shot, under 200 for multi-cut.**
Longer prompts dilute. Front-load: the first 20-30 words carry the most weight.

```
1. FRAME LOCK      one sentence. SIMPLE build-up: "start on the reference scene with
                   <the elements> absent, everything else identical". CREATIVE: "start exactly
                   on the reference image, composition, lighting and colour preserved."
                   Do not re-describe the image beyond this line.
2. STYLE           one dense sentence: register, light, palette inherited, depth of field, grain.
3. EDITING LOGIC   duration, number of hard cuts or "one continuous shot", zero transitions,
                   zero morphing (SIMPLE only), palette lock, and for SIMPLE:
                   "every shot uses the identical locked-off framing".
4. TIMELINE        one line per beat:
                   0.0s-1.5s | Visual: <one visible moment>. Camera: <one explicit move with
                   speed and endpoint, or locked off>. Audio: <event or ambience>.
                   - durations sum exactly to total
                   - one action and one camera move per beat, maximum
                   - every beat gets an explicit Camera command, no exceptions
                   - prefix with CUT: when the beat opens a new shot
                   - declare what holds still inside each beat
5. CONSTRAINTS     the mode-appropriate block. Never share one block across both modes.
6. SOUND           one sentence. Silence must be explicit: "No audio. No music. Silent."
7. FINAL TEXT      list every visible string in exact quotes, or
                   "No on-screen text beyond what exists in the reference."
```

Camera vocabulary: locked off, slow push-in, slow pull-back, lateral dolly left/right, slow
tilt, crane, orbit. One move per beat, always with speed and endpoint. Use **cuts, not camera
travel**, to change subject.

Never push, zoom or rotate into packaging type. If the camera must move near a label, state that
labels stay sharp and unwarped.

---

## PHASE 4 — Render

```
arcads_generate_video_seedance_20
  referenceImages: ["videoassets/<assetId>.png"]
  aspectRatio:     9:16 (or 16:9)
  duration:        from the Phase 2 formula
  resolution:      1080p
  audioEnabled:    true, unless the risk profile below applies
  nbGenerations:   2 for hand mode or any CREATIVE morph, else 1
```

~7 minutes per call.

---

## PHASE 5 — QA gate

Because no parameter locks the frames, this gate is what replaces one.

```
1. last frame vs the static: composition drift?
2. brand text: every string spelled correctly? name them and check each one
3. packaging geometry: deformed?
4. SIMPLE only: did anything move that was in static_locks?
5. hand mode: same hand across cuts? final beat handless?
6. final frame frozen? (should have residual motion)

fail → reroll with nbGenerations 2, up to 3 attempts
still failing → report which static is incompatible with this mode. Do not ship.
```

---

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `INVALID_REFERENCE_IMAGES` | passed a temp upload path or local path to seedance | register the asset, use `videoassets/<id>.png` |
| `File not found` on a local path | MCP runs remotely | upload and register first |
| register fails on a path that just worked | temp upload consumed | re-upload, then register immediately |
| `Output audio has sensitive content` | fal-side audio filter, fires **after** ~7 min. `refunded: true`, so free but slow | remove bathroom / shower / bath / bedroom from the Sound line; add `strictly no voices, no breathing, no whispering, no sighs, no humming`; on a second failure set `audioEnabled: false` and add sound in post |
| S3 PUT `503 / DNS resolution failure` | egress transient | retry 3x, then do Phase 0 locally |
| output is competent but anonymous | CREATIVE given a style, not an idea | apply the one-sentence test, regenerate the concept |
| final frame reads as a freeze | hold made into its own shot | fold the hold into the last beat's tail, add residual motion |
| shade names / long words misspelled | list-type static with generated type | apply `products appear only in the first shot`, or accept post-composited type |

**High audio risk profile:** human skin in frame plus liquid plus a wet-room word. Set
`audioEnabled: false` from the start rather than discovering it 7 minutes later.

---

## Never

- Crop the sides of a static to hit an aspect ratio.
- Overwrite original pixels during Phase 0.
- Use `arcads_add_text_overlay` to restore brand type. It regenerates the letterforms and will
  not match the approved artwork.
- Share one constraints block between SIMPLE and CREATIVE.
- Call the same prompt repeatedly instead of using `nbGenerations`.
- Ship a video whose last frame does not match the approved static, in SIMPLE mode.
