---
name: song-ad
description: 'AI music ads: turn a product into a song ad (singing ad, music ad, jingle, musical ad, brand music video) on the Arcads MCP connector plus local ffmpeg. A song about the product (the user''s lyrics, or 2-3 options written from the brief) is generated with Suno v6 (arcads_create_music), vocals from the first second, and plays over a fast-cut animated story with a setup, a turn and a payoff, made with Seedance 2.5 in blocks that each hear their slice of the song, ending on a held, centred product hero. Nobody sings on screen. The full song is laid on top once, then captions. Trigger whenever the user wants their product sung, asks for a song ad, a music ad, an AI music ad, a jingle or a musical ad, or mentions Suno + Seedance for an ad. Do NOT use for spoken voice-over ads (pixar-ad, animated-ad), cinematic films with dialogue (cinematic-ads), or adding background music to an existing video (media-router).'
---

# Song ad (AI music ads)

A song ad is a short animated story told in pictures while a song tells it in words. The song is the spine: it sets the pacing, the emotion and the length. The pictures are a **real story** (a setup, a turn, a payoff), shot like a film: **every shot moves**, there is depth in every frame, the emotions are big and readable with the sound off, and the cutting **follows the music**.

**Nobody sings on screen.** The song plays over the pictures like a music video; characters act, react and move, with their mouths closed. (Lip-sync is not reliable enough in the video model for production ads, so this skill never asks for it.)

Pipeline: brand + research → lyrics → song (vocals from second 0) → transcript and timing → Look + character + product sheets → timed shot list → one Seedance 2.5 clip per block, each with its own slice of the song → motion check on every block → stitch with the full original song on top, captions, product hero.

## How this runs on the Arcads MCP

Generation runs on the Arcads MCP connector; cutting audio, trimming and stitching run locally with `ffmpeg` (the MCP has no audio-cut tool and cannot lay an audio track under a video). Keep everything for one ad in a local run folder, `<run>` (for example `./song-ad-<brand>-<date>/`).

| Job | How |
| --- | --- |
| Brand, product, audience | The user's brief and real product photos; `arcads_list_products` / `arcads_get_product` for a product already on Arcads; `arcads_analyze_media` on the photos for the exact packaging description; web search (when available) for the real customer language |
| Song | `arcads_create_music`, `model: "suno_v6"`, `instrumentalOnly: false`, `lyrics` with section tags, `prompt` = the Suno style prompt, `duration` (20–360; length is APPROXIMATE, the track can come back a little shorter/longer) |
| Timing | `arcads_transcribe`, `mediaType: "audio"`, `format: "srt"` — every sung line with start/end times (line level, not word level) |
| Song slices, head trim | Local `ffmpeg` on the downloaded song |
| Sheets | `arcads_generate_image_nano_banana`, `model: "nano-banana-2"` (best for product/identity consistency across references), grounded on the REAL product photo; `arcads_generate_image_gpt` with `gpt-image-2` for a single photoreal hero still |
| Video | `arcads_generate_video_seedance_25`, `resolution: "720p"`, `aspectRatio: "9:16"`, `duration` = whole seconds, 4–30; `referenceImages` → `@Image 1`, `@Image 2`…; `referenceAudios` → `@Audio 1` = this block's song slice |
| Block check | Local `ffmpeg` scene detection (hard cuts) + `arcads_view_contact_sheet` with `atSeconds` (first/last frame of every shot in one grid) |
| Edit | Local `ffmpeg`: trim each block, concatenate, mute every clip, lay the master song once |
| Captions | `arcads_add_subtitles` with a styled preset and your own timed `segments` |

**Files in and out.**
- Every generation tool is asynchronous and returns an asset id. Poll with `arcads_get_asset` (`waitSeconds` up to 40) until the status is `generated`, then download with `curl -sL "<downloadUrl>" -o <run>/<name>`. Seedance 2.5 takes ~7 min, Suno ~1–2 min, images ~1 min. Don't narrate the polling; say what is running and come back when it lands.
- The MCP runs remotely: a local path does not reach it. To send a local file (a song slice, the stitched ad), call `arcads_get_upload_url` with the right `mimeType` (`audio/mpeg`, `video/mp4`, `image/png`…), `PUT` the raw bytes with the matching `Content-Type` within 10 minutes, and pass the returned `filePath` into ONE call. A temp upload path is single-use: upload again for every call that needs the file.
- To reuse an asset Arcads generated (the sheets, the song), pass its `downloadUrl`, freshly read from `arcads_get_asset` just before the call; the MCP re-uploads it for that call.
- A real product photo used in several calls: upload it once and call `arcads_register_image` on the temp `filePath` to mint a persistent asset, then reuse that asset's path.

**Two prompt facts that change how you work:**
- A re-roll is RE-WORDED (same casting, same Look, same shot order, same locks; vary only the phrasing of secondary direction), never resubmitted as-is.
- There is no negative prompt. Every exclusion is written as prose inside the prompt ("mouths stay closed, nobody sings", "no readable text anywhere except the real packaging"), so state the exclusions more than once and keep them literal.

Write the song lines, the block plan, the shot list, every prompt, every asset id and every check result into `<run>/plan.md` as you go, so the edit can be rebuilt from them.

