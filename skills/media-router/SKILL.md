---
name: media-router
description: >
  Smart router for any "generate" or "edit/modify/repurpose" request on an image or
  video. Introspects connected MCP servers, locates the Arcads MCP, reads its live tool
  list, picks the best-matching tool for the user's intent, and runs it end-to-end
  (upload, call, poll, deliver). Use when the user asks to "generate an
  image", "make a picture of…", "generate a video", "create a video of…", "edit this
  image", "remove the background", "extend this video", "add captions", "add a
  voice-over", "translate this ad", "upscale this", "change the background", "repurpose
  this video", "make a version with…", "add a logo", "swap the product", or any phrasing
  implying media creation, modification, repurposing, captioning, voice work,
  translation, or enhancement — text-only, image, or video input. Defers to specialized
  skills (arcads:clone-hook, arcads:clone-static-ad, arcads:spy-competitor-ads) when
  they match. Do not trigger for read-only/analytical queries.
---

# Arcads Media Router

You route any media-generation or media-editing request to the right Arcads MCP tool. You do not memorize the tool catalog — you **discover it live** every time, because the catalog evolves. Read the connected MCP's tool list and descriptions, then pick the single best match for the user's intent and run it end-to-end.

---

## Golden rules

1. **Discover, don't assume.** Never call an `arcads_*` tool from memory. Inspect the MCP at runtime, read each tool's current `description` / parameters, and pick from that live list. If a tool you used last week has been renamed or replaced, you'll catch it.
2. **Defer to specialized skills when they fit.** If the user's intent matches a sibling Arcads skill, hand off to it instead of routing yourself. See "When to defer" below.
3. **One clarifying question max when ambiguous.** If the intent could plausibly map to two very different tools (e.g. "make a video of my product" with no product asset — text-to-video or image-to-video?), ask exactly one short question, then route. Never run multiple disambiguating turns.
4. **Real assets only.** If the request edits or repurposes an existing image/video, the user must provide that asset. If they didn't, ask. Never invent the source media.
5. **No technical leakage.** Don't surface tool names, MCP names, asset IDs, S3 paths, or polling cycles. Speak like a creative director: "Generating your image…", then deliver.
6. **Stop when a hard requirement is missing.** No source asset for an edit, no product image for a clone, no destination language for a translation — ask once, then proceed.
7. **Spend after a yes.** Any video call, and any call with `nbGenerations` above 1, waits for the cost stop at the end of Step 5.

---

## When to defer to a specialized skill

Before routing, check whether one of these matches better and hand off instead. Invoke the sibling skill explicitly with the Skill tool (e.g. `Skill("arcads:clone-hook")`). The hand-off carries the request and none of the user's consent: each sibling asks its own confirmation and shows its own cost stop before it spends anything.

| User intent | Defer to |
|---|---|
| "Find competitor ads", "spy on competitors", "download winning ads" | `arcads:spy-competitor-ads` |
| "Find the hook", "where does the hook end", "analyze this ad's opening" | `arcads:clone-hook` (stop after analysis step) |
| "Clone this hook for my brand", "recreate this opening for my product" (video) | `arcads:clone-hook` |
| "Spy on competitors, find the best hook, and clone it for me" (full chain) | `arcads:clone-hook` (it auto-runs spy-competitor-ads when no video) |
| "Clone this static ad for my brand", "recreate this image ad for my product" | `arcads:clone-static-ad` |

Only route here (i.e. pick a raw `arcads_*` tool yourself) when the request is a single generic media generation or edit (e.g. "generate an image of X", "add captions to this", "translate this video", "remove the background", "upscale this") that no specialized skill clearly covers.

---

## Step 1 — Locate the Arcads MCP

Inspect the available MCP servers (and their tools) currently connected to the agent runtime:

- In environments that expose connected MCPs as namespaced tools (the most common case), enumerate the tools whose names look like `<mcp-name>_<tool-name>` and find a server whose name contains `arcads` (case-insensitive). The Arcads tools will typically be exposed as `arcads_*` or `mcp__arcads__*`.
- If your runtime exposes an explicit "list MCPs" or "list tools" capability (e.g. `list_mcps`, `list_tools`, `mcp__list_servers`), use it.
- If neither is available, search the recent session's tool surface for any tool whose name starts with `arcads_`.

**If no Arcads MCP is connected**, stop and say exactly:
> "I need the Arcads MCP server connected to generate or edit media. Install it (instructions at https://arcads.ai) and reconnect, then try again."

Do not fall back to other image/video generators — this skill is Arcads-specific.

---

## Step 2 — Read the live tool catalog

Once Arcads is located, **collect the current tool list**, including each tool's:
- name
- description
- input parameters (names + types + which are required)

This is the canonical source of truth. Tool descriptions may include phrasing like "generate an image from a prompt", "edit an existing image with a mask", "extract a frame", "add captions", "translate the voice-over", "remove background", "outpaint a video", "upscale", "swap the actor", "lip-sync to new audio", etc. — read what's actually there.

**Cache the catalog for the current turn only.** Don't keep it across turns; the user may install/upgrade the MCP between turns.

