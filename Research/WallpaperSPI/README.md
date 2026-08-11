# Wallpaper SPI research

This directory records interoperability research for Movo's macOS 26 wallpaper
extension. It is deliberately independent of product code and contains no copied
implementation. Every claim is tagged as one of:

- **Observed** — reproduced from a local binary, SDK stub, property list, or log.
- **Inferred** — the smallest explanation consistent with the observations.
- **Unknown** — not established and therefore unsafe to depend on.

## Safety boundary

The commands here are read-only with respect to macOS and Wallspace. They do not
register extensions, edit wallpaper preferences, write `Index.plist`, restart
system services, or modify `/System`. The sanitizer writes only to standard
output. Redirect output only to a disposable research directory.

Do not ship code merely because a selector appears in these notes. Private APIs
are version-specific. Movo must fail closed when its runtime fingerprint is not
explicitly recognized, and it must never corrupt the wallpaper store while
trying to recover.

## Evidence fingerprint

The current evidence set was collected on:

| Component | Observed value |
| --- | --- |
| macOS | 26.3, build `25D125` |
| Xcode | 26.6, build `17F113` |
| installed macOS SDK | 26.5 |
| Wallspace host | 1.6 (`160`) |
| Wallspace extension | 1.5.1 (`151`) |
| extension SHA-256 | `6190822d8c16236e565ee147edcd2e24bc9f09a7974554ce688c082b68a7fdbd` |
| extension arm64 UUID | `A0851256-DFDD-3E16-8B0B-5421438F2318` |
| SDK `WallpaperExtensionKit.tbd` SHA-256 | `f31357bf870cccf028a5eb5e28691b4c5679c263d33965f4f31f18eac41920af` |

**Observed:** the extension declares the `com.apple.wallpaper` ExtensionKit
extension point and has a deployment target of macOS 26.0.

**Observed:** the extension dynamically loads `WallpaperExtensionKit`; it does
not statically link that framework.

**Unknown:** whether any selector, request layout, or lifecycle behavior remains
compatible on another macOS build. A mismatched build or binary hash is a hard
research-gate failure, not a best-effort compatibility signal.

## Contents

- [`maps/selectors.md`](maps/selectors.md) — provider, reverse-proxy, and XPC
  interface surface.
- [`maps/classes.md`](maps/classes.md) — independently described class roles and
  ownership boundaries.
- [`notes/lifecycle.md`](notes/lifecycle.md) — sanitized lifecycle/state-machine
  model.
- [`notes/store-schema.md`](notes/store-schema.md) — read-only wallpaper store
  observations.
- [`notes/ida-session.md`](notes/ida-session.md) — reproducible IDA evidence and
  remaining extraction blocker.
- [`fixtures/index-schema-sanitized.plist`](fixtures/index-schema-sanitized.plist)
  — synthetic, non-user fixture illustrating only the observed schema shape.
- [`scripts/collect-readonly.sh`](scripts/collect-readonly.sh) — evidence commands
  that print to standard output.
- [`scripts/sanitize_store.py`](scripts/sanitize_store.py) — deterministic
  redaction of a plist to JSON on standard output.

## Known blockers

1. The private framework image lives in the dyld shared cache. The filesystem
   framework path is only a symlink, and no command-line shared-cache extractor
   is installed. Its implementation has therefore not been analyzed. A G002
   follow-up also observed `WallpaperExtensionKit` in dyld runtime mappings, but
   IDA MCP database entries for the installed binary and an ephemeral arm64 slice
   had empty `session_id` values, so no additional targeted analysis could be
   performed through MCP.
2. No controlled before/after store capture has been made for linked versus
   separated desktop/lock-screen assignments or for a second physical display.
3. Available lifecycle logs demonstrated Apple's wallpaper runtime but did not
   prove that the Wallspace extension was the active provider during capture.
4. Private request object fields, allowed-class indexes, and snapshot wire
   layouts remain partly opaque. Runtime use must not be implemented from names
   alone.

## G002 safety checkpoint

**Observed:** the runtime framework image appears loaded, the SDK still exposes
only a `.tbd` stub, and the local machine had no installed Apple dyld
shared-cache extractor available to produce a reviewed standalone framework
Mach-O.

**Observed:** IDA MCP listed active workers for the installed Wallspace extension
binary and an ephemeral arm64 slice, but both worker records had empty
`session_id` values. Analysis calls therefore had no valid database target.

**Inferred:** G002 is blocked on research plumbing, not on an implementation
decision. The compatibility layer must remain fail-closed.

**Unknown:** the allowed classes, request/reply object layout, snapshot payload,
and provider-selection contract needed to mutate desktop or lock-screen state
safely.

No further IDA claims were made from this state. No wallpaper store mutation,
provider registration, service restart, or Wallspace installation change was
performed. The smallest next actions are to repair/update the IDA MCP session
IDs or use a reviewed dyld shared-cache extraction path, then resolve the
allowed-class, request, reply, and snapshot contracts before implementing
activation.
