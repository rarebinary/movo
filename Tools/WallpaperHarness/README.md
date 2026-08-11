# Wallpaper Harness

This directory documents the Set Wallpaper safety laboratory. Stage 0 captures
recovery evidence and first proves restoration on a disposable fixture. A live
same-byte check may then run either in the dedicated lab account or, after an
explicit user authorization, in the current graphical account.

## Current command surface

```sh
Scripts/capture-wallpaper-state.sh capture \
  --store "$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist" \
  --output-dir /absolute/path/to/empty/recovery-bundle \
  --label before-experiment
```

The `capture` command is read-only. It requires explicit absolute paths and
creates a bundle containing:

- original store bytes copied with `ditto --rsrc --extattr`;
- store checksum, size, mode, uid, gid, and mtime;
- extended-attribute names and hex payloads when available;
- OS, Xcode, SDK, PluginKit, launchctl, process, code-signing, app hash, and
  Wallpaper/ExtensionKit log evidence;
- a human-readable JSON manifest describing the capture and safety limits.

No command in Stage 0 writes the real wallpaper store, restarts WallpaperAgent,
registers an extension, or changes the active wallpaper.

## Local extension lifecycle

Stage 2 adds a separate, non-mutating installer for the Movo wallpaper
extension:

```sh
Scripts/install-local.sh install
Scripts/install-local.sh status
Scripts/install-local.sh disable
Scripts/install-local.sh enable
Scripts/install-local.sh repair
Scripts/install-local.sh remove
```

`install` builds an arm64 Release app, signs nested frameworks first, signs the
extension with its sandbox entitlement, signs the host last, and installs the
result at `~/Applications/Movo.app`. It then registers the host and extension
with LaunchServices and PluginKit. A leading `+` in `status` means enabled; a
leading `-` means registered but disabled. `repair` repeats signing and
registration without touching wallpaper selection. `remove` verifies the host
bundle identifier before unregistering and deleting only that managed install.

The full install/status/disable/enable/repair/remove cycle was exercised on the
reference macOS 26.3 machine. This proves the ExtensionKit packaging boundary,
not video rendering or provider activation; no wallpaper state is changed by
these commands.

## No-op recovery proof

Run:

```sh
Scripts/verify-wallpaper-lab.sh
```

This creates a temporary binary plist fixture, captures it, intentionally
corrupts the fixture, restores it from the bundle, and verifies:

- byte-for-byte SHA-256 equality;
- POSIX mode equality;
- mtime equality;
- stable extended-attribute equality when the filesystem supports xattrs.

This proves the recovery mechanism on a disposable target only. It does not
prove recovery of a live wallpaper store, ownership restoration when the
restore command is not running as root, WallpaperAgent synchronization, or
visible wallpaper rollback.

## Real restore guardrails

The restore path exists so later disposable-account experiments can be recovered
from an explicit bundle:

```sh
Scripts/capture-wallpaper-state.sh restore \
  --bundle /absolute/path/to/recovery-bundle \
  --target /absolute/path/to/Index.plist \
  --i-understand-this-overwrites-target
```

It refuses broad paths. It also refuses the current user's real wallpaper store
unless `MOVO_ALLOW_REAL_WALLPAPER_RESTORE=1` is set. That environment variable is
not used by the no-op verification and should remain unset during normal
development.

## Gate 0 status

The repo can prove an interrupted no-op recovery on a temporary fixture and a
same-byte live recovery with an explicit account confirmation:

1. capture the live disposable account state;
2. perform an interrupted no-op experiment that does not change provider choice;
3. restore from the bundle;
4. verify the live store checksum and the visible previous wallpaper are
   unchanged.

`com.apple.provenance` is reported separately because macOS may attach this
protected marker during an atomic file replacement and remove it again
asynchronously. The gate still requires exact store bytes, mode, owner, group,
mtime, and all nonvolatile xattrs to match. Until those checks and the visual
confirmation pass, later Set Wallpaper stages remain fail-closed.

## Disposable-account Gate 0 procedure

On a Mac that cannot keep two graphical sessions open, use the interactive
launcher:

1. log out of the primary account completely;
2. sign in to the disposable `movo-wallpaper-lab` account;
3. double-click `Scripts/run-wallpaper-gate0.command` from the shared Movo
   checkout;
4. inspect the visible wallpaper and type `UNCHANGED` only when it is exactly
   unchanged;
5. log out of the lab account and return to the primary account.

The launcher stores its raw evidence in `/Users/Shared/movo-gate0`. It is only
an interactive wrapper around the two fail-closed commands below and still
refuses to run outside the disposable account.

After signing into the dedicated `movo-wallpaper-lab` local account, run:

```sh
Scripts/capture-wallpaper-state.sh verify-live-noop-recovery \
  --output-dir /Users/movo-wallpaper-lab/Desktop/movo-gate0 \
  --i-confirm-disposable-movo-account
```

The disposable flag is hard-coded to refuse every other account and unexpected
home directory. It captures the live store, records an interruption before provider
selection, restores the same bytes, and proves checksum, mode, owner, group, and
mtime equality. It never attempts a provider change. The generated result stays
in `awaiting-visible-confirmation` until the operator verifies that the same
wallpaper remains visible and runs:

```sh
Scripts/capture-wallpaper-state.sh confirm-live-noop-recovery \
  --bundle /Users/movo-wallpaper-lab/Desktop/movo-gate0 \
  --i-confirm-visible-wallpaper-unchanged
```

Only the resulting `status: passed` report closes Gate 0. Screenshots and raw
recovery bundles remain local and must not be committed because they may contain
user- or machine-specific state.

When the current graphical-account owner has explicitly authorized the no-op
test, the equivalent first phase is:

```sh
Scripts/capture-wallpaper-state.sh verify-live-noop-recovery \
  --output-dir /Users/Shared/movo-current-gate0 \
  --i-confirm-current-account
```

The helper refuses root and refuses a user that does not own `/dev/console`.
