# Clippings — Product Requirements Document

**Status:** Draft (v1 / MVP)
**Name:** Clippings *(working title — provisional, descriptive mark; revisit before any commercial launch)*
**Platform:** iOS (iPhone), Apple-only
**Last updated:** June 10, 2026
**Owner:** [you]

---

## 1. Summary

Clippings is an iOS utility that turns a screenshot of social media content into a clean, well-formatted, shareable item — and sends it onward to specific people who aren't on that platform. The core loop is: **screenshot → Share sheet → Clippings → reformat → send.** It exists so the people who *aren't* on Instagram/TikTok/etc. (often parents and grandparents) don't miss the content their family is posting.

The MVP is intentionally a single, tight loop. The premium/automation vision (library auto-detection, multi-recipient sending, cross-platform adapters) is explicitly deferred to keep v1 shippable and to make a clean "shipped, then iterated" narrative.

---

## 2. Background & Problem

Social platforms are walled gardens. Content posted to Instagram or TikTok is effectively invisible to anyone not on that app, which disproportionately excludes older relatives. The current workaround is universal and clumsy: people screenshot a post and text it over. That works, but it loses the caption context, looks messy, requires several manual steps, and has to be repeated per recipient.

There is no dedicated tool for *reformatting and forwarding* this kind of content to non-platform people. The act is common enough to be a habit, annoying enough to be a real (if mild) pain, and unowned in the market.

### Why this is worth building
- The behavior already exists at scale (everyone screenshots-and-texts).
- The pain is small per instance but high in frequency.
- It demonstrates real technical breadth (share extensions, on-device ML/OCR, image handling, privacy-first design) — valuable as a portfolio piece independent of commercial outcome.

---

## 3. Goals & Non-Goals

### Goals (v1)
- Deliver one frictionless, demoable loop from screenshot to shared output.
- Make formatting genuinely useful: preserve image quality *and* recover caption text.
- Keep everything on-device; collect no user data.
- Ship to the App Store and clear review.

### Non-Goals (v1)
- No multi-recipient / bulk sending automation.
- No automatic photo-library scanning or notifications.
- No cross-platform adapters (TikTok, Snapchat, Facebook, news articles).
- No video/Reels/Stories motion capture.
- No backend, no accounts, no cloud sync.

---

## 4. Target Users

This is a **sender-side** product. The user is the person doing the sharing; the recipient is a passive beneficiary.

- **Primary user (the sender):** A younger, social-media-native person who regularly sees content they want to pass to a non-platform relative. Comfortable with screenshots and the Share sheet. Wants this to take seconds.
- **Secondary beneficiary (the recipient):** A parent or grandparent not on the source platform. Receives a clean image and/or readable text via a channel they already use (Messages, email). Does **not** install or learn anything.

---

## 5. Competitive Landscape

- **Postie (trypostie.com):** Mails *physical* postcards from phone photos; pitches itself as "offline social media" for grandparents. Same emotional positioning, different mechanism (print + mail, paid). Clippings' edge: instant, digital, free, multi-format.
- **SnipShot (App Store):** Uses on-device AI to OCR screenshots and auto-organize them into categories. Overlaps with Clippings' *capture/OCR* side but is an organizer, not a reformat-and-forward tool.
- **Generic screenshot beautifiers (NexSnap, etc.):** Style screenshots for marketing/social posting — opposite direction (posting *to* social, not extracting *from* it).

**Takeaway:** Pieces of the idea exist; the specific combination (reformat a social screenshot + recover its caption + forward to non-platform people) is unoccupied.

---

## 6. Product Scope — v1

### The core loop
1. User screenshots a post/story.
2. From Photos (or any app), user taps **Share** and selects **Clippings**.
3. The Clippings share extension opens as a full UI sheet (not just a menu row).
4. User picks a **format**:
   - **Raw** — the screenshot as-is.
   - **Split** — image preserved + caption extracted as selectable/sendable text.
