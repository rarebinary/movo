# Movo — Wallspace-Level Polish and Working Wallpaper Integration

## Status

Approved planning baseline, 2026-08-11. This file is the canonical cross-session roadmap. After context compaction, read it together with the root product/design documents and `References/Wallspace/README.md` before editing.

The detailed OMX plan entry is `.omx/plans/movo-wallspace-polish-and-wallpaper-spi.md` and points back here.

## Outcome

Ship a local, open-source Movo build that:

1. feels as immersive and coherent as the supplied Wallspace references while retaining Movo's black/chrome identity and single-workspace product model; and
2. actually applies a managed `.mov` or `.mp4` as a silent live desktop and lock-screen wallpaper on the reference macOS 26 Apple Silicon machine through an independently implemented compatibility boundary around the private wallpaper SPI.

Success is not a convincing mock. The **Set Wallpaper** action must change the selected real desktop/lock-screen targets, survive app relaunch, render without flashes, and roll back safely when activation fails.

## Requirements summary

### Product constraints

- macOS 26+, Apple Silicon only, tested first on the 2020 M1 MacBook Air with 8 GB RAM.
- Local-first, offline, MIT, ad-hoc signed; no paid Developer ID or notarization.
- Managed `.mov`/`.mp4`, maximum 180 seconds, always silent.
- Desktop and lock screen linked by default but separable; one assignment per display.
- Balanced energy policy and invisible quality adaptation remain mandatory.
- Existing import, optimization, persistence, preview, search, favorites, menu bar, Trash, and Undo behavior must not regress.

### Design constraints

- One continuous edge-to-edge near-black canvas with native traffic lights and a visually larger `22–24pt` outer radius.
- No differently colored side rails, conventional toolbar strip, or dashboard-card scaffolding.
- Selected video remains dominant and may visually continue behind the top instrument row.
- Adopt the supplied references' compact, tactile button proportions and anchored floating controls, translated into Movo's graphite and directional silver materials.
- Preserve Movo's single workspace, filmstrip, retractable inspector, custom two-frame M mark, and explicit apply semantics.
- Wallspace is evidence for geometry, hierarchy, density, layering, and polish only. No proprietary assets, content, copy, exact topology, or source implementation may be copied.

### Reverse-engineering constraints

- Reverse engineering is limited to functional interoperability with macOS 26's undocumented wallpaper extension lifecycle.
- Keep all private symbols and store manipulation behind `MovoWallpaperSPI`; the media/library/UI layers must compile independently from that implementation.
- Load private frameworks dynamically. Do not add private headers or link the host app directly against private frameworks.
- Treat every wallpaper-store update as a transaction with byte-for-byte backup, atomic replace, post-write validation, render confirmation, and rollback.
- Never report success from UI until both provider selection and visible renderer health are confirmed.

## Acceptance criteria

### A. Visual shell

- At `1240 × 790pt`, the active video is the largest uninterrupted region and the top row reads as an overlay/instrument, not a separate toolbar.
- At `960 × 640pt`, no primary control is clipped; the inspector overlays or retracts without shrinking the stage below usability.
- The outer window has one continuous background, consistent rounded clipping, preserved traffic lights, resizing, full-screen behavior, and a deep restrained window shadow.
- Buttons share one measurable state system: default, hover, pressed, keyboard focus, selected, disabled, loading, success, and failure.
- The bottom action dock exposes title/essential metadata, target selection, favorite/info where useful, and a chrome **Set Wallpaper** action without duplicating the inspector.
- Target selection opens an anchored popover for `Both / Desktop / Lock Screen` and available displays. It remains keyboard- and VoiceOver-operable.
- Settings opens as a compact dedicated dark window with grouped rows, a single surface family, native switches, and Movo chrome used only for current/primary states.
- Reduced Motion replaces shared geometry and sliding with short crossfades; Increased Contrast strengthens boundaries; all essential text meets WCAG AA.

### B. Wallpaper compatibility layer

