# Class and ownership map

This map describes responsibilities visible from symbols, ivars, call sites, and
framework usage. It intentionally avoids reproducing proprietary algorithms.

| Class | Observed evidence | Independent role hypothesis | Unknowns |
| --- | --- | --- | --- |
| `WallspaceWallpaperExtension` | Extension principal class; initializer dynamically loads `WallpaperExtensionKit`; registers Darwin-notification observers | Extension bootstrap and connection acceptance | Exact connection admission and compatibility policy |
| `WallpaperXPCHandler` | Conforms to `WallpaperExtensionXPCProtocol`; ivars include `agentProxy` and `previousPresentationMode` | Own one exported XPC handler and forward lifecycle messages into renderer state | Exact actor/executor isolation and error contract |
| `VideoRenderer` | Owns `AVSampleBufferDisplayLayer`, `AVSampleBufferVideoRenderer`, `CMTimebase`, current/next readers and outputs, still-frame layer, policy and PTS state | Decode and present one loop while maintaining a no-black-frame handoff | Reader scheduling and crossfade algorithm |
| `VideoLibrary` | Name and call relationships associate it with asset lookup | Resolve a choice identifier to local managed media | Persistence format and access-token strategy |
| `WallpaperPrefs` | Includes a `previousDesktopOccluded` field | Cache user playback/policy preferences and prior occlusion state | Whether values are shared with the host app and where they live |
| `WallpaperState` | Appears in renderer/lifecycle ownership paths | Per-wallpaper aggregate state | Exact keying and lifetime |
| `PowerMonitor` | Used near playback-rate and policy paths | Convert power/system pressure signals into playback policy | Signal sources and thresholds |
| `ShimViewModelsXPC` | Secure-coding compatibility strings and class-name remapping | Decode settings models across private-framework revisions | Supported versions and full archive schema |

## Framework and primitive dependencies

**Observed:** the extension links public system frameworks including AppKit,
AVFoundation, CoreMedia, QuartzCore, IOSurface, ExtensionFoundation, Security,
and Swift runtimes. Symbols include `CAContext`, `AVSampleBufferDisplayLayer`,
`IOSurface`, and `NSXPCInterface`.

**Observed:** the SDK stub for the private framework exports a Swift class named
`WallpaperExtensionKit.VideoPlayerLayer`.

**Inferred:** the provider returns a remote Core Animation context rather than a
file URL or ordinary SwiftUI view. The wallpaper agent/loginwindow can then host
that context without owning the provider's decoder.

**Unknown:** whether Movo needs the private `VideoPlayerLayer` class at all. The
observed third-party provider uses its own AVFoundation/CAContext stack, but this
does not prove all lifecycle requirements can be met without the class.

## Proposed clean-room ownership

An independent implementation should separate these concerns without matching
the third-party class layout:

1. `WallpaperExtensionService`: validate the runtime fingerprint and configure
   XPC interfaces.
2. `WallpaperSessionRegistry`: key sessions by opaque request ID and own
   lifecycle transitions.
3. `RemoteSurfaceSession`: own a `CAContext` and root layer for one target.
4. `SilentLoopRenderer`: own hardware-decodable AVFoundation resources and the
   seamless-loop policy.
5. `PlaybackPolicyController`: respond to presentation/activity/power state.

This is an architectural inference, not a transcription of Wallspace.
