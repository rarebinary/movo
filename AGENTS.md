# Movo Agent Guide

## Context recovery

Whenever conversation context is compacted, lost, or uncertain, read every project Markdown file at the repository root before planning or editing. At minimum, always reload:

1. `PRODUCT.md`
2. `DESIGN.md`
3. `SHAPE-BRIEF.md`
4. `README.md`
5. `TECHNICAL-NOTES.md`
6. `ROADMAP.md`
7. `References/Wallspace/README.md`
8. this `AGENTS.md`

Treat those files as the durable source of truth. Newer explicit user instructions override conflicting older text and should be written back into the appropriate Markdown file.

The archived Wallspace screenshots under `References/Wallspace/` are visual evidence. Read their index before any Movo UI redesign. They authorize studying interaction grammar, geometry, hierarchy, and finish; they do not authorize copying Wallspace assets, branding, content, proprietary code, or exact screen structure.

## Product constraints

- Native macOS 26+ app, Apple Silicon only.
- Swift 6 and SwiftUI, with AppKit where macOS integration requires it.
- Local-first and offline in V1; no accounts, analytics, telemetry, or backend.
- Import managed `.mov` and `.mp4` copies, maximum duration 180 seconds.
- Wallpaper playback is always silent.
- Optimize only when needed and prefer hardware-decodable media.
- Target smooth, low-resource behavior on a 2020 M1 MacBook Air with 8 GB RAM.
- Desktop and lock screen are linked by default but separable; assignments are per display.
- Preserve native macOS behavior and accessibility despite the custom edge-to-edge interface.
- MIT license. No paid Developer ID or notarization workflow is assumed.

## Design constraints

- Follow `DESIGN.md` tokens and `SHAPE-BRIEF.md` states.
- The active wallpaper is the stage; product chrome stays near-black and silver.
- Chrome is earned: reserve it for the mark, current selection, and primary action.
- Avoid cloning Wallspace, generic macOS Settings UI, SaaS card grids, purple/neon AI palettes, gaming RGB, and decorative glass.
- All user-facing copy is English.

## Working agreement

- Keep diffs reviewable and preserve unrelated user changes.
- Use focused tests before broad builds.
- Verify on the installed Xcode SDK instead of assuming undocumented macOS 26 wallpaper APIs.
- Do not claim desktop or lock-screen support until it is exercised against the real extension lifecycle.
