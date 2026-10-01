---
name: Smart Taxi
description: A single dark, yellow-on-black Material 3 system for a company-run taxi app, shared by riders and drivers.
colors:
  meter-yellow: "#FFD600"
  meter-yellow-wash: "#3A3216"
  amber: "#F59E0B"
  amber-wash: "#3D2A14"
  cabin-black: "#0F1012"
  dash-surface: "#1E1F22"
  inset-fill: "#2A2C30"
  hairline: "#26282C"
  border-steel: "#34363B"
  text-primary: "#F5F6F7"
  text-secondary: "#B4B8C0"
  text-tertiary: "#7D818A"
  nav-inactive: "#9CA3AF"
  on-yellow: "#374151"
  go-green: "#10B981"
  go-green-wash: "#123420"
  stop-red: "#EF4444"
  stop-red-wash: "#3B1619"
  route-blue: "#3B82F6"
typography:
  display:
    fontFamily: "Tajawal, sans-serif"
    fontSize: "32px"
    fontWeight: 800
  headline:
    fontFamily: "Tajawal, sans-serif"
    fontSize: "22px"
    fontWeight: 700
  title:
    fontFamily: "Tajawal, sans-serif"
    fontSize: "16px"
    fontWeight: 600
  body:
    fontFamily: "Tajawal, sans-serif"
    fontSize: "14px"
    fontWeight: 400
  label:
    fontFamily: "Tajawal, sans-serif"
    fontSize: "12px"
    fontWeight: 500
  figure:
    fontFamily: "Tajawal, sans-serif"
    fontSize: "26px"
    fontWeight: 800
    fontFeature: "tnum"
rounded:
  md: "12px"
  lg: "16px"
  xl: "24px"
  full: "100px"
spacing:
  xs: "4px"
  s: "8px"
  m: "12px"
  l: "16px"
  xl: "20px"
  xxl: "24px"
components:
  button-primary:
    backgroundColor: "{colors.meter-yellow}"
    textColor: "{colors.on-yellow}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: "14px 24px"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.amber}"
    rounded: "{rounded.md}"
    padding: "14px 24px"
  button-destructive:
    backgroundColor: "{colors.stop-red}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "14px 24px"
  input-field:
    backgroundColor: "{colors.dash-surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "14px 16px"
  card:
    backgroundColor: "{colors.dash-surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    padding: "16px"
  role-badge:
    backgroundColor: "{colors.meter-yellow-wash}"
    textColor: "{colors.meter-yellow}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "8px 12px"
  bottom-nav:
    backgroundColor: "{colors.dash-surface}"
    textColor: "{colors.nav-inactive}"
    height: "60px"
---

# Design System: Smart Taxi

## Overview

**Creative North Star: "The Meter Light"**

Picture the inside of a cab at night: dark, quiet, and lit by one warm source, the meter or the roof sign. The whole app works that way. Near-black surfaces recede into a cabin, and a single yellow does the work of light. It tells a rider "this is your next action" and a driver "this is the number that matters". It is not decoration. Everything else is steel-gray text and tonal layers so that the yellow stays rare and means something.

The voice is calm, confident and utilitarian. This is the app a driver glances at mid-trip and a rider checks while waiting at a curb after dark, so it is built for scanning: big, filled, tactile controls, clear 1dp borders around cards, tabular figures for money and clocks, and status shown by color plus icon plus text, never by color alone. It rejects friendliness-by-decoration; trust comes from legibility and from never making fares or fees a surprise. The system is dark-only and is one identity for both the rider and driver roles.

It is a Material 3 system, themed rather than replaced: the theme builds a dark `ColorScheme` seeded from the yellow, with Tajawal as the type face, so Arabic and Latin text share one design. Layout is direction-aware, so everything mirrors in RTL.

**Key Characteristics:**
- One dark theme; yellow `#FFD600` is the single dominant signal, amber `#F59E0B` its secondary.
- Depth by tonal layering and hairline borders, not shadows.
- Filled, generously rounded (12–16dp) controls with large touch areas.
- Tajawal throughout, with heavy weights (700–800) for figures and headings.
- Semantic color always paired with an icon or label.

## Colors

A near-black cabin with warm yellow light: restrained neutrals, one loud primary, and three status colors used only for status.

