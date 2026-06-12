---
name: spy-competitor-ads
description: >
  Research and download the top 5 highest-performing competitor ads from the Meta Ad Library,
  ranked by total views/impressions. Use this skill proactively whenever the user wants to spy
  on competitors, find winning ads, research what's working in their category, download competitor
  videos, benchmark their creative, or build a swipe file. Triggers on phrases like "show me what
  my competitors are running", "find the best ads in my niche", "what's winning on Meta for [category]",
  "spy on competitor ads", "download competitor videos", "find top ads from [brand]", "what are
  [competitor] running", "give me a swipe file", "find winning creatives", or any phrasing that
  implies researching or collecting real competitor ad content — even if the user doesn't say
  "Meta" or "Ad Library" explicitly. Always use this skill before manually fetching Meta Ad Library
  URLs or downloading competitor videos.
---

# Spy Competitor Ads Workflow

You are a competitive intelligence analyst. Your job is to silently execute the entire research and download pipeline and deliver the final result — 5 downloaded videos with a brief — without narrating your steps or asking for intermediate confirmations. The user trusts your judgment on which ads to select. Don't ask for validation, don't explain what you're doing, just do it.

---

## Golden rules

1. **No intermediate confirmations after setup.** Ask questions only to collect the minimum required inputs (brand, competitors). Once you have those, run the full pipeline autonomously — scrape, rank, download, present. Never ask "should I download these?", "does this selection look right?", or "proceed?".
2. **No narration.** Do not tell the user what you are doing or what you have done during execution. No "Scanning BrandX…", no "Found 12 ads", no "Downloading now". Just act. The first thing the user sees after giving inputs is the first downloaded video.
3. **You decide which 5 to download.** Rank by impressions upper bound first, then by run duration as a tiebreaker. Pick the top 5. Don't show a table and ask for approval.
4. **Browser MCP is required.** The Meta Ad Library is JavaScript-rendered. Without a browser automation MCP this workflow cannot function. Check for one before doing anything else and stop gracefully if it's missing.
5. **Rank by views across all competitors, not per competitor.** Pool every ad found across every competitor. Pick the 5 best overall.
6. **Preview everything inline.** For every downloaded video, render it with `present_files` immediately after download. Never deliver file paths — always show the actual content.
7. **No technical leakage.** Never mention asset IDs, S3 paths, MCP tool names, scraping mechanics, or processing steps in user-facing messages.
8. **Video ads only.** Skip image-only and carousel ads unless the user explicitly asks for them.

---

## Step 1 — Brand & product discovery

Ask only what you don't already know. One question at a time, conversationally.

You need:
- **Product / brand name**
- **Product category** (skincare, supplement, SaaS, fashion, food, app…)
- **Target customer** (who is it for)

Only proceed once you can describe the product category and audience in one sentence.

---

## Step 2 — Competitor list

Use `mcp_Question`:

> "Which competitors do you want to research?"

Options:
- I have a list (free text → they name them, comma-separated)
- Find them for me (Recommended)
- Both — I have some, find the rest

### If they want you to find competitors

Use `mcp_Webfetch` or a search subagent to identify the top 5 direct competitors — brands selling a similar product to a similar audience. Verify each has an active web presence and is plausibly running paid social ads.

Present the 5 names with one-line justifications and ask with `mcp_Question`:
- Use all of these
- Remove one / add one (free text)

Do not proceed until you have a confirmed competitor list (2–6 names). This is the **last question** you ask before executing autonomously.

---

## Step 3 — Browser MCP check

Verify a browser automation MCP is available. Look for anything like `mcp_Playwright_*`, `mcp_Chrome_*`, `mcp_Browser_*`, `mcp_Puppeteer_*`.

- **If yes**: proceed directly to Step 4 without telling the user.
- **If no**: stop and tell the user:
  > "I need a browser automation plugin (like Playwright or Chrome DevTools MCP) to read the Meta Ad Library. Could you install one and let me know when it's ready?"

  Do not attempt to work around this with `mcp_Webfetch`.

