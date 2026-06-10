# Clippings — System Design

**Companion to:** Clippings PRD (v1 / MVP)
**Platform:** iOS 17+ (iPhone), Swift / SwiftUI *(floor raised from 16 — negligible user cost by launch, simplifies SwiftUI/Vision API choices)*
**Last updated:** June 10, 2026
**Scope:** Technical design for the v1 loop, with v2 hooks noted but not specified.

---

## 1. Overview

Clippings is a fully **on-device, no-backend** iOS app. It ships as **two targets that share one framework**:

- **Container app** — the standalone app users see on the Home Screen. Hosts the **full flow** (PHPicker import → Raw/Split + crop + export), an onboarding/"how it works" screen, and settings. Reviewers open the container app first, so it must demonstrate the product on its own.
- **Share extension** — the heart of the product. Invoked from the system Share sheet on a screenshot; presents the formatting UI and performs OCR.
- **Shared framework ("ClippingsKit")** — common code used by both targets, packaged as a **local Swift package**: the data model, OCR service, image-formatting logic, and export helpers. Avoids duplication and keeps logic testable in isolation.

There is no server, no account system, and no network calls. All processing happens locally.

```
┌─────────────────────────────────────────────┐
│                  iOS Device                   │
│                                               │
│  ┌───────────────┐      ┌──────────────────┐ │
│  │ Container App │      │  Share Extension  │ │
│  │  (Home Screen)│      │ (from Share sheet)│ │
│  └───────┬───────┘      └─────────┬────────┘ │
│          │                        │           │
│          └──────────┬─────────────┘           │
│                     ▼                          │
│            ┌──────────────────┐                │
│            │   ClippingsKit   │                │
│            │  ─ Data model    │                │
│            │  ─ OCR service   │                │
│            │  ─ Formatter     │                │
│            │  ─ Export helper │                │
│            └────────┬─────────┘                │
│                     ▼                          │
│   Apple Vision · PhotoKit · UIActivityVC       │
└─────────────────────────────────────────────┘
```

---

## 2. Core Flow (v1)

1. **Invocation.** User taps Share on a screenshot and selects Clippings. iOS hands the extension the image via its `NSExtensionContext` input items. The extension is declared to accept image content types (UTType `public.image`) with `NSExtensionActivationSupportsImageWithMaxCount` set high enough (e.g. 10) that Clippings still appears when multiple images are selected; the extension processes the **first** image and shows a one-line notice that one image is handled at a time.
2. **Presentation.** The extension renders a **custom view controller hosting a SwiftUI sheet** — not the default compose view. This is what gives the "real interface" feel.
3. **OCR.** On load, the formatter kicks off a Vision text-recognition request on the image. Detected text is surfaced as the editable caption for the "Split" format.
4. **Format selection.** User chooses **Raw** (pass image through unchanged) or **Split** (image + extracted text). Optional crop and quality/format adjustment.
5. **Export.** The formatted output is handed to a `UIActivityViewController` (the system Share sheet) for delivery to a single destination. **Raw** exports one image item; **Split** exports **two activity items** — the image and the caption as plain text. Messages and Mail accept both; some third-party destinations accept only one item and may drop the text (a composite single-image renderer is the v2 answer for those). The extension completes its request only after the activity controller's completion handler fires.

---

## 3. Key Technical Decisions

### 3.1 Share extension UI
iOS share extensions are **not** limited to a small menu — a `UIViewController` subclass can present arbitrary UI, and SwiftUI can be embedded via `UIHostingController`. Decision: build the formatting experience entirely inside the extension so the user never has to open the container app first. This is the single most important UX decision in the product.

### 3.2 On-device OCR (the ML moment)
Use the **Vision** framework (`VNRecognizeTextRequest`, accurate recognition level) for caption extraction. Rationale:
- Runs fully on-device — no network, supports the privacy story.
- High accuracy on rendered UI text (which IG/TikTok captions are).
- No model to train, bundle, or version for v1.

Vision returns observations in layout order, which does not reliably match reading order on a screenshot full of interleaved UI elements (username, caption, comments, timestamps). v1 applies a **vertical-position sort** (top-to-bottom, then left-to-right within a line band) before joining observations into the caption block, and the fixture tests assert ordering — not just recall. The user can edit the result before sending. Smarter layout heuristics (e.g., stripping UI chrome like usernames/like counts) are a v2 refinement, not a v1 requirement. If no text is detected, Split is disabled with a short explanation and the user proceeds with Raw + crop.

### 3.3 Image formatting & export
Formatting (crop, choose output type) is standard Core Graphics / `UIImage` work in ClippingsKit. v1 output types are **JPEG and PNG**; a quality/compression slider is deferred to v2. Exported images are **re-encoded without source metadata** (no EXIF/location travels with the share). Export goes through `UIActivityViewController`, which deliberately:
- Respects platform rules (no silent/bulk send — see §6).
- Gives the user every channel they already have (Messages, Mail, AirDrop, etc.) for free.

**Known risk:** presenting `UIActivityViewController` *from inside a share extension* is historically fragile (certain activities misbehave; completion/dismissal ordering with `completeRequest` is fiddly). This is validated as the first build task (see development roadmap, Phase 1 spike). Fallback if unacceptable: hand off to the container app via the App Group.

### 3.4 Photo access model
v1 does not need broad library access — the image arrives through the Share sheet. Where the container app offers direct import, prefer the **limited photo picker (PHPicker)**, which requires no full-library permission prompt and keeps the privacy label clean. Full-library access is a **v2** concern (auto-detection only).

### 3.5 No backend / no data collection
Everything is local. The privacy nutrition label declares **no data collected**, which is both honest and a selling point. This also removes an entire class of review risk and infrastructure cost.

