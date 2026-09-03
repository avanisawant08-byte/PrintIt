---
name: Obsidian Deep Sea
colors:
  surface: '#0a1229'
  surface-dim: '#0a1229'
  surface-bright: '#313851'
  surface-container-lowest: '#050d24'
  surface-container-low: '#131b32'
  surface-container: '#0f1a36'
  surface-container-high: '#162245'
  surface-container-highest: '#2c344c'
  on-surface: '#dbe1ff'
  on-surface-variant: '#c1c7d3'
  inverse-surface: '#dbe1ff'
  inverse-on-surface: '#282f48'
  outline: '#8b919d'
  outline-variant: '#414751'
  surface-tint: '#a4c9ff'
  primary: '#a4c9ff'
  on-primary: '#00315d'
  primary-container: '#60a5fa'
  on-primary-container: '#003a6b'
  inverse-primary: '#0060ac'
  secondary: '#b6c4ff'
  on-secondary: '#05297a'
  secondary-container: '#264191'
  on-secondary-container: '#9db2ff'
  tertiary: '#fabd34'
  on-tertiary: '#412d00'
  tertiary-container: '#d19900'
  on-tertiary-container: '#4b3500'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d4e3ff'
  primary-fixed-dim: '#a4c9ff'
  on-primary-fixed: '#001c39'
  on-primary-fixed-variant: '#004883'
  secondary-fixed: '#dce1ff'
  secondary-fixed-dim: '#b6c4ff'
  on-secondary-fixed: '#00164e'
  on-secondary-fixed-variant: '#264191'
  tertiary-fixed: '#ffdea4'
  tertiary-fixed-dim: '#fabd34'
  on-tertiary-fixed: '#261900'
  on-tertiary-fixed-variant: '#5d4200'
  background: '#0a1229'
  on-background: '#dbe1ff'
  surface-variant: '#2c344c'
  glass-surface: rgba(15, 26, 54, 0.7)
  glass-edge: rgba(164, 201, 255, 0.25)
  primary-glow: rgba(96, 165, 250, 0.15)
typography:
  display:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 28px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter-desktop: 24px
  margin-desktop: 64px
  margin-tablet: 32px
  margin-mobile: 16px
---

## Brand & Style

This design system is a sophisticated evolution of glassmorphism, shifting from neutral obsidian to a rich, **Deep Navy** atmospheric aesthetic. It is engineered for high-performance professional environments—fintech dashboards, advanced IDEs, and aerospace interfaces—where long-form focus and technical prestige are paramount.

The style is defined as **Atmospheric Minimalism**. It utilizes deep, saturated blues as the foundational "dark matter" of the UI, layered with translucent glass panels that feel like heavy, polished sapphire. The emotional response is one of calm authority, immense digital depth, and cutting-edge precision. By replacing pure blacks with deep navies, the UI reduces eye strain while maintaining a high-end, bespoke feel that differentiates it from standard "dark mode" implementations.

## Colors

The palette transitions from monochromatic blacks to a tiered system of **Deep Navy Blue**.

- **Primary Background:** The core canvas uses a rich Navy (`#0a1229`), providing a more natural and premium foundation than pure black.
- **Surface Strategy:** Layers are built using increasing lightness of the navy hue. Surface containers use `#0f1a36`, ensuring a subtle but perceptible lift from the base.
- **Accents:** The Primary Blue (`#60a5fa`) is retained but calibrated for maximum vibrance against the navy backdrop. It should be used for critical actions, active states, and "light-leak" effects.
- **Glass Optics:** The "glass-surface" utilizes a 70% opacity version of the container color, allowing the deep background hues to bleed through when blurred. The "glass-edge" uses a tinted blue-white to simulate light catching the edge of a sapphire pane.

## Typography

This system uses **Hanken Grotesk** for its clean, sharp geometry which pairs perfectly with technical "glass" surfaces. **JetBrains Mono** is employed for all functional data, labels, and status indicators to reinforce the technical nature of the system.

To ensure contrast against the deep navy background:
- **Primary Text:** Use `#FFFFFF` for maximum readability.
- **Secondary/Body Text:** Use a high-brightness blue-tinted gray (`#CBD5E1`) to maintain the color story without sacrificing legibility.
- **Labels:** Monospaced labels should always be in uppercase for better structural alignment in dense data layouts.

## Layout & Spacing

A **Fluid Grid** model is used to allow the atmospheric navy background to breathe.

- **Grid:** A 12-column grid on desktop, 8-column on tablet, and 4-column on mobile.
- **Spacing Rhythm:** Based on a 4px scale. Components should favor `16px` (md) and `24px` (lg) internal padding to maintain an airy, premium feel. 
- **Negative Space:** Use the primary navy background as a structural element. Do not crowd the interface; the "depth" effect requires sufficient empty space around containers to perceive the backdrop blur and edge lighting.

## Elevation & Depth

Hierarchy is achieved through **Optical Physics** rather than traditional shadows.

- **Layer 0 (Base):** The Primary Navy background.
- **Layer 1 (Panels):** Semi-transparent surfaces with a `backdrop-filter: blur(20px)`. This creates the "Deep Sea" effect where content behind the panel is diffused into the navy base.
- **Edge Definition:** All glass containers must feature a 1px solid border using the `glass-edge` token. This simulates a specular highlight and is critical for distinguishing layers of the same color.
- **Atmospheric Glows:** High-priority elements (modals, active cards) utilize a large-radius (60px+) soft outer glow in `primary-glow` color rather than a black drop shadow.

## Shapes

The shape language is **Rounded**, echoing the feel of polished nautical equipment or high-end consumer electronics.

- **Base Radius:** 0.5rem (8px) for standard components.
- **Large Radius:** 1rem (16px) for major cards and glass panels.
- **Extra Large:** 1.5rem (24px) for modals and primary navigation sidebars.

Maintain "inner-radius alignment": when a button (8px radius) is placed inside a card (16px radius), the visual relationship feels nested and intentional.

## Components

### Buttons
- **Primary:** A vibrant solid fill using the Primary Blue. Use bold white text. On hover, apply a soft outer glow of the same color.
- **Glass (Secondary):** Use the `glass-surface` with a 1px `glass-edge` border. Text should be Primary Blue.

### Cards & Panels
The primary container for the design system. Must always include `backdrop-blur` and the subtle blue-tinted edge border. For information-dense sections, reduce the transparency slightly to maintain text clarity.

### Input Fields
Designed as "inset" glass. Use a darker navy fill with 1px border. On focus, the border transitions to Primary Blue and the entire field gains a subtle inner glow. Labels should always use JetBrains Mono for a "terminal-inspired" look.

### Chips & Tags
Small pill-shaped elements with a high-contrast border and 20% opacity fill. Use Primary Blue for active states and Tertiary Gold for alerts.

### Navigation
Vertical navigation in the sidebar should use a "glass-morphic" highlight for the active state—a slightly brighter blue tint with a 2px vertical "power line" on the left edge.