---

## Step 3 — Classify the user's intent

Reduce the request to one short structured intent before scanning the catalog:

1. **Input modality** — `none` (text-only), `image`, `video`, `audio`, or `multiple`.
2. **Output modality** — `image`, `video`, `audio`, or `text` (e.g. analysis).
3. **Action** — pick one of:
   - `generate` — produce new media from scratch (text-to-image, text-to-video)
   - `image-to-image` / `image-to-video` — condition new media on a provided image
   - `edit` — modify an existing image/video locally (background swap, object remove, inpaint, outpaint, color shift, retouch)
   - `repurpose` — same media, different format (resize, crop, reframe, change aspect ratio, extract a frame, change duration)
   - `enhance` — quality/output improvements (upscale, denoise, stabilize, color-grade)
   - `caption` — burn-in or styled captions
   - `voice` — voice-over, dubbing, lip-sync, voice clone
   - `translate` — change spoken or written language
   - `composite` — merge/overlay/insert (add a logo, place a product, add a sticker)
   - `analyze` — describe / break down / classify (rare here; usually defer to a specialized skill)
4. **Key constraints** — anything explicit in the prompt: aspect ratio, duration, language, actor style, brand assets, must-include text.

Write this internally as a 4-line scratch note. The router decisions come from this, not from the raw user words.

If two actions are plausible and they map to materially different tools (e.g. *generate a new image of my product* vs. *edit my existing product photo*), ask exactly one short question:
> "Do you want me to (a) generate a new image from a description, or (b) start from a photo you'll share?"

---

## Step 4 — Pick the best-matching tool

Walk the live catalog and score each tool against the intent. Pick the tool whose description and parameters best satisfy **all** of:

1. **Output modality match** — a video tool can't satisfy an image request and vice-versa. Hard filter.
2. **Input modality match** — if the user provided an image, prefer tools that take an image input (image-to-image, image-to-video, edit-with-reference). If they provided text only, prefer pure text-to-X tools.
3. **Action match** — the description should explicitly cover the action (edit, upscale, caption, translate, generate, etc.).
4. **Constraint fit** — among remaining candidates, prefer the one whose parameters expose the user's explicit constraints (e.g. `aspectRatio`, `duration`, `language`, `referenceImages`).
5. **Specificity** — when two tools could work, prefer the **more specific** one. A dedicated "add captions" tool beats a generic "edit video" tool for a captioning request.
6. **Recency / version** — if multiple versions of the same tool exist (e.g. `_v2`, `_20`, `seedance_20` vs. `seedance`), prefer the newest unless the user explicitly asked for an older one.

If after this no tool clearly wins, surface the top 2 candidates with `AskUserQuestion`:
> "Two tools could do this — [A: short description] or [B: short description]. Which fits?"

Do not run two tools in parallel hoping one works.

---

## Run folder

Create one folder per run with `mkdir -p ~/Downloads/arcads/media-router-$(date +%Y%m%d-%H%M)` and reuse that exact path, written `<run>` below, for the whole run, follow-ups included. Every file the run produces goes into it, and the link handed over points into this folder.

---

## Step 5 — Collect required inputs and upload assets

For the chosen tool, read its required parameters and check what the user has actually provided:

- **Missing required parameter?** Ask the user — one item at a time, the most important first.
- **Any parameter expects a file (image, video, audio)?** The Arcads MCP can't read local desktop paths. Upload first:
  1. Get the file onto disk (search `~/Downloads`, `~/Desktop`, `~/Pictures` if the user pasted a chat thumbnail rather than a path: `find ~/Downloads ~/Desktop -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.mp4" -o -iname "*.mov" \) -mmin -15`). Confirm by reading.
  2. Call `arcads_get_upload_url` with the file's `mimeType`.
  3. `PUT` the bytes: `curl -X PUT -H "Content-Type: <mimeType>" --data-binary @"<localPath>" "<presignedUrl>"`. Expect HTTP 200.
  4. Pass the returned `filePath` as the parameter value. File fields (`referenceImages`, `startFrame`, …) take only a `filePath` returned by `arcads_get_upload_url` after its PUT; a local file is uploaded first.
- **Each upload serves one generation call.** A generation copies its `external-api-temp-uploads/*` references and deletes them, so upload a fresh copy of each input for every call, including calls you run in parallel. If a call fails with `INVALID_REFERENCE_IMAGES` or `REFERENCE_FILE_NOT_FOUND`, re-upload and retry once with the new `filePath`.
- **Reasonable defaults for unset optional params:** `aspectRatio` `"9:16"` for social video / `"1:1"` for static, `audioEnabled` `true` for video. Leave `resolution` unset so the tool's own default (720p for video) applies, and set a higher one only when the user asks for it. Override anything the user specified.
- **`productId`:** if the tool returns `PRODUCT_SELECTION_REQUIRED` with a list, ask the user which product, then pass its `id`.

### Cost stop before spending

