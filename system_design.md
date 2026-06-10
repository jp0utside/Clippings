# Clippings — System Design

**Companion to:** Clippings PRD (v1 / MVP)
**Platform:** iOS 16+ (iPhone), Swift / SwiftUI
**Last updated:** June 10, 2026
**Scope:** Technical design for the v1 loop, with v2 hooks noted but not specified.

---

## 1. Overview

Clippings is a fully **on-device, no-backend** iOS app. It ships as **two targets that share one framework**:

- **Container app** — the standalone app users see on the Home Screen. Hosts the crop/format/export tool, an onboarding/"how it works" screen, and settings.
- **Share extension** — the heart of the product. Invoked from the system Share sheet on a screenshot; presents the formatting UI and performs OCR.
- **Shared framework ("ClippingsKit")** — common code used by both targets: the data model, OCR service, image-formatting logic, and export helpers. Avoids duplication and keeps logic testable in isolation.

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

1. **Invocation.** User taps Share on a screenshot and selects Clippings. iOS hands the extension the image via its `NSExtensionContext` input items. The extension is declared to accept image content types (UTType `public.image`).
2. **Presentation.** The extension renders a **custom view controller hosting a SwiftUI sheet** — not the default compose view. This is what gives the "real interface" feel.
3. **OCR.** On load, the formatter kicks off a Vision text-recognition request on the image. Detected text is surfaced as the editable caption for the "Split" format.
4. **Format selection.** User chooses **Raw** (pass image through unchanged) or **Split** (image + extracted text). Optional crop and quality/format adjustment.
5. **Export.** The formatted output is handed to a `UIActivityViewController` (the system Share sheet) for delivery to a single destination. Extension completes its request and dismisses.

---

## 3. Key Technical Decisions

### 3.1 Share extension UI
iOS share extensions are **not** limited to a small menu — a `UIViewController` subclass can present arbitrary UI, and SwiftUI can be embedded via `UIHostingController`. Decision: build the formatting experience entirely inside the extension so the user never has to open the container app first. This is the single most important UX decision in the product.

### 3.2 On-device OCR (the ML moment)
Use the **Vision** framework (`VNRecognizeTextRequest`, accurate recognition level) for caption extraction. Rationale:
- Runs fully on-device — no network, supports the privacy story.
- High accuracy on rendered UI text (which IG/TikTok captions are).
- No model to train, bundle, or version for v1.

The recognized text is returned as ordered observations; the formatter joins them into a caption block the user can edit before sending. Layout heuristics (e.g., stripping UI chrome like usernames/like counts) are a refinement, not a v1 requirement.

### 3.3 Image formatting & export
Formatting (crop, recompress, resize, choose output type) is standard Core Graphics / `UIImage` work in ClippingsKit. Export goes through `UIActivityViewController`, which deliberately:
- Respects platform rules (no silent/bulk send — see §6).
- Gives the user every channel they already have (Messages, Mail, AirDrop, etc.) for free.

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
 └─ export: { type, quality }     // output format + compression
```

Format/quality preferences may be persisted in a **shared App Group** `UserDefaults` so the extension and container app agree on defaults (see §5).

---

## 5. State Sharing Between Targets

The extension and container app are separate processes and cannot share memory directly. Use an **App Group** (`group.<bundle-id>`) to share:
- User preferences (default format, default export quality).
- (v2) A small queue of detected-screenshot references for the auto-forward flow.

No large image data is passed across the boundary in v1 — the extension handles its image start-to-finish within its own process.

---

## 6. Constraints & Limitations (engineering view)

- **No programmatic messaging.** iOS exposes no API for silent or multi-thread sending. `MFMessageComposeViewController` / `UIActivityViewController` always require a user tap and target one destination at a time. This is the binding constraint on the "automation is premium" vision and shapes v1 toward single-destination export.
- **Share-extension memory budget.** Extensions run under a tighter memory limit than full apps (historically on the order of ~120 MB, subject to change and device variance). Large screenshots must be downsampled before OCR/processing to avoid termination. Decision: downsample to a working resolution for OCR and on-screen preview; only re-render at full quality at export time.
- **Extension lifecycle.** The extension must call `completeRequest`/`cancelRequest` promptly; long work should show progress and be cancelable.
- **Minimum-functionality bar (review).** Addressed by shipping the crop/quality/export tool, not just reshare.

---

## 7. Tech Stack

| Concern | Choice |
|---|---|
| Language / UI | Swift, SwiftUI (UIKit bridging where required for the extension host) |
| OCR / ML | Vision (`VNRecognizeTextRequest`), on-device |
| Image processing | Core Graphics / UIImage |
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
- **OCR fixtures:** a set of representative IG/TikTok/story screenshots to validate extraction quality and catch regressions.
- **Manual/UI:** extension invocation across source apps, memory behavior on large images, export to each channel.
- **Edge cases:** image-only screenshots (no caption), very long captions, low-contrast text, non-Latin scripts.

---

## 10. Open Technical Questions

- Caption cleanup: how aggressively to strip UI chrome (usernames, counts, buttons) from OCR output in v1 vs. leaving raw text for the user to trim.
- Export of the "Split" format: send image + text as one combined message vs. two items — depends on destination capabilities.
- Whether to persist a lightweight local history of recent clippings (convenience vs. keeping the "nothing stored" story absolute).
