# Movo

Movo is a local-first live-wallpaper app for macOS 26 and Apple Silicon. It turns short `.mov` and `.mp4` files into quiet, efficient desktop and lock-screen wallpapers through the native macOS wallpaper extension architecture.

The project is in active pre-alpha development. The native app now builds and runs, imports managed videos, persists a local manifest, generates thumbnails, and plays silent looping previews. The product contract lives in [PRODUCT.md](PRODUCT.md), the visual system in [DESIGN.md](DESIGN.md), the approved V1 interaction brief in [SHAPE-BRIEF.md](SHAPE-BRIEF.md), platform findings in [TECHNICAL-NOTES.md](TECHNICAL-NOTES.md), and the next implementation milestone in [ROADMAP.md](ROADMAP.md). Visual references are indexed in [References/Wallspace/README.md](References/Wallspace/README.md).

## Intended V1

- Managed local video library
- Instant preview with optional framing, focal point, loop range, and speed controls
- Explicit desktop and lock-screen application
- Independent assignments per display
- Hardware-friendly media optimization when required
- Energy-aware automatic pausing
- Main workspace plus compact menu-bar controls
- Fully offline operation

## Requirements

- macOS 26 or newer
- Apple Silicon Mac
- Xcode 26 or newer
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build

```sh
xcodegen generate
xcodebuild \
  -project Movo.xcodeproj \
  -scheme Movo \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Open `Movo.xcodeproj` in Xcode for local development. The project intentionally targets Apple Silicon and macOS 26 or newer.

## Status

Pre-alpha. Local import and preview work. Desktop and lock-screen application remains under development because macOS exposes the required third-party wallpaper extension lifecycle only through private SPI.

## License

MIT. See [LICENSE](LICENSE).
