---
name: spy-competitor-ads
description: >
  Find and download competitor ads from the Meta Ad Library. Three modes — VIDEO only
  (`media_type=video`), IMAGE only (`media_type=image`), or BOTH (`media_type=all`); if
  the user didn't say which, ask once before scraping. Also confirms the competitor
  shortlist with a multi-select before scraping. Use proactively when the user wants to
  spy on competitors, find competitor ads, download competitor videos or images, grab
  winning creatives, or build a swipe file. Triggers on "download competitor ads", "spy
  on competitor ads", "find ads from [brand]", "what are [competitor] running", "grab
  competitor videos", "find static ads from [brand]", "give me all competitor ads (video
  and image)", "build me a full swipe file", or any phrasing implying collecting real
  competitor ad content — even without saying "Meta" or "Ad Library". When run
  standalone, ends with a multi-select to pick which ads to clone — videos handed to
  arcads:clone-hook, images to arcads:clone-static-ad, one chained run per pick.
---

# Spy Competitor Ads — Find & Download

Your only job: **find competitor ads and download them.** Nothing else. Execute the whole pipeline silently and the user's first output is the downloaded creatives themselves.

**Media type — pick exactly ONE of three modes. NO default.**

| Mode | Explicit trigger phrases | `media_type` param | Extractor | Downloads |
|---|---|---|---|---|
| **VIDEO** | "video ads", "competitor videos", "video creatives", "their videos" | `video` | `<video>` only | `.mp4` |
| **IMAGE** | "static ads", "image ads", "photo ads", "still creatives", "posters", "image creatives" | `image` | `<img>` only (min 200px) | `.jpg` / `.png` |
| **BOTH** | "both", "video and image", "videos and statics", "all formats", "everything", "any media", "full swipe file" | `all` | `<video>` + `<img>` in one pass | `.mp4` + `.jpg` / `.png` |

If — and only if — the user's request **does not contain an explicit trigger for one of the three modes**, ask with `AskUserQuestion` before doing anything else (see Step 1b). Do NOT silently default to video. The chosen mode then flows through the whole skill: URL → in-page extractor → file extensions → delivery list. Pick once and stick with it for every competitor in the run.

---

## Golden rules

1. **Silent execution. No narration, no logging.** Never say what you are doing or have done — no "Searching…", "Found 12 ads", "Downloading…", "Moving files…". No status lines, no step commentary. The user sees only the final downloaded creatives.
2. **Up to three forms, and only these three.** You may ask: (a) which media mode to run (Step 1b, if not explicit in the request), (b) which auto-found competitors to keep (Step 1c, when you had to discover them yourself), and (c) which delivered creatives to clone (Step 5, only on standalone runs). All use `AskUserQuestion`. Beyond these three, no other questions, confirmations, or "proceed?" check-ins. Between forms, go fully autonomous.
3. **No analysis.** Do NOT analyze the creatives, describe hooks, summarize messaging, rank by "why it's winning", or write a competitive brief. Do not profile the competitors. Just find and download.
4. **Auto-find competitors when not given — then confirm.** If the user names competitors, use them as-is, no confirmation. If not, find them yourself AND surface them with a multi-select form so the user can drop any that don't fit (Step 1c). Never silently scrape against a list the user never saw.
5. **No technical leakage.** Never mention CDN URLs, asset IDs, MCP tool names, scraping mechanics, or file-move steps.
6. **One mode per run** (VIDEO, IMAGE, or BOTH — see the mode table above). Skip carousels in every mode.
7. **Browser MCP is required.** The Meta Ad Library is JavaScript-rendered. If no browser automation MCP is connected, that is the one thing you stop and report (Step 2).

---

## Step 1 — Resolve the brand, mode, and competitors

You run up to three short setup interactions here, **in this exact order**, and only the ones whose answer isn't already in the request. Once these are settled, go autonomous.

### 1a — Brand

- **Brand named or obvious from context?** → use it.
- **Not inferable?** → ask exactly one short question: *"What's your brand or product?"* Nothing else.

### 1b — Media mode (NO default — ask if missing)

