---
name: omniflash-restyle
description: 'Restyle a raw talking-head video into the look of a reference edit using Arcads Omni Flash (arcads_generate_video_omni_flash). Required inputs: RAW footage, reference video or screenshots, and script (script governs on-screen text spelling, transcript governs timing). Copies the full editing grammar: backgrounds, typography, overlays, zoom in/out, punch-ins, and cut density (many cuts in the reference means many cuts in the output). Locks the person''s identity so the face never changes. Omni Flash runs multiple timed scene changes in ONE call via a timestamped prompt (1 to 2s switches are fine); hard limits are 3 to 10s input/output per call. 10s or less is one call; longer footage is chunked, stitched, and the original voice relaid for lip sync. Never trust Omni Flash audio. All outputs in English. Trigger on: ''edit my video like this'', ''restyle this'', ''make it look like this reel'', ''Omni Flash edit'', a talking-head clip plus a style reference, or a viral AI-editing tutorial to replicate on Arcads.'
---

# Arcads Omni Flash Restyle

Turn raw talking-head footage plus a reference edit into a finished scene-by-scene restyled video, entirely on the Arcads MCP connector plus local ffmpeg. The reference look this skill was built on: hard background replacement per scene, chunky kinetic typography synced to speech, sticker and doodle overlays, retro UI frame devices, aggressive reframing, one visual idea per phrase, style change every 1 to 2 seconds.

All skill outputs are in ENGLISH regardless of conversation language: the style spec, the timeline plan table, every generation prompt, QC notes, and delivery notes. Conversational replies may follow the user's language, but the artifacts are English. No em dashes anywhere in output; use commas, periods, or parentheses.

## What Omni Flash can and cannot do (verified, do not re-litigate)

- **CAN: multiple timed scene changes in one call.** A timestamped multi-scene prompt ("0 to 2s: X. 2 to 4s: Y. 4 to 6s: Z.") executes reliably, including 1 second pacing. This is the default mode. Same internal-timeframe prompt structure as the vox-animated-ad Seedance skill.
- **CANNOT: input or output shorter than 3 seconds or longer than 10.** Schema: duration integer 3 to 10, referenceVideos as source. The 3 second floor constrains the clip you feed it, never the scene pacing inside it.
- **CANNOT: competing simultaneous edits on the same element.** "Replace the background AND regrade the whole image" style stacked global instructions drop one silently (verified in earlier sessions). Sequential timed scenes are fine; simultaneous competing transforms are not. One dominant transformation per scene beat.
- **KNOWN DRIFT RISK: the person's face.** Verified in field use: without countermeasures Omni Flash alters facial features during restyling. The countermeasure is video-as-truth framing (below): the source video is the identity ground truth, still face references stay OUT of standard beats, and every prompt opens with the preservation lock. This is mandatory in every call, not optional polish.
- **DO NOT TRUST: audio.** Discard generated audio always; relay the source voice in post.

The practical consequence: input length is a chunking problem, not a model problem. 10s or less is one call. 60s is 6 to 7 calls, not 15.

## Hard defaults (do not drift)

