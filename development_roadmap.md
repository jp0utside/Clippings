# Clippings — Development Roadmap

**Companion to:** Clippings PRD (v1 / MVP) and System Design
**Last updated:** June 10, 2026
**Cadence assumption:** part-time; ~2 weeks of active build time spread across ~1 month calendar (the rest is waiting on Apple).

Phases are sequential because each one de-risks the next. Every phase has an explicit **exit criterion** — don't start the next phase until it's met.

---

## Phase 0 — Setup *(mostly waiting on Apple; start Phase 1 work in parallel where possible)*

- [ ] Enroll in the Apple Developer Program (the long pole — do this first).
- [ ] Create the Xcode project: container app target + share extension target, iOS 17+ floor.
- [ ] Create **ClippingsKit** as a local Swift package; link from both targets.
- [ ] Configure the App Group (`group.<bundle-id>`) and entitlements for both targets.
- [ ] Set the extension's activation rule: `public.image`, `NSExtensionActivationSupportsImageWithMaxCount` = 10 (extension takes the first image and shows a notice).
- [ ] Basic repo hygiene: `.gitignore`, README stub pointing at the three docs.

**Exit criterion:** both targets build and run on a physical device; the empty extension appears in the Share sheet for an image and can receive it.

---

## Phase 1 — Validation spike *(the riskiest assumptions, proven before any feature work)*

The product's core export step depends on behavior Apple doesn't strongly guarantee. Prove it now, throw the spike code away after.

- [ ] **Spike A — Share sheet inside the extension.** From the extension, present `UIActivityViewController` with **two items (UIImage + String)**. Verify on a physical device:
  - Messages: image and text both arrive in the composer.
  - Mail: both arrive.
  - WhatsApp (or one third-party messenger): document what happens to the text item.
  - AirDrop and Save Image: no crash, sensible behavior.
  - Completion handler fires; `completeRequest` dismisses cleanly afterward (no stuck sheet, no double-dismiss).
- [ ] **Spike B — Memory headroom.** Run the full pipeline shape (downsampled ImageIO decode → Vision OCR → full-res decode + re-encode) on the largest realistic input (Pro Max screenshot, plus one absurd 50 MP image) inside the extension. Watch peak memory in Instruments; confirm comfortable margin under the extension budget.
- [ ] **Spike C — OCR sanity.** Run `VNRecognizeTextRequest` (accurate level) on 3–4 real screenshots. Confirm captions are recoverable and that the vertical-position sort produces readable order.

**Exit criterion:** all three spikes pass on-device, with notes written into `system_design.md` if reality differs from the design (especially Spike A — if the in-extension share sheet is unacceptable, switch the design to container-app handoff via the App Group **before** building the UI).

---

## Phase 2 — Core loop *(the demo: screenshot → extension → Split → Messages)*

Build in ClippingsKit first, UI second — the kit is where the testable logic lives.

- [ ] **ClippingsKit:**
  - [ ] `Clipping` model (`sourceImage`, `extractedText`, `format`, `crop`, `exportType`).
  - [ ] `OCRService`: Vision request, vertical-position observation sort, joined caption output.
  - [ ] `Formatter`: Raw passthrough; Split = (image, text) pair.
  - [ ] `ExportEncoder`: JPEG/PNG encode, **metadata stripped**, full-resolution path per System Design §6.
  - [ ] Unit tests for each, including the **OCR fixture suite** (≥20 fixtures; synthetic or own-account screenshots; asserts content *and* ordering).
- [ ] **Extension UI (SwiftUI in `UIHostingController`):**
  - [ ] Receive image from `NSExtensionContext`; first-image-only notice when multiple are shared.
  - [ ] Preview from the downsampled decode; OCR kicks off on load with a progress state.
  - [ ] Raw/Split toggle; editable caption text field for Split.
  - [ ] **No-caption state:** Split disabled with a one-line explanation.
  - [ ] Export button → `UIActivityViewController` (one item for Raw, two for Split) → `completeRequest` on completion.
  - [ ] Cancel path (`cancelRequest`) and a generic error state (undecodable image, OCR failure).