Read the user's request. If it contains an explicit phrase from the mode-trigger table (VIDEO / IMAGE / BOTH), use that and skip this step.

If the request is silent on media type, ask with `AskUserQuestion`:

> **Question**: "Which kind of competitor ads should I grab?"
> **Header**: "Media type"
> **Options**:
> - **Video ads** — "Playable video creatives only (.mp4)"
> - **Static / image ads** — "Static image creatives only (.jpg / .png)"
> - **Both video and image** — "Everything they're running, in one pass (Recommended)"

Wait for the answer before doing anything else. **Do not default to video.** Do not scrape without an explicit choice.

### 1c — Competitor shortlist

- **Competitors named by the user?** → use them as-is. Skip this confirmation entirely.
- **Not named?** → find 3–5 direct competitors yourself with a quick `WebSearch`/`WebFetch` (brands selling a similar product to a similar audience that plausibly run paid social). Then confirm with `AskUserQuestion`:

  > **Question**: "Found these competitors for [user's brand]. Pick the ones to spy on — keep the relevant ones, drop the rest."
  > **Header**: "Competitors"
  > **Multiple**: `true`
  > **Options**: one per discovered competitor, with a one-line label like "BrandX — meal kits", "BrandY — recipe app", etc. Each `description` explains why it was matched.

  The form's `custom` option lets the user type any competitor you missed. Run the scrape against the final selection (kept + added). If the user selects zero, ask once for a manual list, then stop.

  Never silently scrape against an auto-found list the user never saw.

### Count

Default count: top **5** ads pooled across the final competitor selection. If the user specified a number ("2 ads", "one each"), honor it exactly.

---

## Step 2 — Browser MCP check

Confirm a browser automation MCP is connected (e.g. `mcp__Claude_in_Chrome__*`, Playwright, Chrome DevTools, Puppeteer). Verify with `list_connected_browsers` or equivalent.

- **Connected** → proceed silently.
- **Not connected** → stop and say only:
  > "I need a browser automation plugin (like the Claude-in-Chrome extension or Playwright) connected to read the Meta Ad Library. Connect one and I'll grab the ads."

Do not try to work around this with `WebFetch`.

---

## Step 3 — Scrape + download in one pass per competitor

Run competitors **sequentially** (parallel sessions trigger bot detection).

For each competitor, build the URL — pick `media_type` based on the chosen mode:

**VIDEO mode (default):**
```
https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=ALL&is_targeted_country=false&media_type=video&search_type=keyword_unordered&sort_data[direction]=desc&sort_data[mode]=total_impressions&q=<COMPETITOR_URL_ENCODED>
```

**IMAGE mode:**
```
https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=ALL&is_targeted_country=false&media_type=image&search_type=keyword_unordered&sort_data[direction]=desc&sort_data[mode]=total_impressions&q=<COMPETITOR_URL_ENCODED>
```

**BOTH mode (image + video):**
```
https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=ALL&is_targeted_country=false&media_type=all&search_type=keyword_unordered&sort_data[direction]=desc&sort_data[mode]=total_impressions&q=<COMPETITOR_URL_ENCODED>
```

Use the user's primary market for `country=` if they mentioned one, else `ALL`.

Then, for speed, do everything in as few calls as possible — **navigate, wait briefly, then one JavaScript call** that scrolls, extracts, filters, and downloads:

### Critical technical facts (learned the hard way)

- **`curl` does NOT work.** The browser extension masks Meta CDN media URLs (they carry cookie/query-string/JWT tokens), so the raw `src` is never returned to you and an external `curl` has no valid URL. **Download in-page instead**: `fetch(src)` → `blob()` → temporary `<a download>` → `click()`. This saves to the browser's Downloads folder. You never need to see the URL.
- **Keyword pollution is common.** A search for a brand often returns an unrelated company with the same name (e.g. "Creatify" the AI tool vs. "Creatify.mx" a sticker shop). Inspect each card's advertiser name / domain / copy and keep only cards that match the real competitor. Drop the rest.
- **Impressions are hidden** for commercial (non-political) ads. Don't rank by impressions. Instead prefer the **most-recurring creative** (many near-identical live copies = highest spend = proven winner), then most recent. Pick the top N by that heuristic.
- **Selector + extension depend on the mode.** VIDEO mode uses `<video>` + `.mp4`. IMAGE mode uses the card's main `<img>` + `.jpg`/`.png`. BOTH mode collects `<video>` and `<img>` in the same pass (with the same min-size filter for images). In every mode, filter out tiny avatars/icons (≤ ~200px on either side) so you only keep real ad creatives.