## The non-negotiables

1. **The song goes to the video model, sliced per block.** Each block's prompt gets its own slice of the master song as `@Audio 1`, so the cuts, the movement and the energy land on the music. The video model's own audio is always dropped in the edit and the original song is laid on top once.
2. **Song-over, always.** Write it in every video prompt: "NO LIP-SYNC: this is a music video; the song plays over the pictures. Nobody on screen sings, talks or mouths any word in any shot; mouths stay closed, smiling or reacting." A character mouthing the lyrics is a failed shot.
3. **The prompt drives the shots, not a picture.** No storyboard images: they cost credits, make the video stiff and leak their text into the footage. The video model gets the Look, the character sheet, the product sheet, the song slice and a detailed shot timeline.
4. **Two motion layers in every shot.** Video models default to *limited animation*: they treat each shot as a drawing they nudge, so "slow push-in, handheld sway" comes back as a held still. Every shot line names both layers in terms the model can measure:
   - **Camera path with start and end framing:** not "push in" but "starts waist-up, ends tight on her eyes"; "arcs left to right past the hanging plants in the foreground"; "cranes down from the ceiling lamp onto the mug". Plus a named **foreground element** for depth.
   - **In-frame motion:** the subject does something that **travels** (walks toward the lens, pours, spins, bikes past, throws) **plus secondary motion** that keeps the frame alive (steam, hair, curtains, dust in the light, rain, foreground parallax).
   - **Static staging is where shots die:** turn every static beat into an action with travel, or give it a big camera path. Never two static, centred, eye-level shots in a row.
5. **Rhythm.** About **2 seconds per shot**, **1-second bursts** on chorus hits, **one held emotional beat of 3–4 seconds**, and the **4–5 second product hero** at the end. About 12–16 shots per 25 seconds, about 20 for 40 seconds. **No shot longer than 2.5s** except that one held beat and the hero. Cut on the beat.
6. **A story, not a montage.** The shots follow the song's five parts (Appendix A) as a real arc: problem → failed attempts → discovery → transformation → payoff, with a **twist or a reaction beat** in the payoff. Emotions big and readable with sound off.
7. **Show the change on screen, progressively.** When the product transforms someone, the character is written explicitly **before** and **after**, and the in-between is written on **every** montage shot ("noticeably brighter than the desk shot", "upright now, blazer on"). Same identity throughout.
8. **Lock what drifts.** Every prompt carries explicit lock lines (step 8).
9. **End on the product, centred, no text.** The last 4–5 seconds are a held product hero: the product in the ad's style, **centred**, label facing camera, about half the frame height, slow push-in. **No CTA text, button or end card over it**: the sung CTA does that job. The video model runs a touch behind the timeline, so start the hero shot ~1 second earlier in the prompt than the music suggests.
10. **Short blocks, whole-second clips, never a frozen frame.** Seedance 2.5 renders a whole multi-shot sequence in ONE clip of up to 30 seconds. Keep each block **≤ ~20s** for the best motion density; split a 40s ad into ~2 blocks of ~20s or 3 of ~13s, and cut only **between sung lines** (never mid-word) and at story/location changes. Each block's clip is a **whole number of seconds, about 2s longer than the block**, with a song slice of exactly that length: the spare seconds let the edit trim a late start instead of freezing a frame. The edit never holds, slows or loops a frame.
11. **One Look per ad**, written once and pasted word for word into every image and video prompt.
12. **No text in the footage.** Captions go on in the edit and stop before the hero.
13. **Your own shots, every time.** The quality bar in Appendix B.6 is a bar, not a template. Never reuse its shots, settings, characters or opening.
14. **Lyrics from the first second.** The first sung word is heard within the first **0.3s** of the final ad. No instrumental intro, no silence, no black frame before the voice. The lyrics have no `[Intro]`, the Suno prompt asks for vocals from the first beat, and if the take still has an intro its head is **trimmed off** (step 3). The trimmed track becomes the **master song** used for every later step.

## Approvals

Ask for approval at each natural checkpoint with `AskUserQuestion` (or a plain-text question that ends your turn when it is unavailable): **lyrics** (pick one option), **song take**, **character + product sheets**, **shot list**. Every question about a generated file carries its link (`[song.mp3](<run>/song.mp3)`, `[character-sheet.png](<run>/character-sheet.png)`) plus a one-line description: the user sees only the chat and the question. The pick is the go-ahead and runs straight away.

**Autonomy mode:** if the user asks to run end-to-end with *no approvals* / "just give me the ad", skip every Stop, make each creative call yourself from the brief, and deliver only the finished ad. An explicit user instruction beats this skill.

## Step 0 — Announce the process (skip in autonomy mode)

Tell the user the 9 steps in one short list: brief + research → lyrics (2–3, pick one) → generate song (pick take) → time the song → Look + character (before/after) + product sheets → plan shots to the music → shot-list approval → one Seedance clip per block + motion check → final edit (stitch, song on top, captions, product hero).

## Step 1 — Brief, research, reference video