---

## 4. Data Model (lightweight)

A single in-memory value type represents the working item; nothing is persisted server-side, and little is persisted locally beyond user defaults.

```
Clipping
 ├─ sourceImage: image data (from the share context)
 ├─ extractedText: String?        // from Vision OCR, user-editable
 ├─ format: .raw | .split
 ├─ crop: rect?                   // optional
 └─ exportType: .jpeg | .png      // quality/compression control is v2
```

Format/quality preferences may be persisted in a **shared App Group** `UserDefaults` so the extension and container app agree on defaults (see §5).

---

## 5. State Sharing Between Targets

The extension and container app are separate processes and cannot share memory directly. Use an **App Group** (`group.<bundle-id>`) to share:
- User preferences. **v1 settings (enumerated):**
  - Default format: Raw / Split / *remember last used* (default: remember last used).
  - Default export type: JPEG / PNG (default: JPEG).
  - That's the whole list — metadata stripping is always-on (not a setting), and anything else waits for a demonstrated need.
- (v2) A small queue of detected-screenshot references for the auto-forward flow.

No large image data is passed across the boundary in v1 — the extension handles its image start-to-finish within its own process.

---

## 6. Constraints & Limitations (engineering view)

- **No programmatic messaging.** iOS exposes no API for silent or multi-thread sending. `MFMessageComposeViewController` / `UIActivityViewController` always require a user tap and target one destination at a time. This is the binding constraint on the "automation is premium" vision and shapes v1 toward single-destination export.
- **Share-extension memory budget.** Extensions run under a tighter memory limit than full apps (historically on the order of ~120 MB, subject to change and device variance). Decision — **full output quality is the priority**, so the pipeline is:
  - **Preview/OCR path:** decode a downsampled copy via ImageIO (`CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceCreateThumbnailFromImageAlways`), never the full bitmap, for the on-screen preview and the Vision request. Crop is captured in normalized (0–1) source coordinates against this copy.
  - **Export path:** at export time only, decode the source once at **full resolution**, apply the normalized crop, and encode to the chosen type — a single short-lived full-size bitmap inside an autorelease scope. Screenshots are device-resolution images (~10–30 MB decoded), comfortably within budget.
  - **Safety valve:** if a pathological input (e.g., a shared image far larger than any screenshot) would exceed budget, cap the export's longest edge (e.g., 8K px) rather than crash — and surface that in the UI. This should be rare to never for the screenshot use case.
- **Extension lifecycle.** The extension must call `completeRequest`/`cancelRequest` promptly; long work should show progress and be cancelable.
- **Minimum-functionality bar (review).** Addressed by shipping the crop/quality/export tool, not just reshare.

---

## 7. Tech Stack

| Concern | Choice |
|---|---|
| Language / UI | Swift, SwiftUI (UIKit bridging where required for the extension host) |
| OCR / ML | Vision (`VNRecognizeTextRequest`), on-device |
| Image processing | Core Graphics / UIImage, ImageIO for downsampled decode |
| Sharing in/out | Share extension (`NSExtensionContext`), `UIActivityViewController` |
| Photo import (container) | PHPicker (limited access) |
| Cross-target state | App Group `UserDefaults` |
| Backend | none |

---

## 8. v2 Technical Hooks (noted, not specified)

- **Library auto-detection.** PhotoKit exposes a screenshot media subtype (`PHAssetMediaSubtype.photoScreenshot`), making "find the screenshots" trivial. The harder part — *is this screenshot social media?* — is an image-classification problem: a small **Core ML** model (trained via Create ML) or a Vision classification request, run on-device, gating a local notification. This is the natural "deeper ML" iteration and a strong talking point.
- **Shortcuts / App Intents.** Expose formatting actions via the **App Intents** framework so power users can wire one-tap flows (Home Screen, Back Tap, Shortcuts app) — the "advanced users hardcode, basic users get the UI" split, same logic behind two front doors.
- **Background scanning + notifications.** Requires careful permission UX and battery/privacy consideration; deliberately out of v1.
- **Multi-send.** Only viable via an email backend; would introduce the first server component and a data-handling review surface.

---

## 9. Testing Approach

- **Unit tests (ClippingsKit):** OCR result parsing, formatter output (raw vs split), crop math, export encoding — all testable without UI.
- **OCR fixtures:** a set of ≥20 representative screenshots (IG feed/story, TikTok, X; light/dark; short/long captions; ≥2 non-Latin scripts) to validate extraction quality and ordering, wired to the PRD's measurable accuracy bar. Use synthetic posts or content from accounts you own — avoids copyright/privacy questions about committing strangers' posts to the repo.
- **Manual/UI:** extension invocation across source apps, memory behavior on large images, export to each channel.
- **Edge cases:** image-only screenshots (no caption), very long captions, low-contrast text, non-Latin scripts.

---

## 10. Resolved Technical Questions (June 2026)

- **Caption cleanup:** v1 ships raw OCR text (vertical-position sorted); the user trims by editing. Chrome-stripping heuristics are v2.
- **Split export:** **two separate activity items** (image + text). Composite single-image rendering is a v2 option for destinations that drop the second item.
- **Local history:** **none in v1.** Keeps the "nothing stored" privacy story absolute and the review surface minimal; revisit only if real usage asks for it.

| Concern | Choice |
|---|---|
| ClippingsKit packaging | Local Swift package (not an embedded framework target) |
| Export quality slider | Deferred to v2; v1 is JPEG (fixed sensible quality) / PNG |
| Auto crop-to-content | Deferred to v2; v1 crop is manual |