- A Generic ExtensionKit target is embedded with extension point `com.apple.wallpaper`, macOS 26 minimum, arm64, sandbox enabled, and valid ad-hoc nested signing order.
- The extension registers and can be enumerated after a clean install in `~/Applications` or `/Applications`.
- A selected managed video renders through a remote Core Animation context on the chosen desktop display.
- Lock-screen rendering works through the real separate wallpaper context; linked and separated assignments behave as selected.
- Multi-display assignments are stable across app relaunch and display reconnect.
- Loop transitions produce no black frame or flash; playback remains silent.
- Failure at any store, agent, XPC, renderer, or validation stage leaves the previous wallpaper active and surfaces a specific recoverable error.
- The installer/test path is documented and repeatable from a fresh clone without a paid Apple developer account.

### C. Performance

- On the reference M1/8 GB Mac, steady-state wallpaper playback uses hardware decode for accepted/optimized assets.
- Playback is capped to target display resolution and 60 fps, and pauses under the approved power/full-screen/display-sleep rules.
- Preview and wallpaper renderer do not decode duplicate full-quality streams when the app is hidden or the same media can be shared safely.
- A 30-minute Instruments run shows no unbounded memory growth, renderer accumulation, or repeated media reopening.

## Implementation plan

### Current implementation anchors

- Window customization already begins in `MovoApp/MovoApp.swift:32-53`; extend that AppKit boundary instead of scattering window mutations through SwiftUI views.
- The current root canvas/top row/inspector composition is in `MovoApp/Views/WorkspaceView.swift:10-45`, and the instrument row is in `MovoApp/Views/WorkspaceView.swift:47-130`.
- Preview, filmstrip, and the separate bottom action bar are assembled in `MovoApp/Views/WorkspaceView.swift:132-196`; preview clipping is at `MovoApp/Views/WorkspaceView.swift:259-299`, and filmstrip selection geometry is at `MovoApp/Views/WorkspaceView.swift:302-329`.
- Current chrome and icon controls are centralized in `MovoApp/Views/ChromeControls.swift:3-71`; evolve these rather than adding unrelated one-off button styles.
- Palette/material primitives live in `MovoApp/Design/MovoTheme.swift:3-35`.
- Settings layout and grouped-row helpers live in `MovoApp/Views/SettingsView.swift:3-119`.
- The production apply action is currently an honest placeholder at `MovoApp/AppModel.swift:186-192`; this is the exact application seam Phase 8 replaces.
- The current XcodeGen graph has only core, host app, and tests at `project.yml:20-74`; Phase 6 adds the SPI framework and ExtensionKit targets here.
- Existing platform evidence and the transaction safety contract are in `TECHNICAL-NOTES.md:3-26`.

### Phase 0 — Freeze evidence and baselines

**Files:** `References/Wallspace/`, `References/Wallspace/README.md`, `MovoCoreTests/`, future `UITests/` or snapshot harness.

1. Keep the six supplied captures under stable ASCII names and record their hashes.
2. Capture the current Movo UI at `1240 × 790pt` and `960 × 640pt` before visual edits.
3. Add behavior-focused tests for selection, target assignment state, pending/applying/success/error transitions, and rollback-facing notices before refactoring the workspace.
4. Record an idle/import/preview CPU-memory baseline on the reference Mac.

**Exit:** archived inputs and regression baselines make visual and functional changes comparable.

### Phase 1 — Rebuild the window as one projection canvas

**Files:** `MovoApp/MovoApp.swift`, `MovoApp/Views/WorkspaceView.swift`, `MovoApp/Design/MovoTheme.swift`, new `MovoApp/Design/WindowChrome.swift` if AppKit isolation is useful.

1. Make the `NSWindow` opaque/transparent behavior, corner clipping, titlebar, shadow, movable regions, safe areas, and full-size content explicit rather than relying on default SwiftUI composition.
2. Remove the visible toolbar/body separation: the root canvas owns the whole window; preview gradients provide local contrast beneath controls.
3. Tune the continuous outer radius, inset traffic-light clearance, minimum-size adaptation, full-screen radius removal, and restored window size.
4. Add a debug-only layout overlay for content bounds, safe areas, control hit targets, and window clipping.