**Exit criterion:** on a physical device, a real Instagram screenshot goes screenshot → Share → Clippings → Split → Messages, with the caption editable in between, in under ~15 seconds. OCR fixture suite green at the PRD bar (≥90% complete-and-ordered).

---

## Phase 3 — Crop, export controls, container app, polish

- [ ] **Crop:** manual rect crop on the preview; stored in normalized coordinates; applied at full resolution on export. Tests for crop math (including rotation/scale of the preview vs. source).
- [ ] **Export type control:** JPEG/PNG picker (quality slider explicitly *not* in v1).
- [ ] **Container app — full flow:** PHPicker (limited access) import → same Raw/Split/crop/export screens from ClippingsKit-backed shared SwiftUI views.
- [ ] **Container app — onboarding:** a short "how it works" (enable in Share sheet, the loop in 3 steps).
- [ ] **Settings (App Group `UserDefaults`):** default format (remember-last-used default), default export type (JPEG default). Nothing else.
- [ ] **Edge-case pass** (from System Design §9): image-only screenshot, very long caption, low-contrast text, non-Latin scripts, oversized image (safety-valve cap + notice), share from apps other than Photos.
- [ ] **Memory regression check** in Instruments after crop/export are wired up.
- [ ] Dark mode, Dynamic Type sanity, basic accessibility labels.

**Exit criterion:** the full v1 scope works in both targets; edge-case list is verified on-device; no extension terminations under normal use.

---

## Phase 4 — Store prep

- [ ] App icon, App Store screenshots (show the loop, not just static screens), description + subtitle.
- [ ] Decide the final display name ("Clippings — [tagline]") — *still an open PRD question*.
- [ ] Privacy nutrition label: **no data collected.**
- [ ] **Privacy policy URL** — required by App Store Connect even with nothing collected; a one-page static site/GitHub Pages page is fine.
- [ ] Specific, narrow photo-permission purpose strings (PHPicker keeps these minimal).
- [ ] Review notes for the reviewer: explain the extension is the main surface and how to test it (reviewers open the container app first — the full flow there is the safety net).
- [ ] TestFlight pass with 2–3 real users (the friends-and-family senders from the PRD).

**Exit criterion:** archive validated, all Store Connect metadata complete, TestFlight feedback triaged.

---

## Phase 5 — Submit & iterate

- [ ] Submit for review; expect 1–2 revision cycles (minimum-functionality is the likely pushback; the crop/format tool and full-flow container app are the prepared answer).
- [ ] Fix-and-resubmit loop until approved.
- [ ] Tag `v1.0` in the repo on approval.

**Exit criterion:** live on the App Store.

---

## Post-v1 backlog *(ordered roughly by value-to-effort; pick ONE as the headline iteration — open PRD question)*

1. **Composite Split rendering** — caption drawn into a single output image, for destinations that drop the second activity item. (Smallest lift; directly patches a v1 rough edge found in Spike A.)
2. **App Intents / Shortcuts action** — "Split + share" as a one-tap flow; strong portfolio talking point, no new permissions.
3. **Library auto-detection** — `PHAssetMediaSubtype.photoScreenshot` scan + Core ML "is this social media?" classifier + local notification. The deeper-ML iteration, but the biggest permission/UX surface.
4. Export **quality slider** and **auto crop-to-content**.
5. Caption **chrome-stripping heuristics** (usernames, counts, buttons).
6. Multi-send via email backend — first server component; only if real demand.

---

## Standing assumptions (decided June 2026 — change the docs if these change)

- Split = two separate share items; full-resolution export is the priority; metadata always stripped.
- v1 export types: JPEG + PNG only. Crop is manual. Caption cleanup is manual.
- No local history, no backend, no analytics — the privacy label stays "no data collected."
- iOS 17+ floor.
