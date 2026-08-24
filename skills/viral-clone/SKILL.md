---
name: viral-clone
description: 'Clone any viral video ad frame by frame with a different product swapped in, on the Arcads MCP connector plus local ffmpeg. Inputs: one reference video plus 1 to 3 product images. Output preserves the reference''s shots, cuts, camera, hands, set, lighting, captions, and pacing, with only the product and its packaging replaced. Primary engine: arcads_generate_video_omni_flash in edit mode with a source-as-truth product-lock prompt; fallback: per-shot rebuild (nano-banana-2 stills plus Seedance or Kling image-to-video, stitched). Trigger whenever the user uploads a reference ad and says anything like "copy this ad with my product", "recreate this with my product", "clone this viral video", "same video but swap the product", "この広告をうちの商品でパクって", "product swap", or uploads a viral clip plus product photos with intent to reproduce it. Do NOT use for restyling the user''s own raw footage (omniflash-restyle) or from-scratch ads with no reference (arcads ad skills).'
---

# Arcads Viral Clone (product swap)

One reference viral ad plus product images in, the same ad with your product out. This skill treats the reference video as pixel-level ground truth and swaps ONLY the product objects. Everything else (hands, set, fabric, lighting, camera, cut timing, on-screen captions, pacing) is preserved.

## REQUIRED INPUTS (collect before doing anything else)

1. **Reference video (required):** the viral ad to clone, as a file. 3s minimum (Omni Flash floor). Any length works; over 10s gets chunked. A link is not enough on Claude.ai; ask for the file if only a URL was given.
2. **Product images, 1 to 3 (required):** clear photos of the replacement product. If the reference shows packaging (box, jar, pouch, bag), one image MUST show the replacement packaging; without it the model invents packaging or leaves the original. Best set: one clean side/hero shot, one packaging shot, one in-context shot.
3. **Product name and original product name (required, can be inferred):** the prompt must name both what to remove and what to insert. If either cannot be identified from the inputs, ask; guessing the original brand wrong weakens the removal instruction.
4. **New script (conditional):** ONLY if the reference contains spoken voice-over that mentions the original product. Ambient/ASMR audio relays as-is with no script. Ask before generating, never after.
5. **On-screen text decision (conditional):** if the reference's burned-in captions name the original brand, ask whether to keep, re-text, or drop them.

If 1 or 2 is missing, stop and ask. Do not substitute web-searched product images without telling the user.

All artifacts (shot tables, prompts, QC notes) are in ENGLISH regardless of conversation language. No em dashes in artifacts; use commas, periods, or parentheses.

## Route decision (do this first, after ingest)

- **EDIT route (default):** the new product has the same form factor as the original (shoe to shoe, jar to jar, phone to phone) and the reference is 3s or longer. Omni Flash edits the actual footage, which gives true frame-by-frame fidelity. One call per chunk of 10s or less.
- **REBUILD route (fallback):** form factors differ materially (shoe to skincare jar), the reference contains a real person whose face or body would need synthesis, or the EDIT route drifts after the repair ladder. Decode each shot into a spec, generate an anchor still per shot with nano-banana-2 (product images as references), animate each still with Seedance 2.0 or Kling 3.0 image-to-video at the shot's duration, stitch. Lower pixel fidelity, unlimited flexibility.
- A reference with a visible person handling the product still qualifies for EDIT as long as the person is untouched; scope every instruction to the product objects and pin the person in the hold clause.
- **Head-to-head result (verified):** on a 9s branded unboxing, Seedance 2.0 with the reference video in referenceVideos produced its own third-hand and autonomous-paper artifacts AND leaked the original brand into the remake (original-brand insoles inside the replacement shoe, original box unswapped). Generation-native remakes inherit the reference's branding; if the REBUILD route must be used on a branded reference, feed it only the shot-table text plus product images, never the original branded video.

## PHASE A: INGEST

1. ffprobe the reference: duration, resolution, fps, color_transfer. If HDR (arib-std-b67 / smpte2084), tonemap to SDR: `ffmpeg -i in.mp4 -vf zscale=t=linear:npl=100,tonemap=hable,zscale=t=bt709:m=bt709:r=tv -c:a copy out.mp4`. TikTok rips (ssstik etc.) are usually bt709 already.
2. Trim to integer seconds (Omni Flash duration is an integer 3 to 10). Trim the tail, re-encode for frame accuracy, strip audio: `ffmpeg -i ref.mp4 -t {int}.0 -an -c:v libx264 -crf 18 source_N s.mp4`
3. Park the original audio for relay: `ffmpeg -i ref.mp4 -t {int}.0 -vn -c:a aac -b:a 192k audio.m4a`. Unboxing/ASMR ambience relays as-is; spoken VO may need a rewrite for the new product (flag to the user before generating).
4. Normalize product images to jpeg or png (webp inputs get converted; keep one image that shows the packaging/box if the reference contains packaging).

