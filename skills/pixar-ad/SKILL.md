---
name: pixar-ad
description: 'Turn a product (URL and/or product image) into a finished 15-second Pixar-style 3D animated ad in ONE Seedance 2.0 call, with the voice-over and in-scene dialogue generated natively. Produces a researched product read, a character sheet, a composition key frame, a professional dual-track script (narrator plus character dialogue), and the exact generation call. Trigger whenever the user wants a Pixar-style, Disney-style, 3D animated, or animated-film-look ad: "make a Pixar style ad for this", "3D animated ad", "make it look like an animated movie", "cute 3D character ad", or pastes a product URL or photo asking for an emotional animated spot. Also trigger on "15 second animated ad" or a request for an animated ad script with scene-by-scene prompts. Do NOT use for the Vox paper-collage look (use animated-ad), brick or stop-motion looks, cloning a reference video (viral-clone), or restyling existing footage (omniflash-restyle).'
---

# Arcads Pixar Ad

One product in. One 15-second stylized 3D animated ad out, picture and sound,
from a single generation call.

This is a STORY skill, not a render skill. The model already renders this look
well by default — smooth animation is its natural grain, so you are not fighting
material physics. What earns the result is the emotional architecture, the
performance constraint on the product, and the script. Spend your effort there.

## Hard constraints

- **15 seconds. One `arcads_generate_video_seedance_20` call.** Never chunk,
  never stitch, never add a post-production pass.
- **`audioEnabled: true`.** Seedance generates the narrator and the in-scene
  dialogue itself. Never pre-synthesise audio, never pass `referenceAudios`,
  never plan to layer a track afterwards.
- **30 to 33 spoken words total**, across narrator and dialogue combined.
- **9:16, 1080p** unless the operator says otherwise.

## Inputs

Required: a **product** (URL, listing text, or description). Strongly preferred:
a **product image**.

Everything else you infer. Ask at most one question, and only if the product is
genuinely missing.

## Gate 0 — is this product right for this style?

Run this before anything else. Stylized 3D animation is good at exactly one
thing, and it is not explaining features.

**Its four capabilities:**

1. **Interiority.** Large expressive eyes and full facial animation can play a
   private internal state: shame, worry, relief, longing. No other register in
   the library can do this at all.
2. **Anthropomorphised objects.** An appliance can hold attention and intent
   without a face. See doctrine D below.
3. **Appealing realism.** Homes look warm and aspirational without looking
   staged. It reads premium rather than novelty, which makes it durable rather
   than a passing gimmick.
4. **Caricatured physics.** Squash, stretch, anticipation. Emotional
   exaggeration in motion.

**It is bad at:** technical explanation, spec comparison, system diagrams,
cutaway logic, and any pitch whose core is a number.

**The filter — all four must pass:**

- Is the pain **emotional or relational** rather than technical? A styled
  character can act "I can't read to my grandson." It cannot act "the field of
  view is 110 degrees."
- Is the pain **visible on a face**? If the benefit only shows up in a spec
  sheet, pick a different register.
- Is there a **relationship** in the story? Two characters beat one. The strongest
  ads here are about someone else, not about the buyer alone.
- Is it **impulse-priced**? Warm animation converts at 15 dollars. At 900 it
  creates trust dissonance.

If the product fails the filter, say so plainly and name what it would suit
instead. Do not build a charming ad for a product that needs a demo.

## Gate 1 — product read (do the research, then summarise in under 200 words)

Source from the product URL, listing text, or image. Then state:

1. **Verified facts:** name, price, key specs, star rating and rating count.
   Quote only what the source actually says.
2. **Buyer language:** recurring phrases from real reviews, in the buyer's words.
3. **Who actually buys.** Reviews frequently reveal the purchaser is not the
   user: an adult child buying for a parent, a spouse buying for a partner. If so,
   **put the product into the purchaser's hand on screen.** This is usually worth
   more than any feature beat, and it is the single biggest advantage this
   register has over a technical one.