- **Edit model:** arcads_generate_video_omni_flash with the source clip (or chunk) in referenceVideos, aspectRatio matching source (usually "9:16"), duration set explicitly to the clip's integer length. Do not omit duration; auto-pick causes drift.
- **The source VIDEO is the identity ground truth. Video stays video.** In standard beats (person facing camera, visible in source), do NOT pass any face image. referenceVideos carries the source clip and the prompt instructs preservation of the person exactly as they appear in the video, frame by frame. Adding a still face reference in these beats risks flipping the model from "preserve this footage" into "generate this person from the image", which is the drift we are avoiding, and it wastes a style slot. referenceImages in standard mode = up to 3 style frames from the reference edit.
- **Face anchor image ONLY for synthesis beats.** When a beat genuinely requires rendering the person beyond what the source pixels show (user-approved true angle change, heavy stylization of the person themselves), extract one clean frontal frame from the RAW and put it first in referenceImages for that call, with the lock sentence pointing at it. Everywhere else the anchor stays out.
- **How the model actually behaves (documented):** Omni Flash is an edit-native model that treats the source video as the truth for the scene and reference images as the truth for the look. It applies the changes you name and preserves the elements you do not mention. The corollary is the real drift mechanism: a GLOBAL style instruction ("make the whole video look like this reel") sweeps the person into the restyle. Scope every transformation to the surroundings (background, typography, overlays, crop) and pin the person by name in the hold clause. Google's own guidance: edit prompts must be very specific; lead with a transformation verb, close with a "keep" clause listing what must hold. Per-beat face QC stays because preservation is prompt-scoped behavior, not a guarantee, and a mis-scoped beat still drifts.
- **Full camera grammar replication.** The reference's camera language gets copied completely: punch-in zooms, snap zoom-outs, crop reframes, shake, AND true angle changes, dolly-ins, low angles, behind-the-subject moves. Omni Flash documents shot-language editing (close-up to wide, angle shifts, dolly-in) with character consistency held across moves, and field results confirm the person survives when the identity pin is explicit. Name the camera move inside each beat as part of its transformation, and pin identity THROUGH the move: "the camera changes angle; the person stays the same person, same face, same body." Do not pre-sanitize angle changes into crops. Demotion rule: only if a specific angle beat shows face drift in QC after one fix-edit does that beat fall back to a punch-in or crop reframe with the same energy.
- **Never keep Omni Flash audio.** Extract the original audio once at ingest (ffmpeg -i raw.mp4 -vn -c:a aac voice.m4a), discard all generated audio, relay the original track over the final video.
- **Integer-second durations.** Round chunk lengths to whole seconds so requested duration matches source. For a fractional total (9.55s), request 10 and verify; trim overshoot rather than letting the model stretch.
- **One dominant transformation per scene beat** inside the timeline prompt. On-screen text belongs to its scene's transformation, not a second instruction.
- **Chunk seams double as scene cuts.** When splitting footage over 10s, place chunk boundaries exactly where a style change happens. The stitch seam hides inside the cut.
- **Stitch locally with ffmpeg concat** when clips are downloaded (free, frame-accurate, and required anyway for audio relay). arcads_stitch_videos (2 to 6 clips, batch for more) when the user wants an Arcads-native story for demos.
- **Tools are deferred.** Load schemas with tool_search ("arcads omni flash", "arcads stitch trim", "arcads upload") before the first call each session.
- **HDR iPhone footage must be tonemapped to SDR before upload:** ffmpeg -i in.mp4 -vf zscale=t=linear:npl=100,tonemap=hable,zscale=t=bt709:m=bt709:r=tv -c:a copy out.mp4

## The Arcads asset workflow (memorize)

Presigned S3 temp upload paths are single-use. For any asset reused across calls:

1. arcads_get_upload_url for a presigned URL.
2. PUT the file bytes.
3. arcads_register_video (or arcads_register_image) to get an asset id.
4. Reference downstream as videoassets/{id}.mp4 (or .png).

Local paths are auto-uploaded by most generation tools, but any clip referenced in multiple attempts (rerolls, variants) must be registered once and reused by asset path.

---

## PHASE A: INGEST AND TRANSCRIBE

1. ffprobe the raw footage: duration, resolution, fps, HDR flag. Tonemap if HDR.
2. Extract and park the voice track: ffmpeg -i raw.mp4 -vn -c:a aac -b:a 192k /work/voice.m4a
3. Get word-level timestamps (arcads_transcribe on the uploaded footage; local whisper as fallback). The scene timeline depends on timestamps, not just text.
4. Ask for the script if it was not provided; treat it as a required input. Division of authority: the transcript wins on TIMING (when each word is actually spoken), the script wins on SPELLING (what the on-screen text says). Force-align the script to the transcript timestamps. Transcription reliably mangles proper nouns and brand names ("Arcads" becomes "arcades" or "our cards"), and a misspelled burned-in caption is the most expensive failure in the pipeline (full-clip reroll discovered at QC). If the user genuinely has no script, show them the transcript and get explicit spelling confirmation on every on-screen text string, especially proper nouns, before generating.

## PHASE B: DECODE THE REFERENCE INTO A STYLE SPEC

Extract frames from the reference at 2fps (ffmpeg -vf fps=2), grid them, decode into a JSON style spec. Over-specify on purpose. Per scene archetype capture:

```json
{
  "archetype_id": "kinetic_bg_swap",
  "background": "flat maroon #8C2332, full replacement, subject cut out cleanly",
  "typography": "ultra-bold condensed sans, cream #F2E8D5, fills 60% of frame behind subject, one phrase max 4 words",
  "overlays": "none",
  "frame_device": "none",
  "reframe": "keep original framing",
  "camera": "hard punch-in to 130% on the stressed word, snap back on beat end",
  "motion": "text slams in on first syllable, static after",
  "mood": "loud, editorial, print-poster"
}
```

Also measure the reference's global rhythm and record it at the top of the spec:

```json
{
  "cut_density": "one hard cut every 1.2s (8 cuts in 9.5s)",
  "camera_grammar": "punch-in on emphasis words, snap zoom out on phrase ends, one fisheye moment, low-angle shift on the CTA beat",
  "zoom_range": "100% to 140% crops",
  "sound_feel": "whoosh on every cut, bass hit on text slams, paper-slap on sticker pop-ins, upbeat lo-fi bed"
}
```

sound_feel never goes into generation prompts (generated audio is discarded); it feeds the post-audio cue sheet in Phase H.