**Exit:** Movo looks like one near-full-screen surface inside a normal resizable Mac window, with no side-color seams.

### Phase 2 — Create a coherent optical control family

**Files:** `MovoApp/Views/ChromeControls.swift`, `MovoApp/Design/MovoTheme.swift`, new focused control files under `MovoApp/Views/Controls/`.

1. Define `OpticalControlSize`, shared radii, graphite well, selected fill, chrome primary material, hairline, shadow, and focus-ring tokens.
2. Implement reusable button styles for icon, labeled secondary, segmented choice, primary action, loading action, toggle row, and compact chip.
3. Add hover and press feedback using 120–180 ms tonal changes and sub-2% scale only; disable geometry movement under Reduced Motion.
4. Reserve the shiny multi-stop chrome gradient for the mark, active selection edge, and primary action. Everything else remains low-chroma graphite.
5. Verify 44pt effective hit areas even where visible controls are more compact.

**Exit:** no one-off control geometry remains in workspace, popovers, or Settings.

### Phase 3 — Recompose the workspace around the media

**Files:** `MovoApp/Views/WorkspaceView.swift`, `MovoApp/Views/VideoPreview.swift`, `MovoApp/Views/InspectorView.swift`.

1. Place the brand and essential instrument controls over the preview with adaptive contrast scrims.
2. Let the preview approach the window edges while retaining native traffic-light clearance and a clear drag region.
3. Make the filmstrip overlap the preview/body transition, with clipped horizontal continuation and a restrained double-chrome active edge.
4. Replace the separate full-width bottom bar with a centered floating action dock inspired by the reference detail screen but specific to Movo's workflow.
5. Keep display selector, search, import, and inspector access; do not introduce Wallspace's Home/Explore/Library tabs.
6. Move `Both / Desktop / Lock Screen` and display choice into an action-anchored `TargetPopover`; leave Fill/Fit, focal point, loop, and speed in the retractable inspector.
7. Add explicit `Ready`, `Applying`, `Applied`, and `Failed` visual states to the primary action.

**Exit:** the wallpaper is visually dominant, browsing remains in context, and applying is a one-glance decision.

### Phase 4 — Align Settings and secondary states

**Files:** `MovoApp/Views/SettingsView.swift`, `MovoApp/MovoApp.swift`, `MovoApp/AppModel.swift`.

1. Configure Settings as a dedicated compact resizable-or-fixed window with its own rounded graphite canvas and restrained parent dimming/elevation.
2. Standardize grouped rows and dividers; keep native switches and pickers where their behavior matters.
3. Add the real extension status, provider registration status, renderer health, last apply result, and a repair/re-register action.
4. Polish empty import, optimization progress, missing display, deleted/Undo, and first-success Launch at Login invitation using the same state vocabulary.

**Exit:** secondary surfaces match the main workspace without resembling a generic System Settings clone.

### Phase 5 — Map the wallpaper SPI with IDA and runtime observation

**Evidence targets:**

- `/Applications/Wallspace.app/Contents/Extensions/WallspaceWallpaperExtension.appex/Contents/MacOS/WallspaceWallpaperExtension`
- `/System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/WallpaperExtensionKit`
- `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`

**Artifacts:** new `Research/WallpaperSPI/README.md`, selector/class maps, sanitized pseudocode notes, store schema fixtures with user-specific data removed, and reproducible shell/LLDB steps.