### Primary
- **Meter Yellow** (#FFD600): the one signal color. Primary buttons, focused input borders, active-trip emphasis, app bar titles, the planned route line on the map, and the loader. Always carries dark text (**On-Yellow Slate**, #374151) because white is unreadable on it.
- **Meter-Yellow Wash** (#3A3216): the quiet tint behind yellow content, such as the role badge, so yellow text and icons sit on a surface and not on pure black.

### Secondary
- **Amber** (#F59E0B): navigation active state, outlined buttons, text links, the warning status, and the second stop of the brand gradient. It is amber, never orange-red.
- **Amber Wash** (#3D2A14): tint for amber-toned surfaces.

### Neutral
- **Cabin Black** (#0F1012): the page. The darkest layer.
- **Dash Surface** (#1E1F22): cards, app bar, inputs, bottom nav. One step lighter than the page.
- **Inset Fill** (#2A2C30): chips, pills and inset fills that sit on top of a surface.
- **Hairline** (#26282C): dividers and the nav's top edge.
- **Border Steel** (#34363B): card and input outlines.
- **Text Primary** (#F5F6F7), **Text Secondary** (#B4B8C0), **Text Tertiary** (#7D818A): the three text tiers; **Nav Inactive** (#9CA3AF) for inactive icons.

### Status
- **Go Green** (#10B981) with **Go-Green Wash** (#123420): success.
- **Stop Red** (#EF4444) with **Stop-Red Wash** (#3B1619): errors and destructive actions (cancel, delete).
- **Route Blue** (#3B82F6): the driven route on the map, so it can be told apart from the yellow planned route.

### Named Rules
**The One Light Rule.** Yellow is the only light in the cabin. If a screen has more than a few yellow things, one of them has stopped meaning "act here" or "this is the number". The page, surfaces and text carry everything else.

**The Wash Rule.** Colored content sits on its tinted wash (yellow on yellow-wash, red on red-wash), never directly on black, so tint and tier stay legible.

**The Paired Signal Rule.** Status is never color alone. Pair green, red and amber with an icon and a word, because the user may be glancing in sunlight or color-blind.

## Typography

**Display, Body and Label Font:** Tajawal (with the platform sans-serif fallback). One family for everything; it renders Arabic and Latin with the same rhythm.

**Character:** Geometric, sturdy and sober, with enough weight range to make a fare read from an arm's length. Hierarchy is made from weight and size, not from a second family.

### Hierarchy
- **Display** (800, 32px): rare; hero numbers and screen titles that need to dominate.
- **Headline** (700, 22px): screen and section headings (Headline Medium is 20px/600, Small is 18px/600; the app bar title is 18px/700 in Meter Yellow).
- **Title** (600, 16px): card titles and primary-button labels (Title Medium 15px, Small 14px/500).
- **Body** (400, 14px; large 16px): paragraphs and list text. Body Medium is Text Secondary; Body Small (12px) is Text Tertiary.
- **Label** (500–600, 11–14px): chips, captions, nav labels.
- **Figure** (800, 26px, tabular numerals): clocks (mm:ss) and money in live fee cards. Tabular figures keep timers from jittering.

### Named Rules
**The Tabular Money Rule.** Anything that counts or sums (timers, fares, fees, earnings) uses tabular figures and the heaviest weight in its row, so digits do not shift and the number is the first thing read.

## Layout

Phone-first single column with a bottom navigation shell for each role. Content stacks in cards on the Cabin Black page. Spacing follows a 4-based scale (4, 8, 12, 16, 20, 24), with 12 and 16 doing most of the work: 16 for screen gutters and card padding, 12 and 8 inside rows and between related items. Overlays and snack bars cap at about 480dp wide so they stay readable on tablets and large screens. All horizontal spacing must be direction-aware so layouts mirror correctly in Arabic RTL.

## Elevation & Depth

Tonal layering with hairline borders; the system is flat at rest. Buttons, cards and the app bar all use elevation 0. The ladder is page (#0F1012) < surface (#1E1F22) < inset fill (#2A2C30), and a 1dp border separates cards from the page. Shadows appear only on things that float over other content: the bottom nav, the pill chips over the map, snack bars, and the dialog scrim.

### Shadow Vocabulary
- **Nav lift** (`0 -3px 12px rgba(0,0,0,0.10)`): the bottom navigation bar's top edge.
- **Float chip** (`0 2px 6px rgba(0,0,0,0.04)`): fee and status pills over the map.
- **Toast** (`0 6px 16px rgba(0,0,0,0.20)`): snack bars.
- **Dialog scrim** (black at 45% plus a 4px blur): the backdrop of branded dialogs.

### Named Rules
**The Flat-At-Rest Rule.** A surface in a list or a stack gets a border, not a shadow. Shadow is a response to being above something else.

## Shapes

Generously rounded, solid forms. The scale is 12dp (controls, inputs, snack bars), 16dp (cards), 24dp (large containers), and fully round (badges, pills). The code also contains some off-scale radii (10, 14, 20, 22) in single widgets; treat 12/16/24/full as canonical for new work. Borders are 1dp Border Steel on cards and inputs, and 1.5dp on focused inputs (Meter Yellow) and outlined buttons (Amber). Status accents use a thin 4dp edge bar plus a tinted icon tile.

## Components

### Buttons
- **Shape:** 12dp corners, 14dp vertical and 24dp horizontal padding, full-width in forms and sheets.
- **Primary:** filled Meter Yellow with On-Yellow Slate text, Title weight (700). No elevation. The one dominant action per screen.
- **Outlined:** Amber 1.5dp outline and Amber text, transparent fill; the secondary action.
- **Destructive:** Stop Red fill with white text (disabled at 40% alpha); for cancel and delete. A sibling of the primary, not a variation of it.
- **Loading:** the label is replaced by a 20dp spinner (2.2dp stroke), and the button is disabled.

### Cards / Containers
- **Corner Style:** 16dp.
- **Background:** Dash Surface, with a 1dp Border Steel outline and no shadow.
- **Internal Padding:** 12–16dp.
- **Live Fee Card:** a signature card for waiting and pause timers. The surface is tinted 8% with its accent color and given a 30% accent border, a 28dp icon, a Figure-style mm:ss clock, a colored status line and an optional rules line.
- **Wallet Summary / Profile Card:** the places where the yellow-to-amber brand gradient fills a surface (the wallet statement summary, profile avatar and badges, and the primary-tone dialog icon). Use it for a hero summary, not for routine cards.

### Inputs / Fields
- **Style:** Dash Surface fill, 12dp corners, 1dp Border Steel outline, 16 by 14dp padding, Text Tertiary hints.
- **Focus:** the border becomes Meter Yellow at 1.5dp.
- **Error / Disabled:** the theme defines no custom error or disabled border, so these fall back to Material 3 defaults on the dark scheme (error uses the scheme's Stop Red). Decide and tokenize them in a future pass.

### Chips / Badges
- **Role Badge:** pill (full radius) in Meter-Yellow Wash with a Meter Yellow icon and label, plus an Amber "change" action.
- **Fee Chip:** a white 95% pill with a 20dp radius and a tiny shadow, used on the map. A light chip on a dark app is intentional so it stays legible over map tiles.

### Navigation
- **Bottom Nav:** a custom shared bar, 60dp tall, in Dash Surface with a Hairline top edge and a soft lift shadow. Active items are Amber (icon swap with a 200ms switcher, weight 600); inactive items are Nav Inactive gray. Each role supplies its own items (rider and driver shells).
- **App Bar:** Dash Surface, flat, Meter Yellow title at 18px/700, with a hairline shadow only when content scrolls beneath it.

### Feedback
- **Snack Bar:** a floating card at 12dp radius with Border Steel, a 4dp colored accent edge, a 36dp tinted icon tile and up to three lines of 600-weight text. Four tones: success, error, warning, info.
- **Branded Dialog:** a scale-and-fade entrance (about 380ms, easeOutBack) over a blurred, 45% black scrim, with tones for destructive, primary, success and warning.

### Map
- The map uses a dark map style. The planned route is Meter Yellow and the driven route is Route Blue. Live fee chips float above it.

## Do's and Don'ts

### Do:
- **Do** keep Meter Yellow rare: one primary action per screen, plus the few places that mean "this is the number".
- **Do** put dark text (On-Yellow Slate #374151) on yellow, always.
- **Do** build from the existing tokens (`AppColors`, `AppConstants` radii and padding, and the theme's text roles) and reuse the widgets in `core/widgets/` before creating new ones.
- **Do** pair every status color with an icon and a label.
- **Do** use tabular figures and heavy weight for money and clocks.
- **Do** use direction-aware spacing and alignment so every screen mirrors correctly in Arabic.
- **Do** keep touch targets at 48dp or more, with at least 8dp between them.
- **Do** show loading, success and error states on every async surface.

### Don't:
- **Don't** introduce a light theme or invert colors; the system is dark-only (`AppTheme.darkTheme`).
- **Don't** hardcode hex colors or `Colors.*` (including `Colors.white`, `Colors.black` and `Colors.transparent`) anywhere outside `AppColors`. Every painted color is a named token there; add one if a needed color is missing.
- **Don't** add drop shadows to cards in lists; use the border.
- **Don't** use gradients on routine surfaces. The yellow-to-amber gradient is reserved for hero summaries and brand accents.
- **Don't** hand-pick font sizes per widget; map text to the theme's roles. (Many widgets hardcode 11–15px today; new work should not.)
- **Don't** convey state by color alone.
- **Don't** use orange-red or another warm color that could be read as the error color. Amber is the warning color, and red is only for errors and destructive actions.
- **Don't** stack primary buttons; one primary action per view.