Start from what the user gave you; ask only for what is missing, in one message. Pin down: **product** (1–3 REAL product photos are required, never invent proof; `arcads_analyze_media` on them gives the exact packaging description: shape, colours, cap, label text), **audience** (decides character, world, genre), **Look** (glossy 3D feature film, 2D cartoon, claymation, felt stop-motion, anime, watercolour, photoreal…; propose 2–3 if the user has no idea), **setting**, **length**, **song language** (lyrics native, video prompts in English), **CTA** (sung, never on-screen), **format** (9:16 default). **Lyrics:** if the user brings a script or lyrics, use them (fit them to the word budget in step 2 and say what you trimmed); otherwise write them in step 2.

**Research** before writing a line: the product page, plus web/comment research when a search tool is available, for the real pain, trigger moments, exact customer phrases, objections. **Claims guardrail:** an unsubstantiated benefit isn't written.

**Reference video** (if shared): analyse it shot by shot with `arcads_analyze_media` (and local `ffmpeg` scene detection) for Look and pacing only — never copy another brand's concept, people or text.

## Step 2 — Lyrics (2 to 3 options)

**Read Appendix C first, every time.** Before writing a line, pick the reference ads closest to this brief (same product category, same audience, or same format) and name them. Write in their voice: their way of opening, their concrete details, their quoted lines, their repeated tag, their CTA. Use Appendix A for the rules and the format. State angle, awareness stage, genre and length in one line. Write 2–3 genuinely different songs, each a clear story (who, what goes wrong, the turn, the payoff with a twist). Every line showable as a concrete moment. Leave a breath every 8–15s so the ad can be split into blocks between lines.

**Word budget (hard rule).** Suno sings slower than planned and drops lines when lyrics run long:

> sung words ≤ (ad length − 5s) × words per second × 0.9

Words per second: **2.0** for 70–100 BPM (ballad/soul/gospel/mid-tempo), **2.3** pop, **2.7** fast pop, **3.5** rap. A 40s gospel = (40−5) × 2.0 × 0.9 ≈ **63 words**. Count each option's sung words (section tags don't count), trim anything over, and show the count ("59 / 63 words"). Close with "Pick your favorite (or ask for variations)." (Autonomy mode: pick the strongest yourself.)

## Step 3 — Generate the song

`arcads_create_music` with `model: "suno_v6"`, `instrumentalOnly: false`, `lyrics` (approved, with `[Verse] [Chorus] [Outro]` tags), `prompt` = the Suno style prompt (Appendix A), `duration` = ad length (20–360). Download the take to `<run>/song-raw.mp3`. Notes:
- **Length is approximate** — the returned track may be a little shorter/longer than `duration`; time the ACTUAL track in step 4 and plan to that.
- **No artist/band/film/brand name in the style prompt** — the provider rejects it and the whole call fails. Describe the sound, not its source.
- Always a short `[Outro]` with a final hit: it plays under the product hero.
- **No intro, vocals from second 0.** The lyrics start directly with the first sung section (`[Verse 1]` or `[Chorus]`), never with an `[Intro]` tag. The style prompt always ends with "vocals start immediately on the first beat, no instrumental intro".
- **Head trim, every take.** Suno often adds a short intro anyway. Transcribe the take (step 4) and read the first cue's start time. If it is above 0.3s, cut the head locally, keeping the consonant attack: `ffmpeg -i <run>/song-raw.mp3 -ss <first cue start − 0.1> -c:a libmp3lame -q:a 2 <run>/song.mp3`. Otherwise copy the take to `<run>/song.mp3`. This file is the **master song**: re-transcribe it, and every slice, the edit and the captions use it, never the raw take. If the intro is long (over ~4s) or the trimmed start sounds abrupt, regenerate once instead (re-word the style prompt).
- **A mood change mid-song** (sad verse → upbeat chorus, etc.) goes in BOTH the lyric section tags (annotate the mood/tempo inline, e.g. "[Verse - slow, sad, sparse]", "[Chorus - upbeat, bright, full band lifts]") AND the style prompt (describe the arc: "opens slow and melancholic ~85 BPM, then lifts at the chorus to bright uplifting ~120 BPM"). Then VERIFY it landed: ask `arcads_analyze_media` with the song in `referenceAudios` where the tempo and mood change. If the lift never happens, regenerate once with re-worded direction.
- **Missing-line check, every take:** tick every lyric off against the transcript. If a line is missing or garbled, shorten the lyrics and regenerate. Never ship a take with missing lines.
- If it runs past length or ends abruptly, trim the tail on a downbeat with `ffmpeg -t`.

**Stop** for the user to validate the song, with the link to `<run>/song.mp3` in the question (skip in autonomy mode).

## Step 4 — Song timing (the source of truth)

1. `arcads_transcribe` on the approved **master song** (`mediaPath` = a fresh upload of `<run>/song.mp3`, `mediaType: "audio"`, `format: "srt"`): every sung line with start/end times. Save it as `<run>/song.srt`.
2. Correct the text against what's actually sung (keep the timings) — this corrected list is what you later pass to `arcads_add_subtitles` as `segments`.
3. Check the first-cue time: on the master song it must be **≤ 0.3s**. If not, go back to the head trim (step 3) and re-transcribe. Then note the sections, where any mood shift lands (align the story turn to it), and where the outro starts (the product hero goes there). Get the exact length with `ffprobe -v error -show_entries format=duration -of csv=p=0 <run>/song.mp3`.