1. Record Wallspace app/extension versions, UUIDs, code signatures, entitlements, Info.plists, linked libraries, Objective-C metadata, strings, and ExtensionKit registration.
2. Use IDA Pro MCP to identify extension entry points, private protocol conformances, selector dispatch, argument/reply classes, `NSSecureCoding` boundaries, remote proxy creation, `CAContext` lifecycle, snapshots, invalidation, and per-display/context renderer ownership.
3. Trace only the minimal host-to-extension path needed for acquire → update → snapshot → invalidate and the minimal provider selection path.
4. Diff `Index.plist` before/after controlled Wallspace changes for desktop, lock screen, both, and a second display; redact personal data and never write during discovery.
5. Observe `WallpaperAgent`, ExtensionKit, and XPC logs during those controlled operations. Correlate log events with selectors and store deltas.
6. Write an independent compatibility specification: symbol names, signatures, data contracts, state machine, and failure semantics. Do not transcribe proprietary implementation logic.
7. Add a macOS-build fingerprint and feature gate so an unknown OS build fails closed.

**Exit:** the team can implement the lifecycle from a documented interoperability contract instead of continuing to probe the binary ad hoc.

### Phase 6 — Build the isolated compatibility boundary

**Files/targets:** new `MovoWallpaperSPI/`, `MovoWallpaperExtension/`, `MovoWallpaperSPITests/`, updates to `project.yml` and extension Info.plist/entitlements.

1. Define public internal models with no private types: `WallpaperTarget`, `DisplayIdentity`, `WallpaperAssignment`, `WallpaperApplyRequest`, `WallpaperApplyPhase`, `WallpaperApplyError`, and `RendererHealth`.
2. Implement runtime symbol loading and Objective-C protocol/class construction inside `MovoWallpaperSPI` only.
3. Add the Generic ExtensionKit target, `com.apple.wallpaper` metadata, sandbox entitlements, app-group/shared-container decision if required by observed behavior, and host embedding.
4. Implement a renderer state machine per `(context, display)` using silent `AVPlayer`/layer output, `CAContext` handoff, loop handover without black frames, snapshots, invalidation, and resource release.
5. Put all SPI calls behind version/capability checks with exhaustive structured errors and os_log signposts.
6. Add protocol-contract unit tests with fakes so UI/application logic can be tested without mutating the system wallpaper.

**Exit:** a registered extension can acquire and render a controlled test surface without yet changing the user's active provider.

### Phase 7 — Implement transactional provider activation

**Files:** new store/agent adapters inside `MovoWallpaperSPI`, fixtures/tests under `MovoWallpaperSPITests/`, CLI/debug harness under `Tools/WallpaperHarness/` if useful.

1. Parse the wallpaper store into typed, round-trippable models while preserving unknown keys and original bytes.
2. Build a transaction journal containing OS build, target displays/contexts, original checksum, backup path, proposed checksum, phase, and recovery status.
3. Write to a same-volume temporary file, fsync, atomically replace, validate provider selection, restart or notify `WallpaperAgent` using the observed minimal mechanism, and wait for extension acquire/render health.
4. On timeout, crash, invalid schema, missing provider, or failed render, restore the exact backup and verify the previous provider resumes.
5. Add a startup recovery pass for interrupted transactions before accepting a new apply request.
6. Exercise desktop first, then lock screen, then linked both, then per-display divergence.

**Exit:** a command-line/debug harness can apply and roll back a wallpaper repeatedly without using the production UI.

### Phase 8 — Connect Set Wallpaper to the real lifecycle

**Files:** `MovoApp/AppModel.swift`, `MovoApp/Views/WorkspaceView.swift`, `MovoApp/Views/InspectorView.swift`, new application service under `MovoApp/Services/` or `MovoCore/` that depends on the SPI boundary.

1. Replace the placeholder notice in `requestSetWallpaper()` with an async apply coordinator.
2. Snapshot all current preview edits and target choices into an immutable request before applying.
3. Stream application phases to the action dock: validating → backing up → selecting provider → starting renderer → verifying → applied.
4. Disable duplicate applies but keep cancel/rollback available until the irreversible agent handoff is complete.
5. Persist successful assignments by stable display identity, not transient screen index.
6. Offer the one-time Launch at Login suggestion only after the first verified success.

**Exit:** `⌘Return` and the button apply the intended real wallpaper and report truthful progress.

### Phase 9 — Performance, resilience, and installability

