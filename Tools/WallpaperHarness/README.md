# Wallpaper Harness

This directory documents the Set Wallpaper safety laboratory. Stage 0 is a
strictly non-mutating gate: it captures recovery evidence and proves restoration
only on a disposable fixture before any later experiment may write wallpaper
state.

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
- extended-attribute equality when the filesystem supports xattrs.

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

The repo can now prove an interrupted no-op recovery on a temporary fixture.
Gate 0 still requires a separate disposable macOS user account before any real
wallpaper mutation work:

1. capture the live disposable account state;
2. perform an interrupted no-op experiment that does not change provider choice;
3. restore from the bundle;
4. verify the live store checksum and the visible previous wallpaper are
   unchanged.

Until those live disposable-account checks pass, later Set Wallpaper stages must
remain fail-closed.

## Disposable-account Gate 0 procedure

After signing into the dedicated `movo-wallpaper-lab` local account, run:

```sh
Scripts/capture-wallpaper-state.sh verify-live-noop-recovery \
  --output-dir /Users/movo-wallpaper-lab/Desktop/movo-gate0 \
  --i-confirm-disposable-movo-account
```

This command is hard-coded to refuse every other account and unexpected home
directory. It captures the live store, records an interruption before provider
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