Video generation and multi-variant calls are where credits go. Before any video call, and before any call with `nbGenerations` above 1, describe what will be generated and wait for a yes with `AskUserQuestion`: "This will make [N images / N clips (lengths)] at [resolution] with [model], then [edit passes]. Generation uses your Arcads credits; video costs much more than images, and 1080p much more than 720p. Continue?" A request to skip questions leaves the stop in place: spending needs a yes to a described run. When `AskUserQuestion` is unavailable, put the question in plain text and end your turn.

Before asking, price the run with the server. When the generation tools list an `estimateOnly` parameter, call each planned generation once with the settings it will use and `estimateOnly: true`; this returns its price in credits and generates nothing. Leave out file fields whose file does not exist yet. Add the prices and put the total in the question, saying "about" when a price is marked approximate. When some calls have no price (a tool without the parameter, or an estimate that returns an error), give the total of what was priced and name what is not, for example "plus the voice pass, not priced in advance"; with no price at all, ask the question without a figure. When the quote says the workspace cannot pay (`canAfford: false`), say so in the question with the reason in plain words, and offer to shrink the run. Edit passes cannot be priced yet, so the question names them. When an estimate call returns created assets instead of a price, stop and tell the user a generation has started.

State quantities: the number of outputs (`nbGenerations` times the call), each clip's duration, the resolution, the model, and any edit pass that follows. The only figure in the message is the total the estimate calls returned. The yes covers exactly that call; a further call, a higher resolution or more variants get their own stop. A go-ahead the user gave before seeing the priced run is a request to price it: show the total and ask again. A single image call with one variant goes ahead without a stop.

---

## Step 6 — Run, poll, deliver

Call the chosen tool with the assembled parameters.

- Tell the user something short and human, e.g. "Generating your image…" or "Editing your video…". Don't narrate which tool or how.
- Poll with `arcads_get_asset` until `status === "generated"` (or `"failed"`). Use the expected processing time from the tool's description as the first-poll delay, then retry every ~20–30s for images and ~60s for video.
- On success, the `arcads_get_asset` result carries the `downloadUrl` of a media file (for text outputs like an analysis, read `data.generatedText` instead).
- Save locally (media file only — never execute or `open` it from the shell) and give the user a clickable file link:
  - **Image** → `curl -sL "<url>" -o <run>/output-1.png`, then link to that file
  - **Video** → `curl -sL "<url>" -o <run>/output-1.mp4`, then link to that file
  - **Audio** → `curl -sL "<url>" -o <run>/output-1.mp3`, then link to that file
  - Number each further output of the run (`output-2.png`, …). The question that asks about a result, in `AskUserQuestion` or in plain text, carries its link and a short description (`[output-1.png](<run>/output-1.png): product centered on cream`): the user sees only the chat and question text, and an image you open with Read stays invisible to them.
- On failure, read the error message, fix the obvious issue (re-upload expired refs, drop an invalid parameter, ask the user for a missing input), and retry **once**. If it fails again, surface a short explanation and stop.

Then summarize in one line — what was produced, not which tool you used:
> "Here's your image. 1:1, with the product centered on a cream backdrop as requested."

---

## Step 7 — Offer a tight follow-up

End with `AskUserQuestion` for the natural next step, scoped to the output type:

**For an image output:**
- Love it — done
- Tweak it (free text → what to change)
- Turn it into a video
- Add text/captions/logo overlay

**For a video output:**
- Love it — done
- Tweak it (free text → what to change)
- Add captions
- Add a voice-over / translate

**For an edit/repurpose output:**
- Looks good
- Apply the same edit to another file
- Tweak the edit (free text)

Stop there. Don't append a paragraph of suggestions.

---

## Edge cases

- **No Arcads MCP connected** → Step 1 stop message. Do not substitute another image/video tool.
- **Tool catalog is empty or unreadable** → say "The Arcads MCP is connected but didn't return any tools. Restart the MCP and try again." and stop.
- **Multiple Arcads MCPs connected** (rare — e.g. prod + staging) → pick the one whose name doesn't contain "test", "staging", or "dev"; if still ambiguous, ask once.
- **User provided text only but asked to "edit"** → ask for the source file. Edits need an input.
- **User provided a file but no instructions** → ask for the action ("Generate a video from it? Remove the background? Upscale?").
- **Request matches a specialized skill** → defer; do not route here.
- **Catalog has no tool that fits** → tell the user clearly: "Arcads doesn't currently expose a tool that does [X]. Closest options are [A] and [B] — want me to use one of those?" Don't fudge with the wrong tool.

---

## Quick reference — tools used

| Tool | Where |
|---|---|
| MCP introspection (`list_tools` / namespaced tool enumeration) | Step 1 + 2 — locate Arcads and read the live catalog |
| `arcads_get_upload_url` + `curl -X PUT` | Step 5 — upload any file inputs |
| The chosen `arcads_*` tool (picked at runtime) | Step 6 — execute the routed action |
| `arcads_get_asset` | Step 6 — poll and fetch the signed `downloadUrl` |
| `AskUserQuestion` | Steps 3, 4, 5, 7 — disambiguate intent, pick between top tool candidates, collect missing params, confirm the cost before video or multi-variant calls, offer follow-ups |
| `curl -o` (save only) + file link | Step 6 — deliver the result |
