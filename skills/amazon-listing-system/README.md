# Arcads Amazon Listing System — README

This is the human guide that sits on top of `SKILL.md`. The skill is the machine
brain (what Claude does); this README is the setup + run + post-generation playbook
(what you do).

**What it does:** you give Claude one product URL + one product photo. Claude
researches the buyer angles, then generates a full Amazon listing image set through
the Arcads connector — 5 angles x 5 image types (Hero, Benefits, Ingredients,
Lifestyle, Reviews) = up to 25 finished, brand-consistent images. You upload them to
Amazon and let the carousel rotation find the winning angle.

---

## Setup (one time)

1. **Enable Code Execution.** Settings -> Capabilities -> turn on "Code execution
   and file creation." Skills don't run without it.
2. **Upload the skill.** Customize -> Skills -> upload `amazon-listing-system.zip`,
   then toggle it on.
3. **Connect the Arcads connector.** Settings -> Connectors -> add Arcads and
   authenticate. (This is the step that matters most — see "Honest limits" below.)
4. **Turn web search on** (and a scraping connector like Firecrawl if you have one —
   it deepens the review research).

## Run it (per product)

1. Open a chat (with the Arcads connector enabled for that conversation).
2. Paste the product URL and attach the product photo. (Optional but recommended: paste
   a few real review excerpts — quote + first name — so the Reviews image can be built.)
   Say something like *"Run the Amazon listing system for this product."*
3. Approve the research brief and the top 5 angles.
4. Approve the 25-image plan. Claude generates and finishes them via Arcads.
5. Download the images.

## What you get

Up to 25 images: each of 5 buyer angles rendered as Hero / Benefits / Ingredients /
Lifestyle / Reviews. The Hero is a pure-white-background main image; the rest are
brand-palette secondary images with their marketing text burned on crisply.

---

## After generation — deploy to Amazon

Amazon's main carousel holds ~7-9 images; A+ Content holds the rest.

- Put the **strongest-predicted angle's full stack** in the main 7 carousel slots.
- Use **A+ Content modules** for the other angles' stacks.
- If the listing has **SKU variants** (flavors/sizes), give each variant a different
  angle's primary stack to test angles at the SKU level.

## Read the winner

Amazon rotates images by session data — that rotation is your free A/B test. After
7-14 days, check:

- **Brand Analytics** — search-query CTR per image.
- **Helium 10 / Jungle Scout** — image rotation tracking.
- **Conversion rate by image variant.**

When one angle beats the others by ~20%+ on CTR + conversion, move its full stack to
the primary carousel, feature it in A+ Content, and weight the next refresh toward it.
Feed confirmed winners back so the next angle map gets sharper.

## Weekly cadence

- **Mon:** run 1-2 products (URL + photo -> approve angles -> generate 25).
- **Tue:** upload to Amazon (carousel + A+ Content).
- **+7 days:** first data check.
- **+14 days:** confirm winner, reinforce in the primary carousel.

---

## Troubleshooting

- **Images came out with no text.** Text is rendered by the image model in one shot,
  so this means a render missed it — regenerate that image, keep the on-image text
  short, or switch to a model stronger at text (gpt-image-2 / nano-banana-2).
- **"Arcads tools aren't available."** The connector isn't enabled for this chat —
  connect Arcads and toggle it on via the "+" in the chat.
- **Product label looks off.** Make sure the product photo is actually attached; it's
  the reference on every generation. Try a cleaner, higher-res photo.
- **Reviews image looks generic / has no quotes.** Real review excerpts couldn't be
  retrieved, so the skill correctly refused to fabricate them. Paste a few real
  reviews into the chat and re-run the Reviews image.
- **Text is garbled on a chart.** Regenerate that single image; keep the text short.
- **Angles feel generic.** Paste 15-20 recent reviews into the chat to feed Step 0.

## Honest limits

- **Arcads plan.** Every user needs an Arcads account with MCP/connector access.
  Confirm which Arcads tier exposes the connector before handing this out — it's the
  real cost floor, not the Claude side.
- **Review scraping.** Amazon blocks scrapers, so deep review mining is hit-or-miss.
  Without it, angles come from positioning + category pains (still good), and the
  Reviews image needs you to paste real quotes.
- **You upload to Amazon.** The skill produces images; deploying to Seller Central and
  reading analytics stay manual.