### One-shot extract + download script — VIDEO mode

```js
(async () => {
  // 1. trigger lazy-load
  window.scrollTo(0, document.body.scrollHeight);
  await new Promise(r => setTimeout(r, 2500));
  window.scrollTo(0, document.body.scrollHeight);
  await new Promise(r => setTimeout(r, 2000));

  // 2. collect videos + their card text
  const vids = Array.from(document.querySelectorAll('video'))
    .filter(v => (v.src || v.currentSrc || '').startsWith('http'));
  const cardText = (v) => {
    let el = v;
    for (let i = 0; i < 12 && el; i++) {
      el = el.parentElement;
      if (el && el.innerText && el.innerText.length > 100 && el.innerText.length < 2000) return el.innerText;
    }
    return '';
  };

  // 3. keep only cards matching the REAL competitor (edit the regex per brand),
  //    drop same-name pollution, and de-dupe so recurring creatives count once.
  const BRAND = /creatify\.?ai|@creatify/i;        // <-- set per competitor
  const kept = [];
  const seen = new Set();
  for (const v of vids) {
    const t = cardText(v);
    if (!BRAND.test(t)) continue;
    const key = t.slice(0, 80);
    kept.push({ v, t, dup: seen.has(key) });
    seen.add(key);
  }

  // 4. download up to N (recurring creatives appear first → already spend-weighted)
  const N = 5;                                      // <-- set to requested count
  const picks = kept.slice(0, N);
  const results = [];
  for (let i = 0; i < picks.length; i++) {
    const url = picks[i].v.src || picks[i].v.currentSrc;
    try {
      const b = await (await fetch(url)).blob();
      const a = document.createElement('a');
      a.href = URL.createObjectURL(b);
      a.download = `spy-ad-${i + 1}-COMPETITOR.mp4`;   // <-- set competitor slug
      document.body.appendChild(a); a.click(); a.remove();
      results.push({ i: i + 1, bytes: b.size });
    } catch (e) { results.push({ i: i + 1, error: String(e) }); }
  }
  return results;
})()
```

### One-shot extract + download script — STATIC / IMAGE mode

```js
(async () => {
  // 1. trigger lazy-load
  window.scrollTo(0, document.body.scrollHeight);
  await new Promise(r => setTimeout(r, 2500));
  window.scrollTo(0, document.body.scrollHeight);
  await new Promise(r => setTimeout(r, 2000));

  // 2. collect images + their card text. Drop avatars/icons by minimum size.
  const MIN = 200;                                  // px — anything smaller is likely an avatar/icon
  const imgs = Array.from(document.querySelectorAll('img'))
    .filter(i => (i.currentSrc || i.src || '').startsWith('http'))
    .filter(i => (i.naturalWidth || i.width) >= MIN && (i.naturalHeight || i.height) >= MIN);
  const cardText = (n) => {
    let el = n;
    for (let i = 0; i < 12 && el; i++) {
      el = el.parentElement;
      if (el && el.innerText && el.innerText.length > 100 && el.innerText.length < 2000) return el.innerText;
    }
    return '';
  };

  // 3. keep only cards matching the REAL competitor (edit the regex per brand),
  //    drop same-name pollution, and de-dupe so recurring creatives count once.
  const BRAND = /creatify\.?ai|@creatify/i;        // <-- set per competitor
  const kept = [];
  const seen = new Set();
  for (const img of imgs) {
    const t = cardText(img);
    if (!BRAND.test(t)) continue;
    const key = t.slice(0, 80);
    if (seen.has(key)) continue;                    // de-dupe identical creatives
    kept.push({ img, t });
    seen.add(key);
  }

  // 4. download up to N as JPGs (recurring creatives appear first → already spend-weighted)
  const N = 5;                                      // <-- set to requested count
  const picks = kept.slice(0, N);
  const results = [];
  for (let i = 0; i < picks.length; i++) {
    const url = picks[i].img.currentSrc || picks[i].img.src;
    try {
      const b = await (await fetch(url)).blob();
      const ext = (b.type && b.type.includes('png')) ? 'png' : 'jpg';
      const a = document.createElement('a');
      a.href = URL.createObjectURL(b);
      a.download = `spy-ad-${i + 1}-COMPETITOR.${ext}`;  // <-- set competitor slug
      document.body.appendChild(a); a.click(); a.remove();
      results.push({ i: i + 1, bytes: b.size, ext });
    } catch (e) { results.push({ i: i + 1, error: String(e) }); }
  }
  return results;
})()
```