The timeline plan must MATCH the reference's cut density, not dilute it. A reference cutting every 1.2s that gets restyled at one look per 4s reads as a different, slower edit. Beats inherit both a visual archetype and a camera move.

Common archetypes in this style family: flat-color background swap with giant kinetic type; retro media-player or camcorder REC UI frame; sticker or emoji pop-in; split color-block background with silhouette cutout; tight crop with drop-shadow caption; textured background (cutting mat, cardboard) with hand-drawn doodles, arrows, or marker circles; fisheye or vignette lens moment; polaroid or cutout framing of the subject.

Save 1 to 3 representative reference frames per archetype for referenceImages.

## PHASE C: SCENE TIMELINE PLAN

Map transcript phrases to scene beats on a single timeline:

- Beat boundaries at clause boundaries, never mid-word. Each beat carries one complete thought and one archetype.
- Beats can be 1 to 3 seconds; the reference's native cadence is fine. No 3 second floor here; the floor applies to clip duration, not beats.
- Match the reference's measured cut_density. If the reference cuts every 1.2s, plan beats at that cadence; do not average it out. When a dense timeline starts degrading in generation (beats firing late or skipping), merge the two least important beats first rather than slowing the whole edit.
- Every beat gets a camera move from the reference's grammar (punch-in, zoom out, dolly, angle change, shake, hold), copied at full strength; do not water angle changes down to crops preemptively.
- Rotate archetypes; never two identical looks back to back.
- On-screen text per beat: max 5 to 6 words, the words spoken inside that beat, spelled per the SCRIPT (never per the transcript).
- If total footage is 10s or less: one clip, one timeline, one call.
- If over 10s: chunk into 6 to 10 second segments, cutting exactly on a beat boundary so the stitch seam coincides with a style change. Each chunk gets its own internal timeline prompt.

Output the plan as a table (beat, timecode, spoken words, archetype, on-screen text, chunk assignment) and get user sign-off before generating.

## PHASE D: SPLIT AND UPLOAD (over 10s footage only)

ffmpeg -i raw.mp4 -ss {in} -t {dur} -c:v libx264 -crf 18 -an /work/chunk_{n}.mp4

Cut without audio (-an); the voice returns at the end. Re-encode rather than stream-copy so cuts are frame-accurate. Register each chunk via the upload loop. For 10s-or-less footage, upload the whole clip once (still strip audio expectations; the relay happens regardless).

## PHASE E: GENERATE

One arcads_generate_video_omni_flash call per clip/chunk:

- referenceVideos: [source clip asset path]
- referenceImages: [up to 3 archetype/style frames from the reference edit; NO face image in standard beats]
- duration: integer length of the source clip
- aspectRatio: "9:16"
- prompt structure, video-as-truth identity lock first, then timestamped timeline with a camera move per beat:

> Edit this video. Preserve the person exactly as they appear in the source video, frame by frame: same face, same features, same skin, same hair, same body, same lip movement, same gesture timing. Do not redraw, regenerate, restyle, or beautify the person; treat their footage as locked and edit only what surrounds them (background, typography, overlays, crops). Apply these scene changes in sequence:
> 0.0 to 2.4s: Replace the background with a flat maroon poster wall; giant cream ultra-bold condensed typography "EDITING IS SO EASY" slams in behind the person. Hard punch-in to 125% on "EASY".
> 2.4 to 3.4s: Snap zoom back out to full frame; the maroon scene gains a retro media-player UI frame overlay (REC dot, battery icon, playback bar).
> 3.4 to 5.8s: Hard cut to mustard yellow background, chunky maroon 3D-extruded text "EVEN FOR PEOPLE LIKE ME", small calendar sticker pops in.
> 3.4 to 5.8s beat may also carry a camera move, e.g.: dolly-in from mid-shot to close-up across the beat.
> 5.8 to 9.5s: Hard cut to teal cutting-mat grid background, camera shifts to a slightly low angle, hand-drawn white arrows pointing at the person, yellow handwritten caption building word by word "YOU CAN DO EVERYTHING WITH ARCADS".
> Match the visual style of the other reference images. Execute every camera move as written, including zooms and angle changes; through every camera move it is the same person, same face, same body, same identity. Do not change the person's timing or speed. No audio changes.

Rules: the video-as-truth identity lock is always the first sentence; no face image in referenceImages unless the beat is a user-approved synthesis beat (then the anchor goes first and the lock sentence points at it); one dominant transformation per beat plus its camera move; exact on-screen text in quotes; guards at top and bottom; never stack two competing global transforms in the same beat.

Parallelize chunk calls where the connector allows; each is roughly 2 minutes.

## PHASE F: QC BEFORE ASSEMBLY

Per generated clip:

