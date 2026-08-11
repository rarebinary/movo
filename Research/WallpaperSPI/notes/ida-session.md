# IDA session notes

## Target

```text
/Applications/Wallspace.app/Contents/Extensions/
  WallspaceWallpaperExtension.appex/Contents/MacOS/
  WallspaceWallpaperExtension
```

SHA-256 and UUIDs are recorded in [`../README.md`](../README.md). IDA 9.4 selected
the x86_64 slice for this session. Autoanalysis and Hex-Rays completed before
queries were made.

## Reproducible analysis sequence

Using IDA Pro MCP, the session used the equivalent sequence:

1. Open the extension binary headlessly and wait for autoanalysis.
2. Enumerate entry points, imports, Objective-C classes/selectors, strings, and
   cross-references.
3. Locate `WallpaperXPCHandler` lifecycle methods from the Objective-C metadata.
4. Follow only their immediate async wrappers and semantic bodies.
5. Record calls to public primitives (`dlopen`, `CAContext`, AVFoundation,
   CoreMedia, XPC) and sanitize behavior into an independent state machine.

No patches, debugger writes, process injection, or live-hook installation were
performed.

## High-value observations

| Function | x86_64 anchor | Sanitized observation |
| --- | ---: | --- |
| extension initialization | `sub_10004C990` | Dynamically loads the private framework and registers notification observers |
| acquire body | `sub_100043B00` | Creates/returns a remote CA context and establishes renderer/session ownership |
| update body | `sub_100047D50` | Reads presentation/activity state and adjusts playback policy/timebase |
| snapshot body | `sub_100049ED0` | Associates a snapshot operation with active renderer time/context |

**Observed:** the binary contains diagnostics related to snapshot XPC encoding
and compatibility shims. This is evidence that the archive boundary is fragile;
the proprietary diagnostic text is intentionally not reproduced here.

## Private framework inspection

`WallpaperExtensionKit.framework/WallpaperExtensionKit` resolves into the dyld
shared cache rather than a standalone Mach-O file. The SDK contains only a
text-based stub. However, Apple's `/usr/bin/dyld_info` accepts the framework's
logical path and inspects the matching cache-resident image read-only.

The recorded image reports:

- architecture `arm64e`;
- UUID `2F2E867F-3729-35B7-AE95-2EC823B11353`;
- platform/minimum SDK tuple macOS 26.3/26.3;
- Swift exports for the high-level wallpaper, request, destination, snapshot,
  host-proxy, and choice-request contracts described in
  [`../compatibility-contract.md`](../compatibility-contract.md).

Consequently:

- exported symbol names from the `.tbd` are **observed**;
- framework export signatures are **observed** for this cache UUID;
- private XPC archive layouts and callable ABI from an independent module remain
  **unknown**;
- Gate 1 still cannot declare the compatibility contract implementation-safe.

The remaining research route is controlled runtime tracing in the disposable
account, tied to the same OS build and cache UUID. It must remain sanitized and
must not commit an extracted framework image.

## G002 follow-up resolution

### Observed

- `WallpaperExtensionKit` appears in dyld runtime mappings, confirming that the
  framework image is present at runtime.
- The filesystem framework binary is not available as a standalone analyzable
  Mach-O at the expected private-framework path; the SDK still provides only the
  text-based `.tbd` stub.
- No installed Apple command-line dyld shared-cache extractor was found during
  this pass.
- Opening the extension explicitly with `force_headless` and preferred session
  ID `movo-wallspace-extension` produced a healthy, targetable database.
- Opening the host with preferred session ID `movo-wallspace-host` likewise
  produced a healthy database.
- The extension session proved the full shared allowed-class set and exact 30
  selector/index/reply tuples.
- The host session exposed static provider-deployment and selection evidence.

### Inferred

- The prior empty-session condition was stale worker state and is no longer the
  active blocker.
- Static evidence substantially narrows the contract but cannot replace runtime
  provider-selection reproduction.

### Unknown

- Secure-coding keys and archive validation rules for each private model.
- Timeout, ordering, and reply/error semantics.
- Whether the high-level choice-request surface can select Movo as provider.
- The twice-reproduced store or runtime-choice transaction required by Gate 1.

### Safety notes

- All new IDA and `dyld_info` work remained read-only.
- No wallpaper store, provider registration, system service, or Wallspace
  installation state was modified.
- The smallest next action is a controlled, fully recoverable provider-selection
  experiment in the disposable account after Gate 0 passes.
