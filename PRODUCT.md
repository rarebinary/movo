# Product

## Register

product

## Users

Movo is initially built for Yann, using a 2020 MacBook Air with an M1 chip and 8 GB of memory. The primary workflow is occasional and focused: import a short local video, preview it, tune a few playback and framing choices, assign it to one or more displays, and then leave the app running quietly from the menu bar.

The open-source project may later serve Apple Silicon Mac owners who are comfortable building the app locally in Xcode. Movo does not promise a frictionless public binary distribution without Apple code signing and notarization.

## Product Purpose

Movo is a macOS 26+ live-wallpaper utility for Apple Silicon. It turns local `.mov` and `.mp4` files into silent, efficient desktop and lock-screen wallpapers through the native macOS wallpaper extension architecture.

The first release is deliberately local-first and offline. It imports managed copies, optimizes inefficient media when needed, supports independent display assignments, and pauses playback intelligently to protect battery life and responsiveness. A future editorial `Discover` catalogue may offer curated downloads, but accounts, community uploads, analytics, remote services, and distribution infrastructure are outside the first release.

Success means a 4K video up to 60 fps can feel smooth on the reference M1/8 GB Mac without turning Movo into a persistent resource burden, while importing and applying a wallpaper remains understandable on the first attempt.

## Brand Personality

Calm, precise, tactile.

Movo should feel like a compact projection instrument: cinematic without theatre, premium without luxury posturing, and polished without borrowing generic SaaS decoration. The product voice is concise, direct, and entirely in English.

## Anti-references

- Do not visually clone Wallspace, reuse its assets, or reproduce its information architecture. Its level of finish and native technical approach are references, not its identity.
- Do not resemble a generic macOS Settings pane or an unstyled SwiftUI sample.
- Do not use the predictable AI-tool palette of midnight blue, purple gradients, and neon green.
- Do not fall into SaaS dashboard clichés: card grids, decorative glass everywhere, pill navigation for its own sake, oversized marketing headings, or badges without meaning.
- Do not use gaming, cyberpunk, or RGB aesthetics.
- Do not let custom chrome undermine standard macOS window behavior, keyboard access, or accessibility.

## Design Principles

1. **The wallpaper is the stage.** Movo's interface frames motion content and then gets out of its way.
2. **Make power visible, not complicated.** Important controls are immediate; advanced choices appear contextually in the inspector.
3. **Preview freely, commit deliberately.** Editing is instant inside Movo, while changing the real desktop always requires an explicit action.
4. **Spend resources only when visible.** Playback quality adapts invisibly, and pausing follows the user's actual context.
5. **Earn familiarity, then add character.** Preserve native Mac mechanics while expressing Movo through composition, materials, typography, and purposeful motion.
6. **Local means trustworthy.** No accounts, analytics, network calls, hidden uploads, or proprietary backend dependencies in the first release.

## Accessibility & Inclusion

Movo must support complete keyboard navigation, meaningful VoiceOver labels and state announcements, visible focus treatment, increased contrast, and non-color status cues. Reduced Motion replaces shared-element movement and sliding transitions with short crossfades without removing functional feedback. The dark-only interface must maintain at least WCAG AA text contrast and remain usable with macOS text and interface scaling.