**Files:** `MovoCore/VideoImportExecutor.swift`, `MovoApp/Views/VideoPreview.swift`, wallpaper renderer, `README.md`, new `Docs/LOCAL-INSTALL.md` and `Scripts/build-local.sh` only if needed.

1. Add hardware-decode eligibility and target-display resolution checks to import/apply diagnostics.
2. Implement pause/resume triggers for Low Power Mode, battery below 20%, full-screen apps, hidden desktop, display sleep, display disconnect, and system pressure.
3. Profile extension and app separately with Instruments; eliminate duplicate players, leaked layers/contexts, and background rendering with no visible consumer.
4. Automate build → nested ad-hoc sign → host sign → install → ExtensionKit registration verification without paid credentials.
5. Document uninstall, store-backup location, recovery, known compatible macOS build numbers, and the private-SPI breakage warning.

**Exit:** a fresh clone can be built, installed, tested, repaired, and removed by another technical user.

## Verification plan

### Automated

- Existing `MovoCoreTests` remain green.
- Add state-machine tests for renderer acquire/update/snapshot/invalidate and all legal/illegal transitions.
- Add store round-trip fixtures proving unknown keys and bytes are preserved where required.
- Add transaction tests for success, write failure, agent timeout, renderer failure, process interruption, and rollback failure escalation.
- Add AppModel tests proving success is impossible without `RendererHealth.ready`.
- Run `xcodegen generate`, targeted test schemes, Swift 6 compile, and release build with ad-hoc signing configuration.

### Manual matrix

- Window: default, minimum, wide, full screen; empty, one item, 50 items; long title; inspector open/closed; Reduced Motion; Increased Contrast; keyboard-only; VoiceOver.
- Target: desktop only, lock screen only, linked both, separate media, all displays, individual displays, disconnect/reconnect.
- Media: H.264/HEVC, MOV/MP4, 1080p/4K, 24/30/60 fps, source with audio, exact 180-second boundary, optimized source.
- System: relaunch app, log out/in, sleep/wake, Low Power Mode, <20% battery simulation where safe, full-screen app, desktop hidden, WallpaperAgent restart.
- Recovery: malformed proposed store, renderer timeout, extension unregister, killed apply process, missing managed media, unknown macOS build.

### Visual review gate

For every design iteration, capture comparable screenshots and score:

1. preview dominance;
2. continuity of the outer canvas;
3. control geometry consistency;
4. chrome restraint;
5. apply-target clarity;
6. minimum-window integrity;
7. accessibility states.

Do not accept a visual change solely because it is closer to Wallspace. Accept it only if it improves Movo's workflow while remaining recognizably Movo.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Private SPI changes across macOS updates | Exact OS-build capability matrix, runtime symbol checks, fail-closed behavior, isolated boundary. |
| Wallpaper store corruption | Read-only discovery first; byte backup; atomic same-volume replace; journal; validation; rollback; startup recovery. |
| Extension works only inside Wallspace assumptions | Reconstruct the minimal protocol contract independently; fake-driven tests; standalone harness before UI integration. |
| Ad-hoc extension registration is fragile | Deterministic local install/sign/register script and explicit diagnostics in Settings. |
| Lock screen differs from desktop lifecycle | Treat as separate contexts from the start and verify independently before linked mode. |
| Visual redesign becomes a clone | Reference boundary, Movo topology/brand tokens, visual review against workflow outcomes rather than pixel matching. |
| Dark chrome loses contrast | Accessibility snapshots, Increased Contrast tokens, non-color state cues, native focus semantics. |
| M1/8 GB performance regressions | Baseline before redesign/SPI, hardware decode checks, per-context lifetime tests, 30-minute Instruments soak. |

## Stop condition

This milestone is complete only when the visual acceptance criteria pass, all automated tests and the manual target matrix relevant to the reference machine pass, a fresh local install works without paid credentials, and **Set Wallpaper** has been visibly verified on the real desktop and lock screen with rollback evidence. Until then, the UI must label unsupported integration honestly and the roadmap remains active.
