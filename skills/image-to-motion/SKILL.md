---
name: image-to-motion
description: Turn any still image into a professional motion graphic through the Arcads MCP connector with Seedance 2.5. Covers how to read a reference image, motion vocabulary for any image type — UI, marketing hero, flat-lay, key art, collage, product, character — the prompt clauses that control camera, timing, frozen regions and text fidelity, and the connector's file-upload mechanics. Use whenever the user supplies an image and wants it animated, moving, or turned into video — including "animate this", "turn this into a motion graphic", "make this move", "この画像動かして", "モーショングラフィックにして", "I want the cards to pop in", "I want the bars to slide up", or when they describe motion beats for a static image. Also use when asked to write a Seedance prompt for an existing image. Do NOT use for text-to-video with no source image, restyling existing footage (use omniflash-restyle), or cloning a reference video (use viral-clone).
---

# Image → Motion Graphic

Any still can become a professional motion graphic. The work is direction, not damage control: decide what moves, in what order, and say it precisely enough that there is nothing left to interpret.

Vague prompts produce vague motion. Specific prompts produce the shot you pictured. That is the whole discipline.

---

## Step 1: Read the image

Look at it properly before writing anything. Record:

- **Dimensions and ratio.** If the requested output ratio differs from the source, the layout gets rebuilt rather than cropped — say so, and describe the new arrangement in the prompt rather than hoping for it.
- **Photographic or illustrated.** State this explicitly in the prompt. Omitting it is the most common way a painted reference comes back photoreal, or vice versa.
- **Light direction and quality.** Hard raking light and soft ambient light imply completely different motion. Long shadows moving is a beat; flat light has nothing to reveal.
- **Layer depth.** What sits in front of what. This is where parallax and staggered entrances come from.
- **Every legible string, transcribed verbatim.** You will quote these back in the prompt.
- **The accent structure.** Most strong reference images run on one saturated accent against a restrained field. Whatever draws the eye is what should move last, or move most.

---

## Step 2: Choose the motion

Match the vocabulary to what the image *is*. This is genre craft — a flat-lay wants different motion from a character render, and reaching for the wrong grammar is what makes AI motion look generic.

**UI, app screens, toolbars, widgets, dashboards**
Panels slide or scale into place and settle. Cursors travel along an arc and click. Press states compress and spring back; hover states lift and deepen their shadow. Tooltips, menus and toasts appear on the interaction that triggers them. Toggles flip, progress fills, counters and badges land. Decide whether screen contents scroll or hold — either is available, but choose deliberately and say which.

**Marketing hero — headline, device, floating cards**
Headline rises and fades in as a block. Device and hand slide in from the frame edge with a slight overshoot and settle. Floating cards pop from slightly under full scale with a bouncy overshoot, staggered rather than together. Progress arcs draw their stroke. Then a gentle out-of-phase idle float so the frame never feels frozen. If figures should count up, say so explicitly; if they should hold, say that instead.

**Flat-lay, evidence board, desk scene**
Items drop in and settle with their shadows catching up a beat late. String, thread and connecting lines draw along their path. Papers can lift and flutter at the corner. A slow light sweep across the surface reads beautifully and costs nothing. Magnifiers and lenses can glide.

**Painted key art, illustrated scene, game art**
The most permissive class. Parallax between depth layers, drifting dust and light shafts, water and cloth movement, slow reveals, ambient particle motion. A slow push-in or drift works here when you want cinematic rather than graphic.

**Collage, paper-cut, halftone**
Assemble-from-empty: elements fly, snap or hinge into place in sequence with slight rotation overshoot. Suits stepped, stop-motion timing rather than smooth easing. Textures can breathe.

**Product still, object, packaging**
Slow turntable rotation, light sweep across the surface, lid lift, pour, unfold, exploded-view separation, hero reveal from shadow.

**Character, mascot, avatar**
Idle breathing, blink, head turn, expression shift, hair and cloth secondary motion, a gesture into a hold.

Across all of them: **stagger paired elements.** Two things entering simultaneously read as one flat sheet; a fifth of a second apart reads as two independent objects with their own weight. That single choice does more for perceived production value than any other.

---

## Step 3: Write the prompt

Structure the shot as timed beats. Include every clause below — each one removes a decision the model would otherwise make for you.

