# Set Wallpaper — implementation plan

**Status:** ready for execution planning; production activation remains gated by private-contract evidence.

## Outcome

Make Movo's **Set Wallpaper** action apply a managed local `.mov` or `.mp4` to the selected desktop, lock screen, or both on macOS 26, including per-display assignments, persistent activation, renderer health reporting, and automatic rollback when activation fails.

The feature is complete only when it changes the real system wallpaper, survives Movo relaunch and loginwindow transitions, and never reports success before the selected Movo extension is rendering.

## Constraints

- macOS 26+, Apple Silicon only, tested first on the MacBook Air M1 2020 with 8 GB RAM.
- Local, open-source, MIT, ad-hoc signed; no Developer ID or notarization.
- The wallpaper extension point and provider protocol are private and build-specific. Unknown OS builds fail closed.
- Discovery remains read-only. System-state mutation begins only in a disposable macOS user account with byte-for-byte recovery evidence.
- Movo never edits `/System` and never ships copied Wallspace code, assets, or proprietary implementation logic.
- Direct `Index.plist` editing is a last-resort compatibility adapter, not the preferred provider-selection interface.

## Current anchors

- The production action is still an honest placeholder in `MovoApp/AppModel.swift:188-194`.
- The dock invokes that action in `MovoApp/Views/WorkspaceView.swift:168-190`; target selection currently covers Both/Desktop/Lock Screen and the built-in display in `MovoApp/Views/WorkspaceView.swift:207-286`.
- Immutable requests, phases, errors, display identity, and renderer health already exist in `MovoCore/WallpaperApplicationModels.swift:3-211`, with tests in `MovoCoreTests/WallpaperApplicationModelsTests.swift`.
- The XcodeGen graph currently has only core, host, and tests in `project.yml:20-74`.
- The extension requirements and transaction contract are recorded in `TECHNICAL-NOTES.md:3-26`.
- The observed provider selector surface is recorded in `Research/WallpaperSPI/maps/selectors.md:6-92`.
- The independent acquire/update/snapshot/invalidate state machine is recorded in `Research/WallpaperSPI/notes/lifecycle.md:19-79`.
- The wallpaper store shape and the current prohibition on writes are recorded in `Research/WallpaperSPI/notes/store-schema.md:11-66`.

Apple's public documentation confirms that ExtensionKit is the system extension foundation and that an extension can configure an XPC connection, but it does not document `com.apple.wallpaper` or provider selection. Public AVFoundation APIs remain appropriate for silent local playback and looping:

