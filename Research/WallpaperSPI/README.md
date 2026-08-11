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
- [`notes/provider-selection.md`](notes/provider-selection.md) — sanitized static
  evidence for the host activation path and its remaining runtime gap.
- [`notes/ida-session.md`](notes/ida-session.md) — reproducible IDA evidence and
  read-only framework inspection route.
- [`notes/runtime-introspection.md`](notes/runtime-introspection.md) —
  build-gated Objective-C metadata and secure-decoding entry keys recovered
  without an XPC connection.
- [`compatibility-contract.md`](compatibility-contract.md) — build-fingerprinted
  Observed/Inferred/Unknown boundary for future implementation.
- [`fixtures/index-schema-sanitized.plist`](fixtures/index-schema-sanitized.plist)
  — synthetic, non-user fixture illustrating only the observed schema shape.
- [`scripts/collect-readonly.sh`](scripts/collect-readonly.sh) — evidence commands
  that print to standard output.
- [`scripts/introspect-runtime-contract.sh`](scripts/introspect-runtime-contract.sh)
  — compiles and runs the ephemeral, fail-closed runtime inspector.
- [`scripts/sanitize_store.py`](scripts/sanitize_store.py) — deterministic
  redaction of a plist to JSON on standard output.

## Known blockers

1. The private framework image lives in the dyld shared cache and the SDK offers
   no importable Swift module. `/usr/bin/dyld_info` now proves its UUID and Swift
   export surface, but a callable ABI-safe client contract is still unproven.
2. No controlled before/after store capture has been made for linked versus
   separated desktop/lock-screen assignments or for a second physical display.
3. Available lifecycle logs demonstrated Apple's wallpaper runtime but did not
   prove that the Wallspace extension was the active provider during capture.
4. The allowed-class superset, indexes, wrapper sizes, and top-level decoder
   keys/classes are now observed. Private `NSData` payloads, archive invariants,
   timeout/error semantics, and provider-selection reproduction remain
   unresolved.

## G002 safety checkpoint

**Observed:** an explicit IDA MCP headless session named
`movo-wallspace-extension` now opens the installed extension with completed
autoanalysis and Hex-Rays. `/usr/bin/dyld_info` inspects the matching private
framework image directly in the dyld shared cache and reports UUID
`2F2E867F-3729-35B7-AE95-2EC823B11353`.

**Observed:** the complete shared allowed-class set and all 30
selector/index/reply tuples were recovered from the extension's XPC interface
configuration. A second read-only IDA session, `movo-wallspace-host`, exposed
static host evidence for deployment, store selection, extension activation, and
runtime restart services.

**Inferred:** the previous empty-session blocker was tooling state, not a missing
binary. G002 is now blocked on runtime reproduction and model semantics rather
than IDA plumbing.

**Unknown:** private payload fields inside the observed `NSData` envelopes,
reply/error/time-out rules, callable framework ABI, and a twice-reproduced
provider-selection transaction.

No wallpaper store mutation, provider registration, service restart, or
Wallspace installation change was performed. The next safe action is a
controlled runtime experiment in the disposable `movo-lab` account after Gate 0
is satisfied; product activation remains disabled.