## Step 5 — Look, character, product

1. **Look Brief** (Appendix B.1) — write once, paste verbatim into EVERY image and video prompt.
2. **Character sheet** (B.2): `arcads_generate_image_nano_banana`, `model: "nano-banana-2"`, `aspectRatio: "16:9"`. Main character + any key second character, in the Look. If the product transforms them, **BEFORE and AFTER on the same sheet, same face**. A from-scratch person: no product, no logo on the sheet.
3. **Product sheet** (B.3): `arcads_generate_image_nano_banana`, `model: "nano-banana-2"`, `aspectRatio: "16:9"`, **grounded on the REAL product photo** (first in `referenceImages`). Packaging exact, including how it opens/is used. Grounding on the real photo keeps the label right in every block — this holds even for a heavily stylised Look (felt, clay, 2D): render the object in the Look while keeping the real label, wordmark, colours and proportions crisp and readable.
4. **Recurring set** (optional): describe once in the Look Brief.

Download both sheets into `<run>`. **Stop** for sheet approval, with both links in the question (skip in autonomy mode).

## Step 6 — Plan the blocks and the shots

Work from the timed lines; write the plan in `<run>/plan.md` before generating.

**Blocks** (one Seedance clip each): ≤ ~20s each (the model's hard ceiling is 30s, but motion density is best at ~20s or under); a 40s ad = 2 blocks of ~20s or 3 of ~13s. A block starts and ends **in a gap between two sung lines**, preferably at a story/location change — and when the song has a mood shift, put a block boundary on it so the sad block and the upbeat block are separate clips. First block starts at **0.0s** of the master song (first sung word ≤ 0.3s); last block ends at the end of the song. **Clip length** = block length + ~2s, rounded UP to a whole second, between 4 and 30. **Song slice** = from the block's start, exactly the clip length long; the LAST block's slice simply ends with the song:

```sh
ffmpeg -i <run>/song.mp3 -ss <block start> -t <clip length> -c:a libmp3lame -q:a 2 <run>/slice-<n>.mp3
```

**Shots** inside each block: ~2s each; 1s on chorus hits; one 3–4s held beat in the whole ad; last shot is the 4–5s product hero. Cut on a sung line's start/end or a downbeat. Times written **relative to the block start** (they go into that block's prompt). For each shot write: the **action with travel** + **secondary motion**; the **camera path with start→end framing** and **angle**; the **foreground element**; the **emotion**. The opening shot comes from the first lyric (B.5 patterns) and its action lands on the first sung word, at 0s: no establishing beat before the voice. The product appears in the action at least twice before the hero.

**Check (write it down):** first sung word ≤ 0.3s on the master song; every block cut between lines; every clip whole seconds, ≥ block + 2s, ≤ 30; no shot > 2.5s except the held beat and the hero; the hero is 4–5s and last.

## Step 7 — Shot list approval (text only; skip in autonomy mode)

One line per shot, numbered, under a one-line block header with its time range. Each line: time, camera move in a few words, action, emotion — under ~20 words. No tables, no clip lengths, no slice times. **Stop, review.** Changes go into the plan; re-check the step 6 numbers if timings change.

## Step 8 — One Seedance 2.5 clip per block