## PHASE B: DECODE THE REFERENCE (mandatory, never skip)

**Actually look at the frames. Do not infer the genre from context, filenames, or prior conversations.** Extract at 1 to 2 fps, grid, and view:
`ffmpeg -i ref.mp4 -vf fps=2,scale=270:-1 f_%02d.png` then grid with PIL and inspect.

Detect cuts: `ffmpeg -i ref.mp4 -vf "select='gt(scene,0.3)',showinfo" -f null -` and read pts_time values. Build a shot table: shot number, in/out timecode, content, how the product appears (in box, held, laid flat, macro), any on-screen text verbatim, and any visible branding/packaging that must also swap. Present the table before generating if the user has not already green-lit a run.

## PHASE C: THE ARCADS ASSET WORKFLOW (hard-won, follow exactly)

The Arcads MCP runs remotely; local container paths FAIL with "File not found" in generation tools. Presigned temp uploads are strictly SINGLE-USE, and registering an upload CONSUMES its temp path.

- **For a single generation call:** arcads_get_upload_url (one per file, correct mimeType) -> HTTP PUT the raw bytes with matching Content-Type -> pass the returned `external-api-temp-uploads/...` filePath directly into referenceVideos / referenceImages of ONE call. Do not register first.
- **Registered image asset paths do not resolve in referenceImages.** `videoassets/{id}.mp4` works for registered videos in referenceVideos, but `imageassets/{id}.jpg` returns REFERENCE_FILE_NOT_FOUND. For images: re-upload fresh temp paths for every call that needs them. Budget one get_upload_url + PUT per image per generation attempt.
- Presigned URLs expire in 600 seconds; upload immediately after fetching the URL and fire the generation call in the same pass.

## PHASE D: GENERATE (EDIT route)

One arcads_generate_video_omni_flash call per 10s-or-less chunk:

- referenceVideos: [reference chunk temp path]
- referenceImages: [1 to 3 product image temp paths; put the packaging/box image FIRST if a box swap is needed]
- duration: integer length of the chunk; aspectRatio matching source (usually "9:16")
- nbGenerations: 3 to 4 ALWAYS. Artifacts (extra hands, autonomous objects, brand-text garbling, reversion ghosts of the original product) are stochastic and survive prompt-level object-permanence clauses; verified 4 of 4 single samples flawed on a 9s 8-shot unboxing. Sampling plus per-shot selection (Phase D2) is the quality mechanism, not the prompt.

Prompt structure (product-lock, source-as-truth):

> Edit this video. The source video is the ground truth: preserve frame by frame [list every element that must hold: hands, clothing, surfaces, packaging materials that stay, lighting, every camera angle, every cut at its exact timestamp, all object motion and handling timing, and the on-screen caption "EXACT TEXT" with its emojis], exactly as in the source.
> Apply exactly N object replacements consistently through the entire video:
> 1. Replace [original product, named precisely] with the product shown in the reference images: [full physical description: colors, materials, stripe/logo geometry, lettering]. The replacement must match the original's exact position, scale, orientation, motion, and the way the hands grip and move it in every single shot, frame by frame. The same identical item in every shot, consistent colorway throughout.
> 2. Replace [packaging/box] with [new packaging as shown in the first reference image], same size, same lid position and movement, same placement in frame.
> Do not change anything else. Do not add new objects, do not change the color grade or lighting, do not change any timing or camera motion, no audio changes.

Rules: name the original product and the replacement explicitly (the model needs to know what to remove, not just what to add); "frame by frame" and "same identical pair in every shot" clauses fight cross-shot colorway drift; product + its own packaging counts as one coherent swap family, not competing transforms, but any THIRD unrelated transform (regrade, new text) goes into a separate fix-edit pass.


## PHASE D2: ALIGNED-VARIANT SHOT SPLICING (the core quality mechanism)

Omni Flash edits preserve the source's cut timing, so ALL variants of the same call are frame-aligned with each other and with the source. Best-of-N therefore works at SHOT granularity, not video granularity:

1. Cut every variant into shot clips at the source's detected cut boundaries (re-encode, -an, crf 18). Clips of the same shot index are interchangeable.
2. QC per shot per variant (forensic prompt below, or human eyes on a shot-by-variant frame matrix). Build the matrix: rows shots, columns variants.
3. Pick the clean take per shot, concat with ffmpeg (seams land exactly on cuts), relay the original audio once at the end.
4. Any shot with zero clean takes across all variants: reroll ONLY a 3 to 4s window containing that shot (respecting the 3s duration floor), nbGenerations 3, splice the winner back.

The math that justifies this: with per-shot clean probability p = 0.7 and 8 shots, one sample is clean end to end with probability p^8, about 6%. Four aligned variants spliced per shot: (1-(1-p)^4)^8, about 94%, at the same generation cost. Never ship the raw single best variant when a splice is available.

