# Wallpaper store: read-only schema observations

Source examined read-only:

```text
~/Library/Application Support/com.apple.wallpaper/Store/Index.plist
```

No store mutation was performed.

## Observed shape

The current store contains these top-level families:

```text
AllSpacesAndDisplays
Displays/<DISPLAY_UUID>
Spaces/<SPACE_ID>/Default
Spaces/<SPACE_ID>/Displays/<DISPLAY_UUID>
SystemDefault
```

A selection may contain:

```text
Content/Choices[]/Configuration   opaque Data
Content/Choices[]/Files           array
Content/Choices[]/Provider        provider bundle identifier
Content/EncodedOptionValues       opaque Data
Content/Shuffle                   null-like sentinel
LastSet                           date
LastUse                           date
```

Observed nodes used `Type = idle` or `Type = individual`, with `Desktop` and
`Idle` branches appearing under per-display/space structures.

See the synthetic fixture in
[`../fixtures/index-schema-sanitized.plist`](../fixtures/index-schema-sanitized.plist).
It contains placeholders and empty data only; it is not a restorable backup.

## Inferences requiring controlled confirmation

- A `Linked`-style assignment likely represents one choice applied to both the
  desktop and idle/lock-screen contexts.
- Separate `Desktop` and `Idle` selections likely represent unlinked choices.
- `Type = individual` likely selects per-display/per-Space resolution precedence.

These are schema interpretations, not observed transition diffs. A later test
must capture sanitized before/after copies around a user-driven change and compare
them without editing the plist directly.

## Transactional product rule

Movo should ask the wallpaper system to perform assignments through its supported
runtime path. It must not treat direct `Index.plist` editing as an API. If future
research proves a write is unavoidable, implementation remains blocked until it
has all of the following:

1. a verified build fingerprint;
2. an atomic, byte-for-byte backup;
3. schema validation before and after;
4. rollback verified on a disposable user account;
5. explicit failure handling for WallpaperAgent races.

None of those conditions is satisfied by this research snapshot.