For each block, `arcads_generate_video_seedance_25` with `resolution: "720p"`, `aspectRatio: "9:16"`, `duration` = clip length (whole seconds, ≤ 30):
- `referenceAudios: [ <fresh upload of <run>/slice-<n>.mp3> ]` → `@Audio 1`.
- **referenceImages & grounding (critical):** the styled product sheet ALONE does not hold the label; the **real product photo** has to be in the references of every block that shows the product. For a block with the product on screen, pass `referenceImages: [ realProductPhoto, productSheet, characterSheet ]` → the real photo is `@Image 1`, the styled sheet `@Image 2`, the character sheet `@Image 3` (tags follow array order — reference them by the right index in the prompt). For a block with **no product on screen**, drop the product images and pass only the character sheet (`@Image 1`).
- Never pass a frame that already contains a character (the model snaps them into that pose); carry set continuity in words instead.
- The prompt follows Appendix B.4; the shot timeline covers the block and ends with "<last shot> continues to the end of the clip" (last block: the product hero holds to the end).
- **Blocks 2+:** open with one continuity line: "Continues the same ad: <who, what they look like now, where we are, the light>." Same Look Brief, sheets and lock lines in every block.
- Launch all the blocks together (they don't depend on each other), then poll each one and download it to `<run>/block-<n>.mp4`.

**Identity locks** (a lock line per prompt for each that applies): hair/head; secondary characters' hair, outfit, build; props that must stay plain ("plain white mug, no printing"); product state and which hand holds it; the transformation stage on each montage shot; no signs/menus/posters/labels with writing anywhere except the real packaging; for a stylised Look, "everything visibly made of <material>".

**Verify gate — check each block the moment it lands, before any edit:**
1. Hard cuts: `ffmpeg -i <run>/block-<n>.mp4 -vf "select='gt(scene,0.3)',showinfo" -f null - 2>&1 | grep -o 'pts_time:[0-9.]*'`. Compare the number and times of the cuts with the plan.
2. `arcads_view_contact_sheet` on the block's asset id with `atSeconds` = the first and last moment of every shot. A shot whose first and last frame match (same framing, same pose) is **dead**.
3. Read the grid shot by shot: does each shot move, does the story read with sound off, does anyone mouth words, is the product right.

**Re-roll a block** (once, same references, failing shots sharpened and the whole prompt re-worded) **only for:** a missing/unreadable story beat or missing product hero; wrong/warped packaging; readable stray text/logos; anyone mouthing; dead motion (opening shot dead, or more than a third of the shots). **Everything else is cosmetic — log one line, handle it in the edit or the report.** After one re-roll, stop and report; never loop.

## Step 9 — Stitch, song, captions

1. **Find each clip's late start.** Compare each clip's detected cuts (step 8) with the planned cuts; take the **median difference** of the clearly-matching cuts. If the clip runs late, trim that much off its head; if on time, start at 0 (a small ~0.1–0.2s head trim is normal).
2. **Keep exactly the block's length** from that start, and drop the clip's own audio. Never retime, stretch, slow, hold or loop — the spare seconds absorb the late start. If a clip lacks footage, re-generate that block rather than freezing a frame.
   ```sh
   ffmpeg -i <run>/block-<n>.mp4 -ss <late start> -t <block length> -an -c:v libx264 -crf 18 -pix_fmt yuv420p -r 24 <run>/cut-<n>.mp4
   ```
3. **Concatenate** the cut blocks in order with hard cuts, then **lay the full master song once**, starting at 0.0s of the timeline (its own 0.0s, already head-trimmed) and running to the end, so the first sung word is heard within the first 0.3s. Nothing before it: no silence, no intro, no black frame. No double music.
   ```sh
   printf "file 'cut-%s.mp4'\n" 1 2 3 > <run>/concat.txt
   ffmpeg -f concat -safe 0 -i <run>/concat.txt -c copy <run>/video.mp4
   ffmpeg -i <run>/video.mp4 -i <run>/song.mp3 -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -shortest <run>/ad.mp4
   ```
   Check with `ffprobe` that `ad.mp4` lasts the song's length within a frame.
4. Optional: desaturate the failed-attempts shots (`-vf hue=s=0` on those cuts before concatenating).
5. **Captions** (unless the user declines): upload `<run>/ad.mp4` and call `arcads_add_subtitles` with `videoPath` = that upload. Pass your corrected song lines as `segments` (each `{text, startSeconds, endSeconds}` from step 4) so the brand name and lyrics are spelled right — the first cue starts on the first sung word (≤ 0.3s), all cues end **before** the product hero starts. `style` is one of the styled presets — **`glass`, `whisper`, `glide`, `glide2`, `fusion`, `terminal`, `handwritten`** — pick one that matches the Look and stays readable on bright frames; `position` `top`/`center`/`bottom` (no size control). Keep the product hero clean: no captions, no CTA text. Download the result to `<run>/ad-captioned.mp4`.

Watch the final ad once with `arcads_view_contact_sheet` and run `arcads_transcribe` (`format: "srt"`) on it: first sung word ≤ 0.3s, no frozen frame, no double audio, captions reading, hero clean and centred. Deliver the final file as a link and report in a few lines: what was re-rolled and why, plus the cosmetic log. Offer extras: another song take or lyric variation, a 16:9 or 1:1 cut, a translated version.

## Locked rules

1. Song-over only. Nobody on screen sings/talks/mouths.
2. Song sliced per block into the video model; original song laid on top once; every clip muted.
3. No storyboard images; the shot list is text.
4. Every shot moves in two layers + a foreground element. No shot > 2.5s except one held beat and the hero.
5. A story with a turn and payoff; before/after progressive; identity locks every block.
6. Blocks cut between sung lines (and on any mood shift); clips are whole seconds, ~2s longer than the block, ≤ 30.
7. Never a frozen/slowed/looped frame; a late start is trimmed.
8. Verify every block for motion before editing; re-roll once, only for story/product/text/mouthing/dead-motion, and always re-worded.
9. Lyrics within budget, count shown; every take checked for missing lines and, if a mood shift was asked for, that it actually lands.
10. End on the product, centred, no overlay; captions end before the hero.
11. Seedance 2.5 at 720p; `arcads_create_music` with `suno_v6`; one Look per ad pasted verbatim.
12. No artist/studio/franchise/third-party brand name in any generation prompt; no unproven claims.
13. Your own shots; the quality bar is never a template.
14. Approval at each Stop (lyrics, song, sheets, shot list) — UNLESS the user asked for autonomy / no approvals.
15. A block that shows the product carries the real product photo in `referenceImages`; a block with no product carries no product image.
16. Lyrics from the first second: no `[Intro]`, vocals-first style prompt, head-trimmed master song, first sung word ≤ 0.3s in the final ad.

## Resuming mid-way

Product and no song → step 1. A finished song → step 3 head trim, then step 4. Approved sheets → step 6. Approved shot list → step 8. Keep `<run>/plan.md` current so any step can resume from it.

---

## Appendix A — Songwriting

### Pick the genre from the audience
Infer from the audience, state it, let the user correct. Examples: moms → acoustic/indie pop; women 40+ → country pop, soft rock; men 40+ → classic rock, blues; women 18–25 → pop, hyperpop, R&B; men 18–25 → hip-hop, trap, EDM, pop punk; sports/fitness → hip-hop, trap, EDM; beauty → pop, R&B, dance pop; wellness/spirituality → acoustic folk, ambient, soft soul; health/supplements 40+ → country pop, soft pop, gospel pop; luxury → modern jazz, cinematic pop; Latino → reggaeton, Latin pop; French → urban pop, French variété, melodic rap. If no row fits, take the closest and say why.

### Lyric rules (every option)
Write like the reference ads in Appendix C (see "Writing habits" there). Hook first: the catchiest line is the very first sung line, starting at 0s (no intro, no pickup bars). Sing the customer OUTCOME, not a feature list; product name once or twice at most. Real verses/chorus/held rhyme, never "buy buy buy". Short singable lines (4–8 syllables for a pop hook). Within the word budget. Genre's vocabulary and energy. Structure by length: 15–20s = hook + one chorus; 30s = verse/chorus/verse/chorus; 60s = full song with a bridge. Respect the step 1 claims. Options genuinely different (change POV, mood or hook). Every line a concrete, showable moment.

### Suno structure tags
Lyrics with section tags, each on its own line: `[Verse 1]` `[Chorus]` `[Verse 2]` `[Bridge]` `[Final Chorus]` `[Outro]`. Never an `[Intro]` tag: the first tag is the first sung section. Always a short `[Outro]` — it plays under the hero. For a mood shift, annotate the tags inline, e.g. `[Verse - slow, sad, sparse acoustic]` then `[Chorus - upbeat, bright, full band lifts]`.

### The Suno style prompt (the `arcads_create_music` `prompt`)
Under 30 words: [genre], [vocal: female lead / male rap / duet / choir], [tempo or BPM], [mood], [production], vocals start immediately on the first beat, no instrumental intro. The last clause is mandatory. Examples:
- "upbeat gospel pop, soulful female lead with handclapping choir, 120 BPM, joyful and uplifting, Hammond organ, tambourine, modern polished production, vocals start immediately on the first beat, no instrumental intro"
- "indie pop, soft tender female lead, opens slow and melancholic 85 BPM then lifts at the chorus to bright uplifting 120 BPM, acoustic guitar, warm handclaps, glockenspiel, vocals from the first beat, no intro"
- "melodic trap, confident male vocal, 140 BPM half-time, playful swagger, punchy 808s, vocals from the first beat, no intro"

Never names of artists, bands, songs, films or brands.

### Output format (per option)
**OPTION N: "title/hook"** — Concept (1–2 sentences) — Words: n/budget — Lyrics (with section tags) — Suno style (the `arcads_create_music` prompt) — Story in pictures (2–3 sentences).

### House structure (when the user brings no lyrics)
First-person customer voice, casual, repetition, rhymes. Five parts, each a set of shots:
1. **Hook + problem** (~40%): open on the pain, then the comparison with a repeated tag.
2. **Failed attempts** (~10%): rapid list (these shots can go B&W).
3. **Discovery** (~15%): someone reveals the product + its one reason to believe.
4. **Transformation** (~30%): a time jump, the change in daily life, flip the hook.
5. **Payoff + CTA** (~5%): one line of the new life, then the CTA sung plainly before the outro.

Devices: a 2–3 word repeated tag that flips at the end — lists on the beat — a tiny sung "what's that?" at the discovery — one concrete detail per part — product name once or twice, never as the hook — no unsupported claim.

---

## Appendix B — Prompts

Every generation prompt is in English. No studio/artist/film/franchise/third-party brand names. Replace every `<...>`.

### 1. Look Brief (one per ad, pasted verbatim everywhere)
```
LOOK: <rendering style>; <surface detail>; <character design>; <lighting>; <colour palette>; <recurring set if any>. No readable words, logos or brand names anywhere in the image except the real product packaging.
```
Rendering examples: "super-detailed glossy 3D animated feature film: nuanced facial acting, textured skin, individual hairs, woven fabric, rich set dressing and volumetric lighting" — "handmade felt stop-motion craft animation: everything made of soft needle-felted wool with visible fuzzy fibres, felted seams and tiny hand-stitched details, miniature handmade practical sets, soft tactile diffused lighting, shallow macro depth of field" — "flat 2D vector cartoon, thick outlines, snappy squash-and-stretch" — "handmade stop-motion claymation, visible fingerprints" — "cel-shaded anime, crisp line art, speed lines, impact frames" — "real photographic 35mm film, grain, halation".

### 2. Character sheet (nano-banana-2, 16:9)
```
Character reference sheet, plain neutral background, no text, no labels. <LOOK> CHARACTER: <name>, <age>, <build>, <skin>, <hair>, <face>, <outfit exact colours>, <how the material reads in the Look>. Show the character twice, same face, same hair, same identity: BEFORE (<explicit state>) and AFTER (<explicit state>). Natural adult proportions. LAYOUT: full body front, three-quarter, side profile, back, and three head close-ups: <expr 1>, <expr 2>, <expr 3>. Same character, outfit and hair in every view.
```

### 3. Product sheet (nano-banana-2, grounded on the REAL product photo)
```
Product reference sheet on a clean surface, no added text. The product is exactly the one in the reference image: identical packaging, shape, colours, label layout, wordmark and proportions. Do not redesign or invent any label text. Render the object in the <LOOK> while keeping its printed label and wordmark crisp and readable exactly as in the reference. Views: front, three-quarter, held in a hand, and open/in use (<how it opens and is used>). <LOOK> The product keeps its real packaging label; only material, lighting and surroundings follow the Look.
```

### 4. Video (Seedance 2.5, one clip per block)
`referenceImages` (product block): `[realProductPhoto → @Image 1, productSheet → @Image 2, characterSheet → @Image 3]`; (no-product block): `[characterSheet → @Image 1]`. `referenceAudios`: `[songSlice → @Audio 1]`. `duration` = clip length. `720p`, `9:16`.
```
<Continuity line for blocks 2+: Continues the same ad: who, how they look now, where, light.> <clip length>-second cinematic animated musical advertisement, vertical 9:16. <LOOK> <One sentence of story, naming the mood (sad/slow or bright/upbeat) for this block.> Edited to the music of @Audio 1: <k> shots joined by hard cuts on the beat, every shot has visible camera movement and moving subjects, strong foreground elements, big readable emotions. Immediate motion in the first frame.
PRODUCT REFERENCE @Image 1 is the actual <product> packaging and @Image 2 is the same pack in the <LOOK>: <colours, wordmark, graphics>. Preserve its design, label layout and proportions exactly; do not invent or restyle any label text. <How it appears.> <Which hand holds it.> No reference-photo white background.
CHARACTERS AND PROPS @Image <n> is the character sheet. Match faces, hair and costumes in every shot. <NAME>, <key traits>. BEFORE: <state>. AFTER: the SAME <name>, same face, same <hair>, now <state>. The change happens gradually across shots <n>-<m>. <Second characters.> <Lock lines.>
NO LIP-SYNC: this is a music video; the song plays over the pictures. Nobody on screen sings, talks or mouths any word in any shot; mouths stay closed, smiling or reacting.
SET AND COMPOSITION <Each location: materials, light, props, depth.> Faces and key action centred, nothing important in the lowest third. Foreground elements in most shots.
SHOT TIMELINE [0.0-<t>s] <Camera path + angle, start->end framing> <foreground element>: <who> <action that travels>, <secondary motion>, <emotion>. ... <Not last block:> [<t>-<end>s] <last shot>, continues to the end of the clip. <Last block:> [<t>-<end>s] Product hero: the <product> in the <LOOK>, <where>, <sparkle/steam>, slow push-in, centred, label facing camera, ~half the frame height. Hold it to the end; final shot, do not cut away.
RULES Every shot a hard cut, no transitions, no morphing. Each action reads within the first second. Keep shots in this exact order and at these timecodes. No on-screen text/captions/logos except the real packaging. The product matches @Image 1 exactly.
AUDIO @Audio 1 is this block's part of the song: cut and move on its beats. No voice from anyone on screen. <Sound effects on the beats.>
```
Shot-writing checklist (every line): camera path with start/end framing — angle — foreground element — one action with travel — secondary motion — emotion. ~35–70 words per shot line.

### 5. Camera phrase library (copy, adapt, combine)
A shot only moves if the line says HOW the camera travels through space: the move, the path, the named foreground object it passes, and where it lands. Every move is motivated by an action.

- **Patterns:** crash push-in past a foreground object — reveal from behind something — whip-pan to the event — slow push-in with rack focus to the product — half-orbit on the beat — macro product action (tear/pour) — circling the celebration — low tracking alongside, foreground wipes — worm's-eye hero — backwards tracking entrance — reaction push-in on the rival — sweep through the crowd to the product — frame-wipe transition — speed ramp at the peak — product hero hold.
- **Opening patterns:** extreme close-up pulling back — character POV — overhead top-down — mid-action drop-in — silhouette against a window — a prop in macro racking to the character — fast whip-pan in — slow push through a doorway.
- **Rhythm:** never two similar shots in a row; alternate wide ↔ tight, low ↔ high; cut on motion; hold one quiet beat longer then spike. For 9:16: keep the landing framing centre-weighted and use vertical moves (crane, tilt, worm's-eye) as much as lateral ones.

### 6. The quality bar (NOT a template)
Match this density and specificity; never reuse anyone else's shots, settings, characters or opening. Each shot line says how the camera travels, where it starts and lands, past a named foreground object; every beat has a physical action with travel and a readable emotion plus something moving; prop continuity is explicit; before/after is written in body terms on every montage shot; the ending holds the product, centred, with nothing written over it. Build your own per brief — a 40s ad is ~3 blocks of ~13s, each a self-contained clip hearing its own song slice.

---

## Appendix C — Reference voice

These come from real long-form ads that worked. They are the style reference for every lyric. Borrow their devices and their voice, never their stories, names, brands or claims, and always stay within the word budget (the originals run 4 to 10 minutes; a song ad is far shorter).

### Writing habits (what makes them work)
- The first line tells the whole wound in one breath, with a concrete, almost absurd detail: who, what, where, and the timing that makes it cruel ("at sixty-three in a supermarket aisle, reaching for the toilet paper").
- First person, past tense, told like a friend on the phone, never like an ad.
- Specifics everywhere: exact ages, years, amounts, places, what's in their hands.
- Short quoted lines. The cruel sentence is quoted word for word, then answered ("Looking like what?"). The mentor speaks in orders ("Sit down. Don't argue.").
- Short punches after long sentences ("Ten pounds." "Nobody did.").
- The rival or ex "does the math" and it won't come.
- The mechanism in one plain image (it sits on top vs it sinks in; the wall).
- A week-by-week progression ("Week one... Week three...").
- A stranger asks "What are you using?" and the phone comes out.
- A repeated tag that flips at the end ("broke, broke" → "I got money now").
- The CTA sung plainly: offer, guarantee, scarcity, "link below".

### Sung reference A — rap, supplement, 65 seconds
"No booty, no booty, no hips, no curves, no nothing. Skinny little thing. Look at my homegirl, she thick thick. I'm sick, sick. Every time we hit the club, all eyes on her. All drinks on her. All them boys on her. Damn. Curves is currency. I was broke, broke. The skinny girl nobody notices. Broke, broke. Dead broke. Tried the shakes, tried the squats, tried it and everything. Still no booty pop, no booty pop. Then I see my homegirl's secret. Hold up. What's that bottle? What's that bottle? Girl don't play with me. What's that bottle? Maca root, fenugreek, ashwagandha. Ooh, now it makes sense. 'Cause two weeks later, jeans don't fit. Leggings too tight. Ex-boyfriend sweating. Homegirl talking, 'Girl, did you get work done?' Nope. Just thick thick. Now the hips sitting, now the booty poking. Now when I walk in, heads keep turning. Curves is currency. And baby, I got money now. Link below."

Devices to steal: the repeated tag that flips (broke → I got money now), the sung "what's that bottle?" at the discovery, the list of failed attempts on the beat, the week-later proof, the two-word CTA.

### Sung reference B — software, 77 seconds
"I found a cheat code, [App], that's a flat fact. Drop one long video, get those clips and your life back. I'm hyped that I found an AI that's on my side. Yo, you're the time I save. You're the money I make. So many posts a day. Yo, the views got crazy. Do you scrub through timelines to find good moments? You need [App]. Are you manually resizing aspect ratios? Then you need [App]. Do you type in captions with your fingers? Come on, you know this. Do you pay for a separate scheduler? No, you're joking. First things first, go and sign up here for free. Yes, free. Drop your file or a link from a podcast or stream, or YouTube or a Zoom call, or a stand-up routine. Now watch 'cause this is the part that's fun. It ranks viral potential before you even blink once. Watch your view count go boom, pow to the moon. Work smart, try it right now. It's half off."

Devices to steal: the hook names the outcome in the first line, the sung objection list with a repeated answer, the demo sung as actions, the offer sung plainly at the end.

### Sung reference C — skincare, chorus shape
The verse opens inside a scene with a date and a place ("At sixty-three in a supermarket aisle, reaching for the toilet paper, I heard a voice I hadn't heard in four whole years"), the chorus is the flipped tag plus the mechanism in plain words ("It was never my skin that failed me. It was layers that sat on top. One little tube finally got in, and the glow, it doesn't stop"), the bridge is the week-by-week ("Week one, the gray began to lift. Week three, my eyes looked brighter. Week six, church ladies asked, 'What work you get?'"), the payoff is the rival doing the math that won't run and a stranger asking what she uses, and the outro sings the offer and the guarantee.

### Spoken references (for story beats, details and lines — then make them singable)
Dialogue scenes where a cruel line is quoted and answered; the sister or brother who shows up and says "Don't argue, just trust me" and puts the product on the counter; the mechanism explained in one image ("the molecules are too big, they sit on top until they evaporate" / "you can't burn what's locked behind a biofilm wall"); the reunion/wedding/restaurant scene where the ex looks a second too long; the stranger at the next rack who says "your skin is incredible, what are you using?" and has their phone out before the name is finished; the closing turn ("He didn't stop seeing me. I stopped seeing me.") and then the offer, the guarantee, the scarcity, "link below".

## Tools used

| Tool | Where |
| --- | --- |
| `arcads_list_products` / `arcads_get_product` | Step 1 — a product already on Arcads |
| `arcads_analyze_media` | Step 1 — packaging description, reference video; Step 3 — mood-shift check |
| `arcads_get_upload_url` / `arcads_register_image` | Every local file sent to a tool; the real product photo reused across calls |
| `arcads_create_music` | Step 3 — the song (`suno_v6`, vocals) |
| `arcads_transcribe` | Steps 3–4 — missing-line check and line timings; Step 9 — final check |
| `arcads_generate_image_nano_banana` | Step 5 — character and product sheets |
| `arcads_generate_video_seedance_25` | Step 8 — one clip per block, hearing its song slice |
| `arcads_view_contact_sheet` | Step 8 — motion check; Step 9 — final check |
| `arcads_add_subtitles` | Step 9 — captions from the corrected song lines |
| `arcads_get_asset` | Polling and download links for every generated asset |
| Local `ffmpeg` / `ffprobe` / `curl` | Head trim, song slices, scene detection, trim, concat, song on top, downloads |
