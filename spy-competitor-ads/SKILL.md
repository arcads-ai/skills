---
name: spy-competitor-ads
description: >
  Find and download competitor video ads from the Meta Ad Library. Use this skill proactively
  whenever the user wants to spy on competitors, find competitor ads, download competitor videos,
  grab winning creatives, or build a swipe file. Triggers on phrases like "download competitor
  ads", "spy on competitor ads", "find ads from [brand]", "what are [competitor] running",
  "grab competitor videos", "give me a swipe file", or any phrasing that implies collecting real
  competitor ad content — even if the user doesn't say "Meta" or "Ad Library" explicitly. Always
  use this skill before manually fetching Meta Ad Library URLs or downloading competitor videos.
---

# Spy Competitor Ads — Find & Download

Your only job: **find competitor ads and download them.** Nothing else. Execute the whole pipeline silently and the user's first output is the downloaded videos themselves.

---

## Golden rules

1. **Silent execution. No narration, no logging.** Never say what you are doing or have done — no "Searching…", "Found 12 ads", "Downloading…", "Moving files…". No status lines, no step commentary. The user sees only the final downloaded videos.
2. **No questions, no confirmations.** Don't ask "which competitors?", "proceed?", or "does this look right?". Decide everything yourself. The only exception is in Step 1 below.
3. **No analysis.** Do NOT analyze the videos, describe hooks, summarize messaging, rank by "why it's winning", or write a competitive brief. Do not profile the competitors. Just find and download.
4. **Auto-find competitors when not given.** If the user names competitors, use them. If not, find them yourself and proceed immediately — no list to confirm.
5. **No technical leakage.** Never mention CDN URLs, asset IDs, MCP tool names, scraping mechanics, or file-move steps.
6. **Video ads only.** Skip image and carousel ads.
7. **Browser MCP is required.** The Meta Ad Library is JavaScript-rendered. If no browser automation MCP is connected, that is the one thing you stop and report (Step 2).

---

## Step 1 — Resolve the brand & competitors (fast, ≤1 question)

- **Competitors named?** → use them. Skip straight to Step 2.
- **Not named?** → infer the user's brand from the request and conversation context. Then find 2–3 direct competitors yourself with a quick `WebSearch`/`WebFetch` (brands selling a similar product to a similar audience that plausibly run paid social). Do **not** present or confirm the list — just use them.
- **Brand genuinely unknown and not inferable?** → ask exactly one short question: "What's your brand or product?" Nothing else. Once answered, proceed autonomously.

Default count: top **5** ads pooled across all competitors. If the user specified a number ("2 ads", "one each"), honor it exactly.

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

For each competitor, build the URL:

```
https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=ALL&is_targeted_country=false&media_type=video&search_type=keyword_unordered&sort_data[direction]=desc&sort_data[mode]=total_impressions&q=<COMPETITOR_URL_ENCODED>
```

Use the user's primary market for `country=` if they mentioned one, else `ALL`.

Then, for speed, do everything in as few calls as possible — **navigate, wait briefly, then one JavaScript call** that scrolls, extracts, filters, and downloads:

### Critical technical facts (learned the hard way)

- **`curl` does NOT work.** The browser extension masks Meta CDN video URLs (they carry cookie/query-string/JWT tokens), so the raw `src` is never returned to you and an external `curl` has no valid URL. **Download in-page instead**: `fetch(src)` → `blob()` → temporary `<a download>` → `click()`. This saves to the browser's Downloads folder. You never need to see the URL.
- **Keyword pollution is common.** A search for a brand often returns an unrelated company with the same name (e.g. "Creatify" the AI tool vs. "Creatify.mx" a sticker shop). Inspect each card's advertiser name / domain / copy and keep only cards that match the real competitor. Drop the rest.
- **Impressions are hidden** for commercial (non-political) ads. Don't rank by impressions. Instead prefer the **most-recurring creative** (many near-identical live copies = highest spend = proven winner), then most recent. Pick the top N by that heuristic.

### One-shot extract + download script (adapt per competitor)

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

If a fetch fails (expired/geo-blocked), it's skipped automatically — just move to the next card. No mention to the user.

---

## Step 4 — Collect files and deliver

After downloading, move the files out of the browser's Downloads folder to `/tmp/` with the Bash tool, in one command:

```bash
cd ~/Downloads && mv -f spy-ad-*.mp4 /tmp/ && ls -la /tmp/spy-ad-*.mp4
```

Then deliver — **only the files, no analysis, no commentary, no brief**. Present each video inline if a preview tool is available; otherwise list them as clickable file links:

> - [spy-ad-1-creatify-ai.mp4](/tmp/spy-ad-1-creatify-ai.mp4)
> - [spy-ad-2-captions.mp4](/tmp/spy-ad-2-captions.mp4)

That's the end. Do not append observations, patterns, recommendations, or next-step offers.

---

## Edge cases

- **No video ads found for a competitor** → skip silently, continue with the rest. If *no* competitor yields any video, say so briefly and stop.
- **Only same-name/unrelated ads found** → treat as "no ads found" for that competitor; skip silently.
- **Browser not connected** → the only blocking case; see Step 2.

---

## Quick reference

| Tool | Where |
|---|---|
| `WebSearch` / `WebFetch` | Step 1 — auto-find competitors (only if not named) |
| Browser MCP (`mcp__Claude_in_Chrome__*` / Playwright) | Steps 2–3 — open Ad Library, run extract+download JS |
| `javascript_tool` (in-page `fetch`→blob→download) | Step 3 — the ONLY reliable download path; curl does not work |
| `Bash` (`mv`) | Step 4 — move files from Downloads to `/tmp/` |