1. ffprobe duration. Must match the request within 0.1s; mismatch means audio drift after relay. Conform by trimming, never by retiming (retiming changes lip speed).
2. Extract a frame per beat; check each scene change landed at the right timestamp, text is spelled correctly, face is intact. Misspelled text gets a fix-edit first (flawed clip as source, single correction instruction, nothing else changed); only reroll the timeline if two fix-edits fail.
3. Face check on EVERY beat, not just one: extract one frame per beat from source and styled clip at matching timestamps, place them side by side, and compare facial features, not just mouth shapes. Any beat where the face reads as a different or beautified person is an automatic reroll; this is the failure the pipeline exists to prevent.
4. Camera check: confirm each beat's camera move landed as written (punch-in, zoom-out, dolly, angle change). Angle-change beats get the hardest face comparison; drift on an angle beat triggers one fix-edit, then the punch-in fallback for that beat.

## PHASE G: ASSEMBLE AND RELAY AUDIO

Single-call outputs skip concat. For chunks:

```bash
printf "file 'chunk_1_styled.mp4'\n..." > list.txt
ffmpeg -f concat -safe 0 -i list.txt -c copy silent_cut.mp4
```

Then relay the original voice over whatever the final video is:

```bash
ffmpeg -i styled.mp4 -i voice.m4a -map 0:v -map 1:a -c:v copy -c:a aac -shortest final.mp4
```

Verify total duration matches source within one frame, then watch every beat boundary: voice must be continuous across scene changes, lips in sync at spot-check points. There is no Arcads tool that lays an external audio track; this step is always local.

## PHASE H: DELIVER

Present the final file, the timeline table, the prompt(s) used, asset ids, and an SFX/music cue sheet derived from the style spec's sound_feel (per beat: timestamp, cue, e.g. "0.0s whoosh + bass hit on text slam"). Offer: beat-level fix-edit list, alternate archetype swaps (regenerate the same clip with a different timeline, cheap since it is one call), and a music bed (voice at full, bed at -18dB, ffmpeg amix). CapCut remains a valid manual finishing path for users who want hand-placed SFX or text repairs; the cue sheet is written so it drops straight into either workflow.

## Scaling table

| Input length | Calls (no reroll) | Wall time est. |
|---|---|---|
| 10s or less | 1 | ~5 min |
| 10 to 20s | 2 | ~8 min |
| 20 to 40s | 3 to 5 | ~15 min, parallelize |
| 40 to 60s | 5 to 7 | ~20 min, parallelize |

Fix cheap before rerolling expensive. Omni Flash is edit-native, so a flawed output is itself editable: pass the flawed clip as referenceVideos in a new call with ONE plain-language fix instruction ("Fix the on-screen text at 3.4 to 5.8s to read exactly EVEN FOR PEOPLE LIKE ME. Change nothing else.") at the same duration. Repair order: (1) fix-edit on the output, (2) full timeline reroll, (3) isolate the stubborn beat into its own 3 to 4s chunk. Note the compounding risk: each fix-edit pass re-renders the clip, so run the face QC again after every fix and cap chains at 2 fix-edits before falling back to a reroll. Text-heavy timelines historically add 30 to 50% in repair calls; quote that upfront.

## Failure modes and fixes

- **Text misspelled or garbled:** fix-edit the flawed output first (single correction instruction, exact spelling in quotes, "change nothing else"). If two fix-edits fail, reroll the timeline with that beat's text instruction moved to the front and nbGenerations: 2. If that also fails, drop burned text for that beat and flag for a CapCut overlay.
- **A beat's scene change fires late or gets skipped:** reduce beat count for that clip (merge the two shortest beats) or shift boundaries to rounder timestamps. Dense timelines degrade before sparse ones.
- **Person's identity drifts or lips regenerate:** the usual root cause is a globally-scoped instruction that swept the person into the restyle. Escalate in this order. (A) Re-scope every beat's transformation to surroundings only and confirm the hold clause names the person explicitly; confirm no stray face image sat in referenceImages of a standard beat. (B) Reduce the offending beat's aggressiveness: drop the camera move, then the reframe, then reduce to background-only. (C) As a countermeasure variant, add the face anchor frame first in referenceImages with the lock pointing at it, and A/B against the video-only version; keep whichever holds the face. (D) If drift survives two rerolls, fall back to compositing: source as base layer, generate only background and overlay plates, assemble locally. Materially different pipeline; say so before doing it.
- **Angle-change beat drifts the face:** first a fix-edit on the output pinning identity harder for that beat. If it persists, fall back to a punch-in or crop reframe with the same energy for that beat only; keep true angle moves everywhere they hold.
- **Competing transforms in one beat, one silently dropped:** expected. Split into two beats or accept the dominant edit.
- **Duration mismatch:** conform by trim, never stretch.
- **Clip looks like a new generation, not an edit:** the source was probably not passed in referenceVideos or the asset path failed to resolve; verify before blaming the model.
