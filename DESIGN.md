---
name: Movo
description: A calm projection instrument for living macOS wallpapers.
colors:
  void-black: "#090A0C"
  projection-black: "#0D0F12"
  graphite-surface: "#13161A"
  raised-graphite: "#1A1E23"
  chrome-shadow: "#6F747C"
  chrome-mid: "#B8BDC5"
  chrome-highlight: "#F0F2F5"
  primary-text: "#F4F5F6"
  secondary-text: "#A3A8AF"
  tertiary-text: "#747A82"
  hairline: "#343940"
  success: "#77B58A"
  warning: "#D1A85E"
  destructive: "#D16D70"
typography:
  display:
    fontFamily: "SF Pro Display, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "30pt"
    fontWeight: 650
    lineHeight: 1.08
    letterSpacing: "-0.018em"
  headline:
    fontFamily: "SF Pro Display, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "20pt"
    fontWeight: 620
    lineHeight: 1.16
    letterSpacing: "-0.01em"
  title:
    fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "15pt"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "normal"
  body:
    fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "13pt"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "normal"
  label:
    fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "11pt"
    fontWeight: 550
    lineHeight: 1.2
    letterSpacing: "0.01em"
rounded:
  control-sm: "8pt"
  control-md: "11pt"
  panel: "16pt"
  preview: "18pt"
  window: "22pt"
spacing:
  xs: "4pt"
  sm: "8pt"
  md: "12pt"
  lg: "16pt"
  xl: "24pt"
  xxl: "32pt"
components:
  button-primary:
    backgroundColor: "{colors.chrome-mid}"
    textColor: "{colors.void-black}"
    typography: "{typography.title}"
    rounded: "{rounded.control-md}"
    padding: "11pt 20pt"
    height: "42pt"
  button-secondary:
    backgroundColor: "{colors.raised-graphite}"
    textColor: "{colors.primary-text}"
    typography: "{typography.title}"
    rounded: "{rounded.control-md}"
    padding: "10pt 14pt"
    height: "40pt"
  inspector:
    backgroundColor: "{colors.projection-black}"
    textColor: "{colors.primary-text}"
    rounded: "{rounded.panel}"
    padding: "16pt"
    width: "300pt"
  filmstrip-item:
    backgroundColor: "{colors.graphite-surface}"
    textColor: "{colors.primary-text}"
    rounded: "{rounded.control-md}"
    size: "164pt 92pt"
---

# Design System: Movo

<!-- SEED -->

## Overview

**Creative North Star: “The Black Projection Bench”**

Movo should feel like a compact optical instrument used in a dark editing room: quiet, exact, and satisfying to touch. A near-black workspace frames the moving image, while sparse chrome details communicate the handful of actions that matter. The wallpaper supplies nearly all chromatic color; Movo supplies structure, light, and restraint.

The interface borrows the confidence and immersive hierarchy of premium media browsers without reproducing Wallspace’s assets or information architecture. It is neither a generic macOS Settings pane nor a conventional SaaS dashboard. Native macOS window behavior stays familiar beneath a custom edge-to-edge surface.

**Key Characteristics:**

- One dominant cinematic preview rather than a card grid.
- Near-black tonal layers, cool silver hairlines, and selective polished chrome.
- Compact SF Pro typography with decisive hierarchy.
- A horizontal filmstrip that behaves like an editing instrument.
- Functional motion that explains continuity, selection, and state.

## Colors

The palette is almost monochrome. Depth comes from black and graphite steps; emphasis comes from controlled reflected silver rather than a saturated brand accent.

### Primary

- **Optical Chrome** (`#B8BDC5`): primary action base, selected borders, active slider hardware, and the animated Movo mark. In production it may use a directional gradient from Chrome Shadow through Chrome Highlight.

### Neutral

- **Void Black** (`#090A0C`): window foundation and darkest backdrop.
- **Projection Black** (`#0D0F12`): preview surroundings and inspector foundation.
- **Graphite Surface** (`#13161A`): control wells and grouped rows.
- **Raised Graphite** (`#1A1E23`): hover, selected dark controls, and elevated contextual surfaces.
- **Chrome Highlight** (`#F0F2F5`): restrained specular edge and primary text-adjacent highlight.
- **Primary Text** (`#F4F5F6`): titles and essential values.
- **Secondary Text** (`#A3A8AF`): metadata and explanations.
- **Tertiary Text** (`#747A82`): disabled and low-priority content, never essential information alone.
- **Silver Hairline** (`#343940`): dividers and boundaries.

### Named Rules

**The Wallpaper Owns Color Rule.** Saturated color belongs to media. Product chrome stays neutral except for semantic success, warning, and destructive states.

**The Chrome Is Earned Rule.** Bright metal is reserved for the primary action, current selection, and brand mark. Most controls remain graphite.

## Typography

**Display Font:** SF Pro Display (with the system sans-serif fallback)  
**Body Font:** SF Pro Text (with the system sans-serif fallback)  
**Logo Lettering:** custom Movo wordmark paired with the two-frame geometric M mark

