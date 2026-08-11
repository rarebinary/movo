# Movo V1 — Approved-direction Design Brief

## 1. Feature Summary

Movo is a production-ready, native macOS 26+ live-wallpaper workspace for an Apple Silicon Mac, initially optimized for a 2020 M1 MacBook Air with 8 GB of memory. It lets Yann import short `.mov` or `.mp4` files, preview and tune them, and explicitly apply them to the desktop and lock screen while the app manages storage, optimization, display assignment, and energy-aware playback locally.

## 2. Primary User Action

Choose or import a video, verify it in the dominant preview, then click **Set Wallpaper** with confidence that the selected desktop, lock-screen, and display assignments are correct.

## 3. Design Direction

**Color strategy:** Restrained. The moving wallpaper owns nearly all color; Movo uses near-black graphite, cool silver hairlines, and selective directional chrome.

**Theme scene:** A focused Mac owner adjusts a moving image at a black optical workbench in a dim room, then commits it with one deliberate silver control.

**Anchor references:** Wallspace for immersive media hierarchy and finish; professional video/color tools for preview-first spatial logic; machined optical equipment for restrained chrome tactility. Wallspace is a quality reference, not a template: Movo keeps one workspace, no V1 section tabs, and its own two-frame M identity.

**Winning probe:** the revised Black Projection Bench north star at `/Users/yann/.codex/generated_images/019ff0a5-28f7-7532-9a15-098ee661e5a0/exec-e24b07fd-8f45-4623-8697-fa589d07f9f1.png`. It deepens the earlier graphite direction to near-black and moves brightness into earned chrome highlights, especially the brand mark, current filmstrip frame, and Set Wallpaper action.

## 4. Scope

- **Fidelity:** production-ready.
- **Breadth:** complete V1 surface: onboarding, main workspace, expanded library, contextual inspector, Settings window, menu-bar control, import/optimization status, and essential recovery states.
- **Interactivity:** shipped-quality native controls, keyboard navigation, drag and drop, contextual animations, media preview, and wallpaper application.
- **Time intent:** polish until the local V1 is genuinely usable, performant, and coherent; no remote catalogue or distribution infrastructure in this phase.

## 5. Layout Strategy

The live preview is the stage and receives the majority of the window. A compact top instrument row contains the Movo identity, active display selector, search, import, inspector toggle, and Settings. The filmstrip sits directly below the preview and expands into the full local library without navigating away. Active-item identity and metadata anchor the lower-left; favorite, information, and Set Wallpaper anchor the lower-right. A narrow inspector slides from the right edge and overlays rather than crushes the preview at compact window widths.

The hierarchy is preview → active selection → explicit apply action → optional adjustments → library management. The minimum `960 × 640pt` composition remains usable, while larger windows increase preview area instead of inflating controls.

## 6. Key States

- **First launch / extension unavailable:** explain the wallpaper extension in context, verify its state, and expose one clear activation action.
- **Empty library:** dominant drop target plus Import Video; supported formats and 180-second limit are visible without becoming legal copy.
- **Import validation:** inspect duration, dimensions, codec, frame rate, and audio; reject unsupported or overlong media with a specific remedy.
- **Managed-copy import:** show immediate thumbnail/preview preparation and preserve the source file.
- **Optimization required:** background conversion with progress, estimated resulting size, cancel, and a clear indication that playback remains silent.
- **Default workspace:** active wallpaper playing in preview, relevant filmstrip, display assignment, desktop/lock linking, and Set Wallpaper ready.
- **Preview paused:** unambiguous play state without implying the real wallpaper is paused.
- **Unsaved preview changes:** inspector changes are visible instantly; Set Wallpaper clearly becomes the commit point.
- **Applying:** short determinate or staged progress with controls protected from duplicate invocation.
- **Success:** restrained confirmation, active-assignment update, and the one-time Launch at Login invitation after the first successful apply.
- **Application error:** preserve the previous assignment, explain the failing target, and offer retry or extension repair.
- **External display disconnected:** remember its assignment; show it as unavailable without deleting configuration.
- **Low power / battery / fullscreen / display sleep pause:** status is available in the menu bar and Settings without persistent banners.
- **Search / favorites / recents:** filmstrip filters immediately; zero results provide a compact reset action.
- **Delete:** managed copy moves to Trash; a quiet Undo notice restores it and its metadata when possible.
- **Reduced Motion / Increased Contrast:** replace spatial transitions with crossfades and strengthen boundaries without changing information architecture.

## 7. Interaction Model

Users can import with the top control, drag and drop, or `⌘O`. Clicking a filmstrip frame uses a shared transition into the preview; arrow keys move through items. Space toggles preview playback. Search (`⌘F`) filters the current library context. The inspector updates Fill/Fit, focal point, loop range, speed, and display targets immediately in preview, while `⌘Return` or Set Wallpaper explicitly commits them.

The desktop and lock screen are linked by default and can be separated in the Displays inspector group. The inspector retracts to return space to the preview. Hover feedback is subtle; pressing controls produces a short tonal/chrome shift. Reduced Motion swaps geometry movement for brief crossfades. The menu bar provides active wallpaper, pause/resume, recent items, favorites, Open Movo, Settings, and Quit.

## 8. Content Requirements

All product copy is English, concise, operational, and non-promotional. Required strings include onboarding guidance, extension states, import limitations, validation failures, optimization progress and size estimate, display availability, desktop/lock linkage, power-pause reasons, apply success/failure, deletion/Undo, and the one-time Launch at Login invitation.

Dynamic ranges: 0–50 typical local wallpapers, one or more displays, videos up to 180 seconds, `.mov` and `.mp4`, source frame rates up to 60 fps, and resolutions capped during optimization to the target display. Metadata shows title, resolution, duration, codec/optimization state, and managed size where useful.

## 9. Recommended References

- `spatial-design.md` for preview dominance, filmstrip rhythm, anchored inspector, and minimum-window adaptation.
- `typography.md` for compact SF Pro hierarchy and optical balance.
- `color-and-contrast.md` for near-black separation, chrome restraint, and Increased Contrast.
- `motion-design.md` for shared selection, inspector movement, logo reveal, crossfades, and Reduced Motion.
- `interaction-design.md` for commit semantics, keyboard behavior, drag/drop, Undo, and error recovery.
- `responsive-design.md` for the `960 × 640pt` minimum and overlay inspector behavior.
- `ux-writing.md` for concise English guidance and recovery copy.

## 10. Open Questions

No product-direction questions block implementation. Exact wallpaper-extension lifecycle APIs and the available lock-screen behavior on macOS 26 must be confirmed against the installed Xcode 26.6 SDK during the technical spike; the UI must report unsupported or unavailable system states honestly rather than simulate success.