4. **What you will NOT claim, and why.** Check the negative reviews and the fine
   print. If reviews contradict durability, the ad does not say "built to last."
   If a subscription is required, the ad does not imply the feature is free.
5. **Anything unbuyable.** No buy box, out of stock, region-locked shipping, or a
   newer model at the same price — flag it before writing a word of creative. A
   perfect ad pointed at a dead listing converts at zero.

## Gate 2 — the three-step chain

Never go straight to video. Each step locks one thing so the video call only has
to invent motion.

**Step 1: character sheet.** `arcads_generate_image`, model `nano-banana-2`,
`1:1`, with the product photo as a reference. On one canvas:

- the lead character in **three emotional states**, readable in the eyes, with
  the low-point expression as the most important panel on the sheet
- any secondary character
- the product, treated per the doctrine below, in 2 to 3 views
- a scale line-up at true relative size

**Step 2: composition key frame.** `arcads_generate_image`, `nano-banana-2`,
`9:16`, referencing the sheet plus the product photo. This is the shot the ad
lives in: strict vertical thirds, one named practical light source, the emotional
low point staged. Specify camera height, lens, and where the shallow focus band
sits.

**Step 3: the render.** One Seedance call referencing the key frame, the sheet,
and the product photo. That is exactly 3 reference images, which is the maximum.

## Product treatment — pick one and say why

**Doctrine C: in-world product, real hero card.** The default. The product is
recreated exactly in design but rendered in the animated look, so the character
can physically use it. The real photographic product appears only in the final
beat as a hero card, outside the styled world, where nobody has to hold it.
Recognition comes from design fidelity, not from material.

Human-scale worlds make this easy: the real design maps 1:1 onto the character's
hands with no scale negotiation. Always add the lock line:

> The product is exactly as shown in the reference: same shape, same colour,
> same proportions, same finish. Do not redesign or restyle it.

And name the specific identifying details — a rivet, a hinge, a lens shape.
Generic descriptions produce generic props.

**Doctrine D: product as character.** Available only when the product's real
articulation is expressive: a pan-tilt head, a hinged lid, a swivelling arm. The
product performs, using **only movements the real product makes.** No eyes, no
mouth, no eyebrows, no limbs, no hopping. Head angle and existing mechanisms
only.

This constraint is the whole point: every expressive beat doubles as a real
feature demo. State the negatives explicitly, because the model will happily bolt
on eyes and turn your product into a mascot.

## The script

Two audio tracks. Label every line.

- **VO** — the narrator. Owns the problem statement, the mechanism, the offer,
  the brand. **This is the primary track; it carries the selling.**
- **SYNC** — dialogue from characters in the scene. Owns proof that the feeling
  is real. Never give SYNC the offer.

Rules:

1. **One shared budget: 30 to 33 words total for 15 seconds.** VO and SYNC draw
   from the same account. Count before writing the prompt, every time.
2. **They never overlap.** Write the SYNC lines first, fit VO into the silence.
3. **Pattern:** SYNC states an emotional fact, VO names what it means, SYNC pays
   it off. Argument and feeling alternate rather than compete.
4. **Name the speaker and one word of intent. Never direct the mix.** No reverb
   notes, no mic distance, no exclusive silence windows. Dense prompts degrade
   before sparse ones, and audio engineering crowds out visual direction. The
   model handles layering.
5. **Prefer escalating specifics over comparisons.** "Four times. Four and a
   half. Five. All the way to six" argues the same point as "most readers stop at
   three" without asserting a competitor fact you cannot verify.
6. Sign-off under 6 words. Give the hero card at least 2 seconds — a brand name
   plus a price needs room or it rushes.
7. No em-dashes in ad copy.

### VOICE STYLE block — required in every prompt

Cast the narrator as concretely as the style card casts the look: age, gender,
register, pace, and what it must NOT sound like.

> The NARRATOR is a warm, low, unhurried woman in her forties, close and
> confessional, the tone of someone telling you something true rather than
> selling. Never bright, never announcer-like. The IN-SCENE voices are ordinary
> and unperformed.