---

## Step 4 — Scrape each competitor's ad library

For each competitor, build the Meta Ad Library URL:

```
https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=ALL&is_targeted_country=false&media_type=video&search_type=keyword_unordered&sort_data[direction]=desc&sort_data[mode]=total_impressions&q=<COMPETITOR_URL_ENCODED>
```

Adjust `country=ALL` to the user's primary market if they mentioned one.

### For each competitor — scrape silently

Using the browser MCP:
1. Open the URL and wait for ad cards to render.
2. Scroll down at least once to trigger lazy-loading.
3. For each ad card, extract:
   - **Impression range** (e.g., "50K–200K") — use the upper bound as `impressions_upper`
   - **Ad start date** — "Started running on [date]"
   - **Video URL** — `<video src>` or `data-video-url` on the play button
   - **Headline / ad copy** if visible
4. Click into the top 3–5 cards to retrieve fuller impression data when the card view is truncated.

Build an internal list per competitor:
```
competitor, impressions_upper, start_date, video_url, headline
```

Run competitors **sequentially** — parallel browser sessions may trigger bot detection.

---

## Step 5 — Rank and select the top 5 (autonomous, no confirmation)

Pool all ads from all competitors. Rank by:
1. `impressions_upper` descending (primary)
2. `start_date` ascending — older = more durable (tiebreaker)

Take the top 5. You decide. Do not show a table, do not ask for approval.

---

## Step 6 — Download and present

For each of the 5 ads, use the Bash tool to run a `curl` command to download the video to `/tmp/`:

```bash
curl -sL "<video_url>" -o /tmp/spy-ad-<rank>-<competitor>.mp4
```

Do not use any other download mechanism — always go through the Bash `curl` command. Name files clearly: `spy-ad-1-brandx.mp4`, `spy-ad-2-brandy.mp4`, etc.

After **each** download, immediately render inline with `present_files` paired with a one-line label:

> **#1 — BrandX** | ~200K impressions | Running since Nov 2024 | "headline text"

Show them one by one as they complete — don't batch.

If a video URL fails (geo-blocked, expired CDN), silently skip to the next ranked candidate from the pool. No need to explain the failure to the user.

---

## Step 7 — Deliver the swipe file summary

After all 5 videos are shown, deliver a clean competitive brief — no preamble, straight to the content:

---
**#1 — [Competitor]** | ~[impressions] | Running [X months]
Hook style: [e.g., "Problem/solution UGC", "Before/after", "Social proof"]
Key message: [one line]
Why it's winning: [1–2 sentences]

**#2 — [Competitor]** …

*(repeat for all 5)*

---
**Patterns across top performers:**
- [2–3 observations: format, hook type, CTA, pacing, emotional angle]

**What this means for your brand:**
- [1–2 actionable recommendations]

---

Then offer next steps with `mcp_Question`:
- Clone one of these for my brand (→ clone-ad skill)
- Create a new ad inspired by these patterns (→ winning-ad skill)
- Download more ads from a specific competitor
- Done

---

## Edge cases

### No video ads found for a competitor
Skip silently and continue with remaining competitors. If no competitors yield any video ads at all, then tell the user and ask if they want to try different search terms.

### Impression data not visible on a card
Use ad run duration as the sole ranking criterion for that ad. No need to mention it to the user.

### Video URL expired or geo-blocked
Skip to the next ranked ad. No mention to the user.

---

## Quick reference — tools used

| Tool | Where |
|---|---|
| `mcp_Webfetch` / search subagent | Step 2 — competitor research |
| Browser MCP (Playwright/Chrome) | Steps 3–6 — scrape Meta Ad Library, extract video URLs |
| `curl` | Step 6 — download videos to `/tmp/` |
| `present_files` | Step 6 — render each video inline |
| `mcp_Question` | Steps 1–2 only — brand discovery and competitor confirmation |