Note the 3s duration floor blocks naive per-shot chunked GENERATION when the reference cuts every 1 to 1.3s; splicing sidesteps the floor because cutting happens locally after generation.

## PHASE E: QC

Download via arcads_get_asset (status generated -> downloadUrl; re-fetch the asset for a fresh signed URL if a download returns a stub file, the URLs expire).

Generic "does this look right" LLM QC is UNRELIABLE: it passed a video containing autonomous tissue paper and a phantom third hand. Use the forensic prompt verbatim via arcads_analyze_media (pass the generated clip as videoassets/{id}.mp4, no re-upload needed):

> You are a forensic QC inspector for AI-edited video. Go second by second and answer ONLY these questions with brutal strictness. When uncertain, answer FAIL.
> 1. HAND COUNT: how many hands at every moment, could they all belong to ONE person; flag third hands, detached hands, extra arms, impossible entry angles, with timestamps.
> 2. OBJECT COUNT: ever more than the correct number of products visible, including partials? Timestamps.
> 3. AUTONOMOUS OBJECTS: does packaging, paper, or the product ever move without a hand touching it at that moment? Timestamps.
> 4. MORPHING: does any object warp, melt, change shape, or teleport between frames; is brand lettering legible or garbled; timestamps.
> 5. ORIGINAL BRAND LEAK: any remnant of the ORIGINAL product or brand (logos, boxes, insoles, text) in any frame? Timestamps.
> 6. PRODUCT: correct replacement product with a consistent colorway in every shot, correct packaging?
> End with VERDICT: CLEAN or FLAWED plus the single worst artifact and timestamp.

Two calibration notes: the "when uncertain, FAIL" instruction over-reports, so a human eyeball on the flagged timestamps is the final accept; and LLM QC of same-family model output has correlated blind spots, so the human check is not optional for deliverables.

Known permanent weak zone: brand MICRO-TEXT (box labels, tongue tags, small foil lettering) garbles in nearly every generation. Policy: do not burn rerolls on it. Accept shaped-right semi-legible text at social sizes; otherwise patch the logo in post (CapCut overlay or a still-image logo plate), and say so in delivery notes.

High-entropy shots (hands lifting or re-gripping the product, occlusion moments) fail most often; give their reroll windows the highest nbGenerations.

## PHASE F: AUDIO RELAY AND ASSEMBLE

Never keep generated audio. For chunked footage, concat locally first (`ffmpeg -f concat`), seams at cut boundaries. Then relay:
`ffmpeg -i styled.mp4 -i audio.m4a -map 0:v -map 1:a -c:v copy -c:a aac -shortest final.mp4`
Verify final duration matches the trimmed source within one frame.

## PHASE G: DELIVER

Present the final file plus: the shot table, the exact generation prompt(s), asset ids, and a legal note when relevant: the output should contain none of the original brand's marks (that is the point of the swap), but the underlying footage composition belongs to the original creator; for paid media, treat the clone as a format reference and confirm rights posture with the brand. Offer: hook variants (arcads_hook_repurposed), translations (arcads_translate_video), caption re-text via fix-edit, and the REBUILD route for products with different form factors.

## Longer references (over 10s)

Chunk at detected cut boundaries into 6 to 10s segments so stitch seams hide inside cuts. One Omni Flash call per chunk, identical product description text in every chunk prompt (verbatim, to hold colorway across chunks), concat locally, relay audio once at the end.

## Scaling and cost

| Reference length | Calls (no repair) | Wall time |
|---|---|---|
| 10s or less | 1 | ~5 min |
| 10 to 20s | 2 | ~10 min |
| 20 to 40s | 3 to 5 | ~15 min, parallelize |

## Failure modes

- **Local path error ("File not found... use arcads_get_upload_url"):** expected; run the Phase C upload loop.
- **INVALID_REFERENCE_IMAGES on temp paths:** those temp paths were already consumed (usually by registration); get fresh URLs and re-upload.
- **REFERENCE_FILE_NOT_FOUND on imageassets/{id} paths:** registered-image path convention does not resolve; use fresh temp uploads for images.
- **Product colorway flips between shots:** strengthen the "same identical item in every shot, consistent colorway throughout" clause and repeat the full physical description; if it persists, chunk shorter so fewer shots share one call.
- **Original product ghosts back in one shot:** fix-edit naming the timestamp and the exact swap for that shot only.
- **Scene composition drifts (new objects, moved hands):** the preservation list was too thin; enumerate the held elements explicitly and reroll.
- **Extra hands, third products, autonomous objects, reversion ghosts of the original product:** stochastic, prompt clauses reduce but do not eliminate. The fix is architectural: nbGenerations 3 to 4 plus Phase D2 shot splicing.
- **Stale download URL (tiny file, "moov atom not found"):** signed URLs expire; call arcads_get_asset again for a fresh URL.