Always include the negative **`no upbeat announcer voice`**. Models drift toward
radio-ad delivery, and that single drift kills the entire emotional register.

### The 15-second skeleton

Five beats. See `references/story-arcs.md` for worked arcs and worked examples.

| TC | Beat | Track |
|---|---|---|
| 0:00–0:03 | **Hook.** A character states the want out loud. | SYNC |
| 0:03–0:06 | **Problem.** The attempt fails on screen. | VO names it |
| 0:06–0:08 | **Low point.** The private defeat. The most important 2 seconds. | SYNC |
| 0:08–0:11 | **Turn.** The product arrives, ideally from the purchaser, and is used. One hard snap of change. | SYNC or silent |
| 0:11–0:15 | **Payoff and offer.** In-scene warmth, hard cut to hero card at 0:13. | VO closes |

The turn needs a **single-frame** change, not a gradual one: a page snapping into
focus, a light coming on. Specify "in a single frame," or the model will render a
slow dissolve and the payoff lands soft.

## Output format

Deliver in this order, no preamble:

1. **PRODUCT READ** — verified facts, buyer language, who actually buys, what you
   will not claim and why, anything unbuyable.
2. **FIT** — one line confirming the product passes Gate 0, or a plain refusal
   with a better register named.
3. **ANGLE** — the enemy this ad attacks.
4. **DOCTRINE** — C or D, and why.
5. **SCRIPT** — timecoded table: timecode, audio (each line tagged VO or SYNC),
   visual. One SFX line. State the word count against the 30 to 33 budget.
6. **THE CALL** — tool and exact params.
7. Then generate: character sheet, key frame, render.

## The call

```
arcads_generate_video_seedance_20
  prompt:          [one self-contained block]
  duration:        15
  aspectRatio:     "9:16"
  resolution:      "1080p"
  audioEnabled:    true
  referenceImages: ["videoassets/{keyframe}.png",
                    "videoassets/{sheet}.png",
                    "videoassets/{product}.png"]
```

**Image handling.** Local paths fail; the MCP runs remotely.
`arcads_get_upload_url` (pass mimeType) → HTTP PUT the raw bytes **bare, with no
extra headers** (the URL carries a signed checksum param but only `host` is in
`X-Amz-SignedHeaders`, so adding `x-amz-checksum-crc32` returns 403) → wait for
200 → `arcads_register_image` → reference as **`videoassets/{assetId}.png`**. The
bare asset UUID is rejected with `INVALID_REFERENCE_IMAGES` despite what the
register tool's output suggests. Crop marketplace screenshots first; UI chrome on
an edge gets rendered into the scene.

## IP rules

The trademark risk here is higher than for any material-based style, because this
aesthetic belongs to specific studios and models will hand you near-copies of
their characters.

- **Never name a studio or franchise in a prompt.** Write "stylized 3D animated
  feature film look."
- Never depict named or recognisable characters. Original designs only.
- Do not reproduce a studio's mascot or signature motifs, even by allusion.
- Add these negatives to every prompt: `no named or copyrighted animated film
  characters`, `no photorealistic humans`, `no uncanny faces`, `no dead eyes`.

## QC, in priority order

1. **The lead's face at the low point.** Everything rides on it. If that beat
   does not land, nothing else matters.
2. **The turn snapped in one frame**, not a slow focus pull.
3. **Voices:** narrator distinct from characters, no overlap, right language, no
   announcer delivery.
4. **Product fidelity** — the specific identifying details survived, and under
   doctrine D nothing grew eyes or limbs.
5. **The hero card cut** reads as intentional, not as a seam.
6. **Uncanny valley** on any human, especially children.

Fix by subtraction. A failed render gets shorter lines and fewer beats, not more
instructions.

## Hard rules

- One product, one 15-second call per run.
- Count the words before writing the prompt.
- Never invent reviews, ratings, prices, or performance claims.
- Never claim what the reviews contradict.
- On-screen text is short words and numbers only, never sentences.
- Do not generate before the operator approves the spend.
- If a fact cannot be verified from the source given, leave it out and say so.