```
[Shot type] of [subject].

CAMERA: [either "The camera is locked off and never moves: no pan, no tilt, no
zoom, no push-in, no orbit, no drift." — or the specific move you want, with its
speed and direction.] Lighting is [constant / describe the change].

The reference image is the exact composed state — every colour, shadow, layout
position and glyph matches it precisely.

TEXT: all text stays perfectly intact and pixel-identical to the reference image
at every frame — [quote every string individually]. Same font, same weight, same
size, same position, correctly spelled. Text is never redrawn or re-lettered; it
travels rigidly with the object it sits on.

[If any region should not animate:]
[REGION] holds completely still: no scrolling, no swiping, no changing content.

TIMED BEATS:
0.0s — [the opening state, including anything that is ABSENT]
[t–t]s — [one object, one motion, with easing]
...
[final]s — Everything holds. [Any permitted idle drift.] No fade out.

[Negatives:] No film grain, no vignette, no lens flare, no added elements,
no watermark, no extra text.
```

Five clauses that carry most of the weight:

**Say the text should be perfectly intact, and quote every string.** This is the single highest-value line in the prompt. Asking for it explicitly works far better than leaving it implied, and naming each string individually works better than a general instruction.

**State the opening frame including what is absent.** If a tooltip, badge or card is visible in the reference and you want it to appear partway through, the prompt must say it is not there at 0.0s. Otherwise it is present from frame one and the reveal never happens. This is logic, not model behaviour — it applies no matter how capable the model is.

**Declare anything that holds still.** A region that should not move needs saying so. Silence is not an instruction.

**End with an explicit hold.** Without a final beat pinning the last state, models tend to invent a drift, a fade or a camera move to fill the remaining time.

**One object per beat, with easing named.** "The cards pop in" is three possible shots. "Each card scales up from slightly under full size with a soft bouncy overshoot, 0.2s apart" is one.

---

## Step 4: Run it

`arcads_generate_video_seedance_25` is the default for image-to-motion.

- `duration` — 4 to 15s. Match it to the beat list; leave a beat of hold at the end.
- `aspectRatio`, `resolution` — `"720p"` or higher.
- `audioEnabled` — `false` unless sound is wanted.
- `nbGenerations` — 4 gives useful choice on a single call.

Use `arcads_generate_video_omni_flash` in edit mode instead when the job is a restyle or a timed multi-scene switch rather than an entrance animation.

If the still needs building or rebuilding first, generate it before animating. A crisp, correctly-composed, correctly-lettered source frame is the foundation of the whole shot — the video stage carries forward what it is handed. Both `arcads_generate_image_gpt` (`gpt-image-2`) and `arcads_generate_image_nano_banana` (`nano-banana-2`) are available; when it matters, run the same prompt through both and compare rather than assuming.

### Arcads MCP file mechanics

Generation tools cannot read local filesystem paths. The flow:

```
arcads_get_upload_url(mimeType)  → { presignedUrl, filePath }
HTTP PUT raw bytes to presignedUrl with matching Content-Type  → 200
pass filePath in referenceImages / startFrame
```

Three observed behaviours that will otherwise cost failed calls:

- **Temp objects expire quickly** — observed dead in a few minutes, well short of the stated presign window. Upload and generate in one uninterrupted burst.
- **Do not call `arcads_register_image` to make references persistent.** Observed to consume the temp object and invalidate the original path, while the returned asset ID is rejected while pending.
- **Reference images cap at 9** on Seedance 2.5 through this connector. Higher figures quoted in tutorials belong to other platforms.

---

## Step 5: Review and iterate

Generate several, pick, then refine the prompt rather than rerunning it unchanged. Look at:

- **Did the beats fire in order,** or collapse into one simultaneous move? If collapsed, spread the timings further apart and shorten each one.
- **Is the camera doing what you asked?** Unrequested drift usually means the camera clause was too short — expand it into the explicit no-pan-no-zoom-no-push list.
- **Read every quoted string at full size.** Check the small labels, not just the headline.
- **Did anything hold still that should have moved,** or move that should have held? Both are prompt clarity problems, not model problems.
- **Shadow and light consistency**, especially in flat-lay and product work where one light direction is the only depth cue.

When something is off, add specificity rather than emphasis. Naming the object, the distance, the direction and the easing beats restating the same instruction more forcefully. If a beat keeps coming out wrong, describe it as a rigid transform of a named object — that is almost always clearer than describing the effect you want.
