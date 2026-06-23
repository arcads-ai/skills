---
name: media-router
description: >
  Smart router for any "generate" or "edit/modify/repurpose" request on an image or
  video. Introspects connected MCP servers, locates the Arcads MCP, reads its live tool
  list, picks the best-matching tool for the user's intent, and runs it end-to-end
  (upload, call, poll, deliver). Use proactively when the user asks to "generate an
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

---

## When to defer to a specialized skill

Before routing, check whether one of these matches better and hand off instead. **All three sibling skills below are `disable-model-invocation: true`** — they will not auto-activate on user phrases, so you (the router) are the one route that brings them in. Invoke them explicitly with the Skill tool (e.g. `mcp_Skill("arcads:clone-hook")`); this works even when model-invocation is disabled.

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

## Step 5 — Collect required inputs and upload assets

For the chosen tool, read its required parameters and check what the user has actually provided:

- **Missing required parameter?** Ask the user — one item at a time, the most important first.
- **Any parameter expects a file (image, video, audio)?** The Arcads MCP can't read local desktop paths. Upload first:
  1. Get the file onto disk (search `~/Downloads`, `~/Desktop`, `~/Pictures` if the user pasted a chat thumbnail rather than a path: `find ~/Downloads ~/Desktop -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.mp4" -o -iname "*.mov" \) -mmin -15`). Confirm by reading.
  2. Call `arcads_get_upload_url` with the file's `mimeType`.
  3. `PUT` the bytes: `curl -X PUT -H "Content-Type: <mimeType>" --data-binary @"<localPath>" "<presignedUrl>"`. Expect HTTP 200.
  4. Pass the returned `filePath` as the parameter value.
- **Upload paths expire (~10 min).** If a call fails with `REFERENCE_FILE_NOT_FOUND`, re-upload and retry with the fresh path.
- **Reasonable defaults for unset optional params:** `aspectRatio` `"9:16"` for social video / `"1:1"` for static, `resolution` `"1080p"`, `audioEnabled` `true` for video. Override anything the user specified.
- **`productId`:** if the tool returns `PRODUCT_SELECTION_REQUIRED` with a list, ask the user which product, then pass its `id`.

---

## Step 6 — Run, poll, deliver

Call the chosen tool with the assembled parameters.

- Tell the user something short and human, e.g. "Generating your image…" or "Editing your video…". Don't narrate which tool or how.
- Poll with `arcads_get_asset` until `status === "generated"` (or `"failed"`). Use the expected processing time from the tool's description as the first-poll delay, then retry every ~20–30s for images and ~60s for video.
- On success, call `arcads_watch_asset` (or read the asset's `data.url` for non-media outputs like text analysis) to get the signed URL.
- Download and open locally:
  - **Image** → `curl -sL "<url>" -o ~/Downloads/arcads-output.png && open ~/Downloads/arcads-output.png`
  - **Video** → `curl -sL "<url>" -o ~/Downloads/arcads-output.mp4 && open ~/Downloads/arcads-output.mp4`
  - **Audio** → `curl -sL "<url>" -o ~/Downloads/arcads-output.mp3 && open ~/Downloads/arcads-output.mp3`
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
| `arcads_get_asset` / `arcads_watch_asset` | Step 6 — poll and fetch the signed URL |
| `AskUserQuestion` | Steps 3, 4, 5, 7 — disambiguate intent, pick between top tool candidates, collect missing params, offer follow-ups |
| `open <file>` (after `curl` download) | Step 6 — inline preview of the result |