**Character:** Native, compact, and optically calm. Typography should feel like macOS at its best, while the custom mark carries the brand distinction.

### Hierarchy

- **Display** (650, 30pt, 1.08): active wallpaper name and rare first-run statements.
- **Headline** (620, 20pt, 1.16): major workspace sections and Settings titles.
- **Title** (600, 15pt, 1.25): controls, inspector groups, and important rows.
- **Body** (400, 13pt, 1.35): explanations, metadata, and status messages.
- **Label** (550, 11pt, 0.01em): compact metadata and restrained section labels; sentence case by default.

### Named Rules

**The One Glance Rule.** The active wallpaper name, active display, playback state, and Set Wallpaper action must be readable without scanning the inspector.

## Elevation

Movo uses tonal layering first and shadows second. Dark surfaces are separated through one-step value changes, silver hairlines, and localized ambient occlusion. Chrome adds a narrow top highlight and a subdued lower shadow, never a broad glow.

### Shadow Vocabulary

- **Window Lift** (`0 24pt 70pt rgba(0,0,0,0.52)`): the main window only when visually separated from the desktop.
- **Inspector Anchor** (`0 16pt 40pt rgba(0,0,0,0.42)`): the retractable contextual inspector.
- **Control Press** (`inset 0 1pt 0 rgba(255,255,255,0.10), inset 0 -1pt 0 rgba(0,0,0,0.45)`): tactile graphite controls.
- **Chrome Edge** (`inset 0 1pt 0 rgba(255,255,255,0.72), inset 0 -1pt 0 rgba(0,0,0,0.28)`): primary chrome surfaces only.

### Named Rules

**The No Glow Rule.** Focus and selection use crisp rings and contrast changes, never neon bloom.

## Components

### Buttons

- **Shape:** compact rounded rectangle (`11pt`), not a universal pill.
- **Primary:** directional brushed-silver gradient, black label, `42pt` height, narrow specular upper edge.
- **Hover / Focus:** highlight shifts slightly toward the pointer; keyboard focus receives a high-contrast double ring that remains visible in Increased Contrast.
- **Secondary:** raised graphite with a fine hairline and white symbol or label.
- **Icon:** square optical control, normally `40pt`; symbols are SF Symbols unless the Movo mark is used.

### Chips

- **Style:** used only for filters or explicit status, never decorative badges.
- **State:** unselected is recessed graphite; selected is raised graphite with a chrome hairline and primary text.

### Cards / Containers

- **Corner Style:** `16pt` panels and `18pt` preview; thumbnails use `11pt`.
- **Background:** tonal graphite, typically without blur.
- **Shadow Strategy:** tonal separation at rest; shadow only for floating contextual surfaces.
- **Border:** one-pixel cool-silver hairline at reduced opacity.
- **Internal Padding:** `16pt` default, `12pt` for dense inspector rows.

### Inputs / Fields

- **Style:** recessed graphite well, `8–11pt` radius, no bright filled background.
- **Focus:** crisp chrome border plus standard keyboard focus semantics.
- **Error / Disabled:** semantic icon and text accompany color; disabled content remains legible.

### Navigation

The V1 has no Home/Explore/Library tab bar. Display selection, search, import, and Settings occupy a compact top instrument row. The library expands in the same workspace from the filmstrip, preserving the preview context.

### Filmstrip

The filmstrip is Movo’s signature browsing component. It shows recent, favorite, or searched items as cinematic frames. The active frame uses a double silver edge and a subtle shared-element transition into the preview. Arrow keys move selection; the filmstrip scrolls only as needed.

### Contextual Inspector

The inspector is a retractable `300pt` anchored panel. It groups Framing, Focal Point, Loop, Playback, and Display assignment without modal interruption. Changes preview instantly; none alter the desktop until Set Wallpaper is invoked.

## Do's and Don'ts

### Do:

- **Do** let the wallpaper occupy the largest uninterrupted region of the workspace.
- **Do** use `#090A0C` through `#1A1E23` to build hierarchy before adding shadows.
- **Do** reserve polished chrome for the Movo mark, active selection, and primary action.
- **Do** preserve native traffic lights, resizing, full screen, keyboard shortcuts, VoiceOver, Reduced Motion, and Increased Contrast.
- **Do** keep animation functional: selection continuity, inspector anchoring, playback feedback, and short crossfades.
- **Do** make destructive deletion recoverable through Trash and Undo.

### Don't:

- **Don't** visually clone Wallspace, reuse its assets, or reproduce its information architecture.
- **Don't** resemble a generic macOS Settings pane or an unstyled SwiftUI sample.
- **Don't** use midnight blue, purple gradients, neon green, cyberpunk lighting, gaming RGB, or luminous glows.
- **Don't** fall into SaaS dashboard clichés: card grids, decorative glass everywhere, pill navigation for its own sake, oversized marketing headings, or badges without meaning.
- **Don't** make every control shiny; chrome loses meaning when it becomes wallpaper.
- **Don't** let custom window chrome undermine standard macOS behavior, keyboard access, or accessibility.