- [ExtensionKit](https://developer.apple.com/documentation/ExtensionKit)
- [AppExtension](https://developer.apple.com/documentation/extensionfoundation/appextension/)
- [PrimitiveAppExtensionScene](https://developer.apple.com/documentation/extensionkit/primitiveappextensionscene)
- [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer)
- [AVPlayerLooper](https://developer.apple.com/documentation/avfoundation/avplayerlooper)

## Decision

Use an isolated build-fingerprinted compatibility layer and a Generic ExtensionKit extension. Prefer the observed wallpaper runtime/choice path for selecting Movo as provider. Keep a transactional wallpaper-store adapter behind a separate capability gate only if controlled evidence proves that no callable selection path exists.

This splits the work into three independently verifiable boundaries:

1. **Provider renderer:** the extension can acquire, update, snapshot, and invalidate a video surface.
2. **Provider activation:** a harness can select that provider and restore the previous provider.
3. **Product coordinator:** the UI converts user choices into immutable requests and streams verified phases.

## Acceptance criteria

### Registration and compatibility

- A clean local build embeds one arm64 ExtensionKit extension whose extension point is `com.apple.wallpaper`.
- `Scripts/install-local.sh` ad-hoc signs the nested extension before the host, installs to `~/Applications/Movo.app`, and produces an explicit registered/enabled/unavailable status.
- The SPI module accepts only explicitly recorded macOS build/framework fingerprints. An unknown fingerprint returns `extensionUnavailable` without opening a write transaction.
- Settings shows the real extension registration, enabled state, runtime fingerprint, renderer health, and last apply result.

### Renderer lifecycle

- A debug harness can drive acquire → update → snapshot → invalidate without changing the active wallpaper.
- Acquire returns a valid remote surface only after the local file is validated and a still first frame is attached.
- Update pauses/resumes the correct renderer for presentation/activity changes.
- Snapshot returns a non-empty image with the expected dimensions and color space.
- Invalidate releases the player, layers, remote context, observers, and file access; the renderer registry returns to zero.
- All playback is muted and uses hardware-decodable managed media.

### Real activation

- Desktop, lock screen, linked Both, and independent desktop/lock-screen assignments work on the built-in display.
- When a second physical display is available, the same-video and different-video per-display cases work independently.
- Apply success requires all of: provider selection readback, extension acquire, `RendererHealth.healthy`, and a successful snapshot/health probe.
- The assignment survives Movo relaunch, sleep/wake, and one logout/login cycle.
- Cancel or any failure before verified health restores the exact previous provider/selection.
- Killing the harness or Movo at every transaction phase leaves a startup-recoverable journal; the next launch restores or completes deterministically.

### User experience

- `Set Wallpaper` displays: Validating → Backing Up → Selecting Provider → Starting Renderer → Verifying → Applied.
- Duplicate apply is disabled while a transaction is active; cancellation remains available until provider handoff.
- A failure notice names the failed phase and offers the correct recovery action.
- No success toast is shown when only store selection changed but rendering did not start.

## Implementation stages

### Stage 0 — Establish the safe laboratory

**Files:** `Research/WallpaperSPI/`, new `Scripts/capture-wallpaper-state.sh`, new `Tools/WallpaperHarness/README.md`.

1. Create a disposable local macOS user used only for wallpaper mutation tests.
2. Record the exact OS build, SDK/framework hashes, Wallspace host/extension hashes, Movo hashes, extension registration, and sanitized wallpaper-store checksum before each experiment.
3. Add read-only capture commands for `pluginkit`, `codesign`, `launchctl`, ExtensionKit/WallpaperAgent unified logs, store metadata, and process state.
4. Define a recovery bundle containing original store bytes, permissions, owner, extended attributes, checksums, active provider metadata, and a human-readable experiment manifest.
5. Prove manual recovery on the disposable account before any automated mutation.

**Gate 0:** a deliberately interrupted no-op experiment restores an identical checksum and the previous wallpaper. Until this passes, later stages may not write system state.

### Stage 1 — Close the remaining interoperability gaps

**Files:** update `Research/WallpaperSPI/maps/`, `notes/`, and fixtures; add `compatibility-contract.md`.

1. Obtain the matching `WallpaperExtensionKit` image from the dyld shared cache using an Apple/platform-provided or independently reviewed extractor, then analyze its Objective-C/Swift metadata in IDA.
2. Resolve the concrete classes, `NSSecureCoding` keys, allowed-class sets, selector argument indexes, reply payloads, timeout behavior, and reverse-proxy requirements for:
   - `acquireWithId:request:reply:`
   - `updateWithId:request:reply:`
   - `snapshotWithId:reply:`
   - `invalidateWithId:reply:`
   - choice addition/removal and selected-choice change notifications.
3. Capture Wallspace-active logs, proving the provider bundle ID and correlation IDs rather than inferring lifecycle ordering from a system provider.
4. Perform controlled user-driven Wallspace changes and diff sanitized before/after state for Desktop, Lock Screen, linked Both, unlinked Both, and—when available—a second display.
5. Determine whether provider selection is exposed through an XPC/choice request. Record direct store mutation only as the fallback if runtime selection is proven unavailable.
6. Convert observations into a clean-room compatibility specification with field types, ownership, ordering, errors, and build fingerprints. Every entry is marked Observed/Inferred/Unknown.

**Gate 1:** no Unknown remains in the minimal acquire/update/snapshot/invalidate request and reply path, and the provider-selection mechanism is reproduced twice with matching sanitized evidence.

### Stage 2 — Add the isolated extension and SPI targets

**Files:** `project.yml`; new `MovoWallpaperSPI/`, `MovoWallpaperExtension/`, `MovoWallpaperSPITests/`, extension Info.plist and entitlements.

1. Add an arm64 framework target `MovoWallpaperSPI` and a Generic ExtensionKit target `MovoWallpaperExtension` embedded under `Contents/Extensions`.
2. Declare `com.apple.wallpaper`, macOS 26, sandboxing, application-extension-safe APIs, and only the entitlements proven necessary.
3. Add `RuntimeFingerprint`, `WallpaperCapability`, `SPIError`, and runtime symbol/protocol builders. Private types and selectors never cross this module boundary.
4. Construct XPC interfaces with explicit allowed classes from the compatibility contract; reject unknown classes and malformed payloads.
5. Add extension registration diagnostics and the system-provided extension-management UI where applicable.
6. Add deterministic local build/install/sign/register scripts with idempotent repair and uninstall operations.

**Gate 2:** a clean clone can build, install, enumerate, enable, disable, repair, and remove Movo's extension without changing the current wallpaper.

### Stage 3 — Implement the renderer state machine

**Files:** new extension renderer/session files; protocol fakes and tests under `MovoWallpaperSPITests/`.

1. Implement one serialized renderer session per observed request/display/context identity.
2. Validate the managed file, display, duration, codec, loop range, fit mode, focal point, and speed before allocating a remote surface.
3. Attach a decoded still frame immediately; prepare a muted `AVQueuePlayer`/`AVPlayerLooper` behind it; crossfade only after the first moving frame is ready.
4. Implement acquire, update, snapshot, and invalidate with explicit timeouts and exactly-once replies.
5. Implement policy updates for display sleep, full-screen suppression, desktop visibility, Low Power Mode, battery threshold, and loginwindow activity using public signals in the host and the observed presentation/activity fields in the extension.
6. Emit structured unified logs/signposts keyed by request ID, display ID, target, phase, renderer count, and last-frame time, without file paths or user data.

**Gate 3:** the harness completes 100 acquire/update/snapshot/invalidate cycles with zero leaked sessions, zero double replies, zero crashes, and less than 20 MB net memory growth over a 30-minute loop test.

### Stage 4 — Build provider activation as a transaction

**Files:** new `MovoWallpaperSPI/Activation/`; new `Tools/WallpaperHarness/`; fixtures and failure-injection tests.

1. Implement `WallpaperProviderSelector` with two adapters:
   - `RuntimeChoiceSelector` — preferred, using the observed choice/request path.
   - `TransactionalStoreSelector` — disabled by default and compiled/activated only for fingerprints with complete store evidence.
2. Implement a transaction journal containing operation ID, runtime fingerprint, requested assignments, original bytes/checksum/metadata, proposed checksum, phase, backup URL, and recovery status.
3. Preserve unknown store keys and opaque data byte-for-byte. Never regenerate unrelated nodes.
4. For the store fallback: write on the same volume, fsync file and directory, atomically replace, validate schema and provider readback, then notify/restart only the minimal observed wallpaper service.
5. Wait for extension acquire and health verification. Commit the journal only after the required target renderers are healthy.
6. On timeout, cancellation, crash recovery, provider mismatch, renderer failure, malformed store, or unknown build, restore the exact backup and verify the previous provider is active.
7. Add phase-by-phase failure injection and an emergency read-only `diagnose` command plus an explicit `rollback <operation-id>` command.

**Gate 4:** on the disposable account, the harness completes 20 successful applications and 20 forced rollbacks for each supported target mode. Every forced failure restores the original checksum and visible previous wallpaper within 10 seconds.

### Stage 5 — Connect the production coordinator

**Files:** new `MovoCore/WallpaperApplying.swift`; new `MovoApp/Services/WallpaperApplyCoordinator.swift`; update `MovoApp/AppModel.swift`, `WorkspaceView.swift`, and `SettingsView.swift`.

1. Define a `WallpaperApplying` protocol so AppModel and UI tests use a fake rather than the real SPI.
2. Snapshot selection, target, display assignments, fit/focal/loop/speed settings, and managed media URL into one immutable request.
3. Replace `requestSetWallpaper()` with an async coordinator that serializes applies, supports cancellation, streams phases, and retains the last structured result.
4. Map phases to the dock button and accessible status text. Require `RendererHealth.healthy` before `.completed`.
5. Show extension unavailable/disabled/fingerprint mismatch states before the user starts an apply.
6. Add repair/open-extension-settings, last operation, diagnostic export, and rollback status to Settings.
7. Offer Launch at Login only after the first verified success.

**Gate 5:** unit and UI tests prove that no path can publish Applied without provider readback plus healthy renderer evidence.

### Stage 6 — System validation and release gate

**Files:** `Tests/System/SET-WALLPAPER-MATRIX.md`, test logs/results excluded from source control except sanitized summaries.

1. Test a fresh clone/install and an upgrade over the previous Movo build.
2. Test MOV/MP4, H.264/HEVC, 1080p/4K, 24/30/60 fps, Fill/Fit, focal point, loop segment, and playback speed.
3. Test Desktop, Lock Screen, linked Both, separated Both, all displays, and per-display divergence.
4. Test relaunch, WallpaperAgent restart, extension disable/enable, sleep/wake, logout/login, display disconnect/reconnect, missing media, Low Power Mode, low battery, full-screen app, and desktop hidden.
5. Test unknown macOS build and modified framework hash; both must fail closed without creating a transaction.
6. Run Instruments for 30 minutes on the M1/8 GB reference machine. Verify one decoder per visible renderer, no unbounded memory growth, no orphaned player/context, and no rendering while all consumers are paused.
7. Visually inspect at least ten loop boundaries per target and confirm no black frame or flash. Archive sanitized video evidence and logs.

**Release gate:** Set Wallpaper becomes enabled in normal builds only after the full built-in-display matrix passes, rollback evidence is archived, and a clean install reproduces success. Multi-display is enabled only after physical second-display validation.

## Test architecture

### Unit

- Runtime fingerprint allow/deny decisions.
- Secure-coding round trips and rejected unknown classes.
- Renderer state transitions, exactly-once replies, timeout, cancellation, and cleanup.
- Store parser byte preservation, precedence resolution, journal serialization, atomic replacement preparation, and recovery decisions.
- Apply coordinator phase ordering and the invariant that `.completed` requires healthy renderer evidence.

### Integration

- Extension registration/enabling diagnostics against a locally installed ad-hoc build.
- Host ↔ extension XPC contract using controlled local media.
- Harness provider selection/readback and real renderer acquisition on a disposable account.
- Restart recovery from every journal phase.

### End-to-end

- A visible desktop and lock-screen application for every supported target combination.
- Persistence across relaunch, sleep/wake, and logout/login.
- Exact rollback after injected errors and killed processes.

### Observability

- One operation ID connects host, selector, WallpaperAgent observations, extension, renderer, and rollback logs.
- Logs contain phases and non-personal identifiers only.
- Diagnostic export includes fingerprints, registration, phase history, renderer health, and checksums—not wallpaper filenames or original store data.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| A macOS update changes the private contract | Exact build/framework allowlist; unknown builds fail before mutation. |
| Direct store writes corrupt user state | Prefer runtime choice API; disposable-account gate; byte backup; atomic replace; startup recovery; exact rollback verification. |
| Ad-hoc extension is not enabled or remains quarantined | Deterministic install/sign/register diagnostics and a Settings repair flow using system extension-management UI. |
| UI reports success while the extension is dead | Completion requires provider readback, acquire, healthy last frame, and snapshot/health probe. |
| Lock screen uses a distinct lifecycle | Separate target/context sessions and separate verification; never infer lock-screen success from desktop success. |
| Multiple displays or Spaces resolve precedence differently | Derive precedence only from controlled diffs; keep multi-display feature-gated until physical validation. |
| Renderer consumes excessive resources on M1/8 GB | Hardware-decodable media, one session per visible context, strict pause policy, 30-minute Instruments gate. |
| Reverse engineering crosses a legal/ethical boundary | Clean-room interoperability specification only; no copied source/assets; retain provenance and Observed/Inferred/Unknown labels. |

## Stop conditions

Stop and keep the production button in honest unsupported mode if any of these remains true:

- The matching private-framework image or allowed XPC class contract cannot be established.
- Provider selection cannot be reproduced deterministically.
- Rollback cannot restore the exact prior state after a forced failure.
- Extension acquire/render health cannot be correlated to the selected provider.
- The installed macOS build or framework fingerprint is unknown.

## Recommended execution order

1. Execute Stages 0–1 as the immediate research milestone.
2. Review the resulting compatibility contract before creating product SPI code.
3. Execute Stages 2–3 and prove renderer-only behavior.
4. Execute Stage 4 exclusively on the disposable account until Gate 4 passes.
5. Execute Stages 5–6 and enable the product action only at the final release gate.

The critical path is **contract evidence → renderer-only harness → transactional activation harness → production coordinator**. UI wiring is intentionally last because it is already the easiest and least risky part.