### One-shot extract + download script — BOTH mode (image + video)

Collects videos and images in a single pass off the same `media_type=all` page. Deduplication is per-card (one creative per ad card, regardless of whether it's a video or an image), so a single card with both a poster image and a playable video counts once and prefers the video.

```js
(async () => {
  // 1. trigger lazy-load
  window.scrollTo(0, document.body.scrollHeight);
  await new Promise(r => setTimeout(r, 2500));
  window.scrollTo(0, document.body.scrollHeight);
  await new Promise(r => setTimeout(r, 2000));

  const MIN = 200;                                  // px — minimum image size to count as a real creative

  // 2. helper: walk up to find the ad card and its text, return both
  const cardOf = (node) => {
    let el = node;
    for (let i = 0; i < 12 && el; i++) {
      el = el.parentElement;
      if (el && el.innerText && el.innerText.length > 100 && el.innerText.length < 2000) {
        return { card: el, text: el.innerText };
      }
    }
    return { card: null, text: '' };
  };

  // 3. collect candidates: every video, plus every large image
  const candidates = [];
  for (const v of document.querySelectorAll('video')) {
    const url = v.src || v.currentSrc || '';
    if (!url.startsWith('http')) continue;
    candidates.push({ kind: 'video', node: v, url });
  }
  for (const img of document.querySelectorAll('img')) {
    const url = img.currentSrc || img.src || '';
    if (!url.startsWith('http')) continue;
    if ((img.naturalWidth || img.width) < MIN || (img.naturalHeight || img.height) < MIN) continue;
    candidates.push({ kind: 'image', node: img, url });
  }

  // 4. attach card text + de-dupe per card (video wins over image when both exist on the same card)
  const BRAND = /creatify\.?ai|@creatify/i;          // <-- set per competitor
  const byCard = new Map();                          // card element → chosen candidate
  for (const c of candidates) {
    const { card, text } = cardOf(c.node);
    if (!card) continue;
    if (!BRAND.test(text)) continue;
    const prev = byCard.get(card);
    // prefer video over image when both exist on the same card
    if (!prev || (prev.kind === 'image' && c.kind === 'video')) {
      byCard.set(card, { ...c, text });
    }
  }

  // 5. de-dupe near-identical recurring creatives by card text prefix
  const seen = new Set();
  const kept = [];
  for (const c of byCard.values()) {
    const key = c.text.slice(0, 80);
    if (seen.has(key)) continue;
    seen.add(key);
    kept.push(c);
  }

  // 6. download up to N (recurring creatives appear first → already spend-weighted)
  const N = 5;                                       // <-- set to requested count
  const picks = kept.slice(0, N);
  const results = [];
  for (let i = 0; i < picks.length; i++) {
    const p = picks[i];
    try {
      const b = await (await fetch(p.url)).blob();
      let ext;
      if (p.kind === 'video') {
        ext = 'mp4';
      } else {
        ext = (b.type && b.type.includes('png')) ? 'png' : 'jpg';
      }
      const a = document.createElement('a');
      a.href = URL.createObjectURL(b);
      a.download = `spy-ad-${i + 1}-COMPETITOR.${ext}`;  // <-- set competitor slug
      document.body.appendChild(a); a.click(); a.remove();
      results.push({ i: i + 1, kind: p.kind, bytes: b.size, ext });
    } catch (e) { results.push({ i: i + 1, error: String(e) }); }
  }
  return results;
})()
```

If a fetch fails (expired/geo-blocked), it's skipped automatically — just move to the next card. No mention to the user.

---

## Step 4 — Collect files and deliver

After downloading, move the files out of the browser's Downloads folder to `/tmp/` with the Bash tool, in one command. Pick the glob that matches the mode you ran:

**VIDEO mode:**
```bash
cd ~/Downloads && mv -f spy-ad-*.mp4 /tmp/ && ls -la /tmp/spy-ad-*.mp4
```

**IMAGE mode:**
```bash
cd ~/Downloads && mv -f spy-ad-*.jpg spy-ad-*.png /tmp/ 2>/dev/null; ls -la /tmp/spy-ad-*.{jpg,png} 2>/dev/null
```

**BOTH mode (image + video):**
```bash
cd ~/Downloads && mv -f spy-ad-*.mp4 spy-ad-*.jpg spy-ad-*.png /tmp/ 2>/dev/null; ls -la /tmp/spy-ad-*.{mp4,jpg,png} 2>/dev/null
```

Then deliver — **only the files, no analysis, no commentary, no brief**. Present each creative inline if a preview tool is available; otherwise list them as clickable file links:

> - [spy-ad-1-creatify-ai.mp4](/tmp/spy-ad-1-creatify-ai.mp4)
> - [spy-ad-2-captions.mp4](/tmp/spy-ad-2-captions.mp4)

…in IMAGE mode:

> - [spy-ad-1-creatify-ai.jpg](/tmp/spy-ad-1-creatify-ai.jpg)
> - [spy-ad-2-creatify-ai.jpg](/tmp/spy-ad-2-creatify-ai.jpg)

…in BOTH mode (videos and images interleaved by rank):

> - [spy-ad-1-creatify-ai.mp4](/tmp/spy-ad-1-creatify-ai.mp4)
> - [spy-ad-2-creatify-ai.jpg](/tmp/spy-ad-2-creatify-ai.jpg)
> - [spy-ad-3-creatify-ai.mp4](/tmp/spy-ad-3-creatify-ai.mp4)

Do not append observations, patterns, recommendations, or written analysis. The only thing that may follow this delivery is the Step 5 "clone which?" form — and only when this skill ran standalone.

---

## Step 5 — Offer to clone (standalone runs only)

This step **only fires when arcads:spy-competitor-ads was invoked directly by the user as the end goal**, not when it was triggered as a sub-step by another skill. Detect the situation before running it:

**Skip Step 5 (do NOT show the form) when any of these is true:**
- The current invocation was triggered by another skill — most commonly `arcads:clone-hook` (Step 1B auto-source) or `arcads:clone-static-ad` (Step 1B auto-source). Those skills will consume the downloaded files themselves; offering to clone again would loop.
- The original user request was explicitly research-only — "just download competitor ads", "build me a swipe file", "save these for me", "I want to look at them".
- Zero creatives were delivered in Step 4.

**Run Step 5 (show the form) otherwise**, including when the user's request was ambiguous-but-actionable like "spy on competitors and let me work from there", "find competitor ads I can use as inspiration", or a bare "find competitor ads from [brand]". When in doubt, run it — declining is one click for the user.

### The form

Surface every delivered creative as a separate option in a single `AskUserQuestion` call with `multiple: true`:

> **Question**: "Want me to clone any of these for your brand? Pick the ones to recreate — I'll rebuild each for you."
> **Header**: "Clone which?"
> **Multiple**: `true`
> **Options**: one per delivered file, in the same order they were listed in Step 4. Each option's `label` is the short filename without the leading slug (e.g. "Ad #1 — BrandX (video)" or "Ad #3 — BrandY (image)"). Each option's `description` is one short cue from the card text if you have it (e.g. "Talking-head selfie, 22s"), or just the file type if you don't.

The `custom` default option ("Type your own answer") lets the user say "all of them", "none — I'm done", or a custom note.

### Routing each selection

Walk the user's selection in the order they were picked. For each chosen file:

1. **Video file (`.mp4`)** → load and run the `arcads:clone-hook` skill, passing the local `/tmp/spy-ad-*.mp4` path as the source video (skipping its Step 1B auto-source, since you already have a video). `arcads:clone-hook` will analyze the hook, then (after its own confirmation prompt) clone it for the user's brand.
2. **Image file (`.jpg` / `.png`)** → load and run the `arcads:clone-static-ad` skill, passing the local `/tmp/spy-ad-*.{jpg,png}` path as the reference static ad (skipping its Step 1B auto-source, since you already have an image). `arcads:clone-static-ad` will analyze the layout and clone it for the user's brand.

Run the chained skills **sequentially** (not in parallel) — each one needs the user's attention for brand/asset questions, and parallel runs would collide. After each chained skill finishes, move to the next selected file.

If the user picks just one creative, hand off immediately without re-confirming. If they pick "none", stop cleanly — no chaining, no further commentary. If they pick "all of them", chain through every delivered file in order.

### Carry brand context forward

The downstream skills (`arcads:clone-hook`, `arcads:clone-static-ad`) will ask for the user's brand, product, and assets. If the user already gave that information during Step 1a or in the original request, pass it forward — don't make them re-answer.

---

## Edge cases

- **No ads of the requested mode found for a competitor** → skip silently, continue with the rest. If *no* competitor yields any creative in the chosen mode, say so briefly and stop. Do **not** silently fall back to a different mode — the user picked VIDEO, IMAGE, or BOTH for a reason.
- **BOTH mode but only one media type returns** (e.g. competitor runs only videos): deliver what you got and say briefly "BrandX is only running videos right now — no statics in their library." Do not pad with the missing format.
- **Only same-name/unrelated ads found** → treat as "no ads found" for that competitor; skip silently.
- **Browser not connected** → the only blocking case; see Step 2.
- **User dismisses the mode form** (Step 1b) or doesn't pick a mode → stop and say "I need to know which kind of ads to grab — video, image, or both." Do not guess.
- **User deselects every competitor** in the Step 1c multi-select → ask once for a manual list ("Which competitors should I look at instead?"). If still empty, stop.
- **User picks "none" in the Step 5 clone form** → stop cleanly. No commentary, no follow-up.
- **User picks one creative in Step 5** → hand off to the matching cloner skill (`arcads:clone-hook` for video, `arcads:clone-static-ad` for image) without an extra confirmation.
- **Step 5 chain — one of the cloner skills fails or is cancelled by the user** → stop the chain (do not run the remaining selections silently). Surface what happened in one line and let the user restart the chain if they want.
- **Invoked from inside another skill** (e.g. `arcads:clone-hook` auto-source) → skip Step 5 entirely. The calling skill owns the next step.

---

## Quick reference

| Tool | Where |
|---|---|
| `AskUserQuestion` | Step 1b — pick media mode (when not explicit). Step 1c — multi-select competitor shortlist (when auto-discovered). Step 5 — multi-select "clone which?" (standalone runs only). |
| `WebSearch` / `WebFetch` | Step 1c — auto-find competitors (only if not named) |
| Browser MCP (`mcp__Claude_in_Chrome__*` / Playwright) | Steps 2–3 — open Ad Library, run extract+download JS |
| `javascript_tool` (in-page `fetch`→blob→download) | Step 3 — the ONLY reliable download path; curl does not work. Pick the extractor that matches the mode: `<video>` for VIDEO, `<img>` for IMAGE, combined for BOTH. |
| `Bash` (`mv`) | Step 4 — move files from Downloads to `/tmp/` (`.mp4` for VIDEO, `.jpg`/`.png` for IMAGE, both for BOTH) |
| `arcads:clone-hook` skill | Step 5 — chained per selected video, passing the local `/tmp/spy-ad-*.mp4` path |
| `arcads:clone-static-ad` skill | Step 5 — chained per selected image, passing the local `/tmp/spy-ad-*.{jpg,png}` path |