5. Optional lightweight **crop** and **quality/format export** controls.
6. User taps to **export via the system Share sheet** to one destination (Messages thread, email, etc.).

### Featured capability — the ML moment
On-device **OCR (Apple Vision)** automatically detects and extracts the caption/text from the screenshot, powering the "Split" format. This is the headline technical feature and the thing that makes Split worth choosing over Raw.

### Supporting feature — format/quality export
Crop to content, and export at a chosen format/quality. This is the "overlooked use case" — a genuinely useful general-purpose tool that also satisfies App Store *minimum functionality* expectations (a one-button reshare alone risks a thin-app rejection).

---

## 7. Out of Scope — v2+ (the iteration story)

- **Library auto-detection + notification:** scan for screenshots (and, deeper, classify them as social media) and proactively prompt the user to forward.
- **App Intents / Shortcuts actions:** preconfigured one-tap flows for power users (e.g., "Split + email to family") that sit alongside the in-app UI.
- **Multi-recipient sending** (subject to platform constraints — see §9).
- **Cross-platform adapters** and **news-article / long-content stitching**.

---

## 8. User Stories (v1)

- *As a sender,* I can invoke Clippings directly from the Share sheet so I don't have to open a separate app first.
- *As a sender,* I can choose whether the recipient gets the raw screenshot or a clean image-plus-text version.
- *As a sender,* I can have the caption pulled out automatically instead of retyping it.
- *As a sender,* I can crop and control the output quality before sending.
- *As a sender,* I can send the result through whatever channel my recipient already uses.
- *As a privacy-conscious user,* I can trust that nothing leaves my device.

---

## 9. Constraints & Risks

- **No programmatic bulk/individual texting (hard platform limit).** iOS does not allow sending texts silently or to multiple individual threads programmatically; you can only pre-fill the Messages composer one thread at a time. This directly caps the "automation is premium" vision and is why v1 sends one destination at a time via the system Share sheet. Email-based fan-out is the realistic path for any future multi-send and would require a backend.
- **App Store minimum-functionality bar.** A thin reshare tool risks rejection; the crop/format/export feature is the mitigation.
- **Photo-library permission scrutiny.** Purpose strings must be specific; request the narrowest access that works (prefer the limited picker).
- **Share-extension resource limits.** Extensions run under tight memory budgets — relevant to image processing (see System Design).
- **Brand risk (low for MVP).** "Clippings" is descriptive and unprotectable; fine for a portfolio project, weak for a commercial launch.

---

## 10. Success Criteria

Because this is primarily a portfolio/learning project, success is defined accordingly:

- **Must:** Ships to the App Store; the full loop works reliably; OCR is accurate on typical IG/TikTok screenshots; nothing is collected (clean privacy label).
- **Nice:** Real people (friends/family) actually use it; demoable in under 30 seconds in an interview; clean enough code/architecture to discuss in a system-design conversation.
- **Stretch:** One v2 capability (library detection *or* a Shortcuts action) added post-launch to demonstrate iteration.

---

## 11. Rough Milestones

1. **Setup** — Developer Program enrollment, signing, project skeleton. *(Mostly waiting on Apple.)*
2. **Core loop** — Share extension + UI sheet + Raw/Split formats + Vision OCR.
3. **Polish** — Crop + quality/format export, error states, empty/edge cases.
4. **Store prep** — Icon, screenshots, description, privacy label, privacy policy.
5. **Submit + iterate** — Expect 1–2 revision cycles on first review.

*Rough calendar estimate at part-time pace: ~1 month to live, of which only ~2 weeks is active building; the rest is waiting on Apple and revisions.*

---

## 12. Open Questions

- Final name + App Store display string (likely "Clippings — [tagline]").
- Should crop/quality export ship in v1 or be the first v1.1 add? (Leaning **in**, for the functionality bar and because it's the most broadly useful piece.)
- Which v2 capability becomes the headline iteration?
