# Read-only runtime contract introspection

This note records Objective-C runtime metadata from the cache-resident
`WallpaperExtensionKit` image. The companion script loads the framework into an
ephemeral local process, allocates wrapper objects without opening an XPC
connection, and supplies a recording `NSCoder` to `initWithCoder:`. It does not
contact WallpaperAgent, register a provider, restart a service, or read/write a
wallpaper store.

Run:

```sh
Research/WallpaperSPI/scripts/introspect-runtime-contract.sh
```

The script fails closed unless both the macOS build and framework UUID match the
fingerprint in the compatibility contract. Its JSON output is intended for
comparison and should not be treated as a production serialization schema.

## Observed wrapper surface

| Wrapper | Instance bytes | Stored ivar | First decode requests |
| --- | ---: | --- | --- |
| `WallpaperCreationRequestXPC` | 104 | `rawValue` at offset 8 | `[NSSecurityScopedURLWrapper]` under `files`; `NSSecurityScopedURLWrapper` under `cacheDirectory`; `NSData` under `codable` |
| `WallpaperUpdateRequestXPC` | 56 | `box` at offset 8 | `NSData` under `WallpaperUpdateRequest` |
| `WallpaperRemoteContextXPC` | 16 | `box` at offset 8 | `NSData` under `UInt32` |
| `WallpaperSnapshotXPC` | 16 | `rawValue` at offset 8 | no request before the synthetic decode returned `nil` |
| `WallpaperExtensionChoiceRequestXPC` | 32 | `box` at offset 8 | `NSData` under `WallpaperChoiceRequest` |
| `WallpaperChoiceRequestAdditionResultXPC` | 64 | `box` at offset 8 | `NSData` under `WallpaperChoiceRequestAdditionResult` |

Each class exposes `initWithCoder:` and `encodeWithCoder:` on the recorded
runtime. The empty/synthetic decoder intentionally returns no private payload;
therefore an initializer returning `nil` is expected and is not evidence of an
invalid real archive.

## Interpretation boundary

### Observed

- The XPC wrappers use secure keyed decoding entry points on build `25D125`.
- Most value-like wrappers begin with an `NSData` envelope keyed by the semantic
  type name. The creation wrapper separately transports security-scoped file
  wrappers and its cache directory before a `codable` data envelope.
- The wrapper sizes, ivar names/offsets, method encodings, requested classes, and
  top-level keys are reproducible without system mutation.

### Inferred

- The `NSData` envelopes likely carry Swift `Codable` representations for the
  high-level request values exported by the framework.
- The creation request separates file capabilities from the opaque value payload
  so the extension can receive scoped access without embedding URLs in the
  codable data alone.

### Unknown — still blocks Gate 1

- The bytes inside each `NSData` envelope, including field names, enum values,
  optionality, validation, and cross-version aliases.
- The real snapshot archive layout; a nil synthetic decode cannot establish it.
- Reply/error/timeout/order semantics and the scope of wallpaper identifiers.
- Which provider-selection transaction activates the extension, and whether it
  succeeds twice with identical controlled inputs.

No product code may construct these wrappers from this table alone.
