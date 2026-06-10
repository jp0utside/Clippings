# Clippings

An iOS utility that turns a screenshot of social media content into a clean,
well-formatted, shareable item — and forwards it to people who aren't on that
platform. Core loop: **screenshot → Share sheet → Clippings → reformat → send.**

iPhone-only, iOS 17+, fully on-device, no backend, no accounts, no data collected.

## Documentation

The product and engineering are specified across three documents — read these first:

- [`clippings_prd.md`](clippings_prd.md) — Product Requirements (v1 / MVP).
- [`system_design.md`](system_design.md) — Technical design for the v1 loop.
- [`development_roadmap.md`](development_roadmap.md) — Phased build plan with exit criteria.

## Repository layout

```
ClippingsKit/        Local Swift package: model, OCR, formatter, export, crop math.
                     The pure logic lives here so it is testable in isolation.
App/                 Container app target (PHPicker import + full Raw/Split flow).
ShareExtension/      Share extension target (the heart of the product).
project.yml          XcodeGen spec that assembles the .xcodeproj from the sources above.
```

## Project generation

The `.xcodeproj` is **not** committed — it is generated from `project.yml` with
[XcodeGen](https://github.com/yonwoo9/XcodeGen) so the project definition stays
reviewable in plain text and free of merge conflicts.

```sh
brew install xcodegen   # once
xcodegen generate       # produces Clippings.xcodeproj
open Clippings.xcodeproj
```

## Configuration before first build

These placeholders must be replaced with your real values (all centralized in
`project.yml`):

- **Bundle identifier prefix** — currently `com.example.clippings`. Change to your
  own reverse-DNS prefix tied to your Apple Developer account.
- **App Group** — currently `group.com.example.clippings`. Must match the App Group
  you register in the Apple Developer portal and enable on both targets.
- **Development team** — set `DEVELOPMENT_TEAM` once you have a Team ID.

## Build status

> **Note:** This repository is being scaffolded in a Linux environment with no
> Swift/Xcode toolchain. The source here has **not** been compiled. The Phase 0
> exit criterion (both targets build and run on a device) and the Phase 1
> on-device validation spikes must be completed on a Mac with Xcode.

The platform-agnostic logic in `ClippingsKit` (caption sorting, crop math) is
written to compile and test on Linux as well, so a future CI job can run those
unit tests with `swift test` without Apple tooling.
