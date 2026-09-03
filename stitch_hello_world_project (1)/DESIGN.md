---
name: Midnight Ledger
colors:
  surface: '#051424'
  surface-dim: '#051424'
  surface-bright: '#2c3a4c'
  surface-container-lowest: '#010f1f'
  surface-container-low: '#0d1c2d'
  surface-container: '#122131'
  surface-container-high: '#1c2b3c'
  surface-container-highest: '#273647'
  on-surface: '#d4e4fa'
  on-surface-variant: '#bdc8d1'
  inverse-surface: '#d4e4fa'
  inverse-on-surface: '#233143'
  outline: '#87929a'
  outline-variant: '#3e484f'
  surface-tint: '#7bd0ff'
  primary: '#8ed5ff'
  on-primary: '#00354a'
  primary-container: '#38bdf8'
  on-primary-container: '#004965'
  inverse-primary: '#00668a'
  secondary: '#bcc7de'
  on-secondary: '#263143'
  secondary-container: '#3e495d'
  on-secondary-container: '#aeb9d0'
  tertiary: '#c5cce6'
  on-tertiary: '#283044'
  tertiary-container: '#a9b1ca'
  on-tertiary-container: '#3c4459'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c4e7ff'
  primary-fixed-dim: '#7bd0ff'
  on-primary-fixed: '#001e2c'
  on-primary-fixed-variant: '#004c69'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#dae2fd'
  tertiary-fixed-dim: '#bec6e0'
  on-tertiary-fixed: '#131b2e'
  on-tertiary-fixed-variant: '#3f465c'
  background: '#051424'
  on-background: '#d4e4fa'
  surface-variant: '#273647'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  title-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1440px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style

This design system is built for high-productivity commerce environments that require extended focus and professional rigor. The brand personality is authoritative, precise, and tech-forward, utilizing a **Corporate Modern** style with a distinct **Tonal Layering** approach. 

The aesthetic avoids pure blacks to prevent eye strain, instead opting for a deep navy foundation that provides a more sophisticated, "pro-tier" atmosphere. Visual interest is generated through high-contrast interactions where vibrant light blue accents pierce the dark background, signifying action and system intelligence. The target audience—shopkeepers and portal managers—demands a UI that feels reliable, organized, and exceptionally clear.

## Colors

The palette is strictly curated to emphasize the portal's functional hierarchy. 

- **Primary (#38BDF8):** An electric light blue used exclusively for primary calls to action, active toggles, and critical status indicators.
- **Secondary (#1E293B):** Used for component surfaces like cards, input fields, and navigation sidebars to distinguish them from the background.
- **Tertiary (#0F172A):** The "True North" background color. All page-level surfaces use this deep navy to establish the base layer.
- **Neutral (#94A3B8):** A slate-grey used for secondary text, borders, and inactive icons to maintain a legible but non-distracting presence.

Functional colors for Error, Success, and Warning should be desaturated to fit the dark theme while maintaining high luminosity for accessibility.

## Typography

The design system utilizes **Manrope** across all roles to leverage its modern, geometric construction and excellent legibility in dark modes. 

- **Headlines:** Use Bold (700) or ExtraBold (800) weights with slight negative letter spacing to create a dense, authoritative "block" feel for section titles.
- **Body:** Standardized at 16px for readability. Use Medium (500) weight for emphasis within paragraphs rather than bolding, to keep the UI from feeling "heavy."
- **Labels:** All-caps styling should be reserved for the `label-md` tier, typically used for table headers and small metadata tags.

## Layout & Spacing

The design system follows an **8px linear scale**. Layouts are based on a 12-column fluid grid for the main content area, while the primary navigation is typically a fixed-width left sidebar (280px).

- **Margins:** Large 40px margins on desktop provide the necessary "breathing room" to make a data-heavy portal feel premium and organized.
- **Gutters:** Standard 24px gutters provide clear separation between dashboard widgets and data cards.
- **Mobile:** On devices, the layout collapses to a single column with 16px side margins. The sidebar transitions into a bottom navigation bar or a hidden drawer.

## Elevation & Depth

Depth is communicated through **Tonal Layers** and **Subtle Inner Glows** rather than heavy drop shadows.

- **Level 0 (Background):** Tertiary color (#0F172A).
- **Level 1 (Cards/Inputs):** Secondary color (#1E293B). 
- **Level 2 (Modals/Popovers):** A lighter shade of navy (#2D3748) with a 1px border using the Primary color at 20% opacity.

Instead of traditional shadows, use a 1px solid border (`#334155`) for all containers to ensure separation against the dark background. For "floating" elements like modals, apply a large, soft blur (32px) with a very low opacity (10%) of the Primary color to create a subtle blue ambient glow.

## Shapes

The design system uses a **Rounded (8px)** corner radius as the standard for all primary components (buttons, inputs, cards). This radius strikes a balance between the clinical feel of sharp corners and the overly casual feel of pill-shapes.

- **Small elements (Checkboxes, Tags):** Use `rounded-sm` (4px).
- **Large elements (Modals, Feature Cards):** Use `rounded-xl` (24px) to create a clear container hierarchy.
- **Interactive States:** Use a subtle scale-down (98%) on click/press to provide tactile feedback without relying on skeuomorphic textures.

## Components

- **Buttons:** Primary buttons use the Light Blue (#38BDF8) with dark text (#0F172A) for maximum contrast. Secondary buttons are outlined with a 1px border of the Primary color.
- **Input Fields:** Dark surfaces (#1E293B) with a subtle bottom border. On focus, the entire border transitions to the Primary Light Blue with a 2px stroke.
- **Chips/Tags:** Used for status (e.g., "Shipped," "Pending"). These should be semi-transparent versions of the status color with high-saturation text to maintain the dark-mode aesthetic.
- **Lists/Tables:** Use Zebra-striping sparingly. Prefer thin dividers (#1E293B) and high-contrast typography for headers.
- **Cards:** Dashboard widgets should have a consistent padding of 24px. Use "Midnight" iconography (linear, 2px stroke) in the Primary color to maintain visual consistency.
- **Data Visualizations:** Charts and graphs must use a palette of blues and teals, avoiding warm colors unless indicating a critical error or system warning.