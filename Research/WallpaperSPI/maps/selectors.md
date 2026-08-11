# Selector and protocol map

Source fingerprint: see [`../README.md`](../README.md). Addresses below refer to
the x86_64 slice selected by IDA and are research anchors only.

## Exported provider protocol

**Observed:** `WallpaperXPCHandler` conforms to a protocol named
`WallpaperExtensionXPCProtocol`. Its Objective-C method list contains 21 methods.

| # | Selector | Observed encoding family | Confidence |
| ---: | --- | --- | --- |
| 1 | `acquireWithId:request:reply:` | `v40@0:8@16@24@?32` | high |
| 2 | `updateWithId:request:reply:` | `v40@0:8@16@24@?32` | high |
| 3 | `invalidateWithId:reply:` | `v32@0:8@16@?24` | high |
| 4 | `snapshotWithId:reply:` | `v32@0:8@16@?24` | high |
| 5 | `provideSettingsViewModelsWithContentTypes:reply:` | `v32@0:8@16@?24` | high |
| 6 | `addChoiceRequestWithChoiceRequest:onBehalfOfProcess:reply:` | `v40@0:8@16@24@?32` | high |
| 7 | `removeChoiceRequestWithChoiceRequest:reply:` | two objects + reply | high |
| 8 | `selectedChoicesDidChangeFor:reply:` | object + reply | high |
| 9 | `invokeContextMenuActionWithMenuItemID:groupItemID:reply:` | `v40@0:8@16@24@?32` | high |
| 10 | `isChoiceDownloadedWith:reply:` | object + reply | high |
| 11 | `downloadWithChoiceID:reply:` | object + reply; reply return encoding needs confirmation | medium |
| 12 | `pauseDownloadFor:reply:` | object + reply | high |
| 13 | `cancelDownloadFor:reply:` | object + reply | high |
| 14 | `resumeDownloadFor:reply:` | object + reply | high |
| 15 | `removeDownloadFor:reply:` | object + reply | high |
| 16 | `migrateSelectedChoiceFor:reply:` | object + reply | high |
| 17 | `migrateFrom:to:reply:` | `v40@0:8@16@24@?32` | high |
| 18 | `skipShuffledContentWithId:reply:` | object + reply | high |
| 19 | `canSkipShuffledContentWithId:reply:` | object + reply | high |
| 20 | `handleDebugRequestFor:reply:` | object + reply | high |
| 21 | `handleNotificationWithNamed:reply:` | object + reply | high |

**Unknown:** the semantic type of every argument and reply payload. Objective-C
encodings establish arity and object/block positions, not Swift model layouts.

### Lifecycle anchors

| Selector | IDA entry | Observed forwarding/body |
| --- | ---: | --- |
| `acquireWithId:request:reply:` | `0x1000420e0` | async wrapper; callback `sub_100043B00` |
| `updateWithId:request:reply:` | `0x1000421e0` | calls `sub_100047D50` |
| `invalidateWithId:reply:` | `0x1000422f0` | async bridge; callback not yet independently labeled |
| `snapshotWithId:reply:` | `0x100042550` | calls `sub_100049ED0` |
| `provideSettingsViewModelsWithContentTypes:reply:` | `0x1000428d0` | wrapper/body not fully mapped |

Addresses are not an ABI and must never be used by production code.

## Reverse proxy

**Observed:** the extension configures a reverse interface named
`WallpaperExtensionProxyXPCProtocol` with four selectors:

| Selector | Encoding |
| --- | --- |
| `pingWithId:` | `v24@0:8@16` |
| `updateSettingsViewModels:reply:` | `v32@0:8@16@?24` |
| `requestReadOnlyAccessTo:reply:` | `v32@0:8@16@?24` |
| `invalidateSnapshotsWithReply:` | `v24@0:8@?16` |

**Inferred:** this proxy lets the provider ask WallpaperAgent for narrowly scoped
host services. It is not evidence that the extension may write the wallpaper
store directly.

## XPC model names

The following names were observed in Swift/Objective-C metadata and strings:

- `WallpaperCreationRequestXPC`
- `WallpaperUpdateRequestXPC`
- `WallpaperRemoteContextXPC`
- `WallpaperSnapshotXPC`
- `WallpaperContentTypeSetXPC`
- `WallpaperChoiceIDXPC` and `WallpaperChoiceIDsXPC`
- `WallpaperExtensionChoiceRequestXPC`
- `WallpaperChoiceRequestAdditionResultXPC`
- `WallpaperDebugRequestXPC` and `WallpaperDebugResponseXPC`
- `WallpaperMigrationVersionXPC`
- `WallpaperSettingsViewModelsXPC`
- `AuditTokenXPC`

**Observed:** interface setup uses `setClasses:forSelector:argumentIndex:ofReply:`
and secure-coding machinery including `NSKeyedArchiver`, `NSXPCCoder`, and
`setClass:forClassName:`.

**Observed:** a compatibility shim named `ShimViewModelsXPC` reports secure-coding
support.

### Exported-interface allowed classes

**Observed:** `sub_100033450` constructs one shared `NSMutableSet`, resolves the
following 15 class names with `objc_getClass`, adds the Foundation classes below,
bridges the result to `NSSet`, and applies that same set to 30 selector/index/reply
tuples with `setClasses:forSelector:argumentIndex:ofReply:`.

Private model classes:

- `WallpaperIDXPC`
- `WallpaperCreationRequestXPC`
- `WallpaperUpdateRequestXPC`
- `WallpaperRemoteContextXPC`
- `WallpaperSnapshotXPC`
- `WallpaperContentTypeSetXPC`
- `WallpaperChoiceIDXPC`
- `WallpaperChoiceIDsXPC`
- `WallpaperExtensionChoiceRequestXPC`
- `WallpaperChoiceRequestAdditionResultXPC`
- `WallpaperDebugRequestXPC`
- `WallpaperDebugResponseXPC`
- `WallpaperMigrationVersionXPC`
- `WallpaperSettingsViewModelsXPC`
- `AuditTokenXPC`

Foundation classes:

- `NSString`, `NSNumber`, `NSData`, `NSArray`, `NSDictionary`, `NSURL`, `NSError`

The exact observed tuples are:

| Selector | Request argument indexes | Reply argument indexes |
| --- | --- | --- |
| `acquireWithId:request:reply:` | 0, 1 | 0 |
| `updateWithId:request:reply:` | 0, 1 | — |
| `invalidateWithId:reply:` | 0 | — |
| `snapshotWithId:reply:` | 0 | 0 |
| `provideSettingsViewModelsWithContentTypes:reply:` | 0 | 0 |
| `addChoiceRequestWithChoiceRequest:onBehalfOfProcess:reply:` | 0, 1 | 0 |
| `removeChoiceRequestWithChoiceRequest:reply:` | 0 | — |
| `selectedChoicesDidChangeFor:reply:` | 0 | — |
| `invokeContextMenuActionWithMenuItemID:groupItemID:reply:` | 0, 1 | — |
| `isChoiceDownloadedWith:reply:` | 0 | — |
| `downloadWithChoiceID:reply:` | 0 | — |
| `pauseDownloadFor:reply:` | 0 | — |
| `cancelDownloadFor:reply:` | 0 | — |
| `resumeDownloadFor:reply:` | 0 | — |
| `removeDownloadFor:reply:` | 0 | — |
| `migrateSelectedChoiceFor:reply:` | 0 | 0 |
| `migrateFrom:to:reply:` | 0, 1 | — |
| `skipShuffledContentWithId:reply:` | 0 | — |
| `canSkipShuffledContentWithId:reply:` | 0 | — |
| `handleDebugRequestFor:reply:` | 0 | 0 |
| `handleNotificationWithNamed:reply:` | 0 | — |

**Unknown:** which member of the shared class set is valid for each tuple, the
secure-coding keys and invariants of each private model, and whether this exact
superset remains accepted on another build. The observed superset is therefore
necessary evidence, but not sufficient authorization to construct a production
interface.
