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

**Unknown:** complete allowed-class sets and their argument/reply indexes. Those
must be captured from an analyzed framework image or controlled runtime tracing
before constructing an independent interface.
