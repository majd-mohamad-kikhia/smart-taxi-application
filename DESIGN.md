---
name: Smart Taxi
description: A single dark, yellow-on-black Material 3 system for a company-run taxi app, shared by customers and drivers.
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
  text-tertiary: "#999DA6"
  nav-inactive: "#9CA3AF"
  on-yellow: "#374151"
  go-green: "#10B981"
  go-green-wash: "#123420"
  stop-red: "#EF4444"
  stop-red-deep: "#DC2626"
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
    backgroundColor: "{colors.stop-red-deep}"
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

Picture the inside of a cab at night: dark, quiet, and lit by one warm source, the meter or the roof sign. The whole app works that way. Near-black surfaces recede into a cabin, and a single yellow does the work of light. It tells a customer "this is your next action" and a driver "this is the number that matters". It is not decoration. Everything else is steel-gray text and tonal layers so that the yellow stays rare and means something.

The voice is calm, confident and utilitarian. This is the app a driver glances at mid-trip and a customer checks while waiting at a curb after dark, so it is built for scanning: big, filled, tactile controls, clear 1dp borders around cards, tabular figures for money and clocks, and status shown by color plus icon plus text, never by color alone. It rejects friendliness-by-decoration; trust comes from legibility and from never making fares or fees a surprise. The system is dark-only and is one identity for both the customer and driver roles.

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
- **Border Steel** (#34363B): card outlines, where the fill does the separating. **Control Edge** (#70747D, 3.5:1 on a surface, 4.1:1 on the page): the outline of an input or an outlined button, where the edge itself says it is a control.
- **Text Primary** (#F5F6F7), **Text Secondary** (#B4B8C0), **Text Tertiary** (#999DA6, 6.1:1 on Dash Surface, 5.2:1 on the muted fill, 4.7:1 on the yellow wash): the three text tiers; **Nav Inactive** (#9CA3AF) for inactive icons.

### Status
- **Error Text** (#F87171, 6:1 on a surface, 5.1:1 on the inset fill): errors as small text (a validation or failure line). The red (#EF4444) is for icons, borders and large figures; as 13px text on a surface it is only 4.4:1.
- **Go Green** (#10B981) with **Go-Green Wash** (#123420): success.
- **Stop Red** (#EF4444) with **Stop-Red Wash** (#3B1619): error icons, borders and status. **Stop-Red Deep** (#DC2626) is the solid fill behind white text on destructive actions (cancel, delete), because white on #EF4444 is only 3.8:1 and on #DC2626 it is 4.8:1.
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

Tonal layering with hairline borders; the system is flat at rest. Buttons, cards and the app bar all use elevation 0. The ladder is page (#0F1012) < surface (#1E1F22) < inset fill (#2A2C30), and a 1dp border separates cards from the page. Shadows appear only on things that float over other content: the bottom nav, the pill chips over the map, snack bars, and dialogs (which float over a 45% black scrim).

### Shadow Vocabulary
- **Nav lift** (`0 -3px 12px rgba(0,0,0,0.10)`): the bottom navigation bar's top edge.
- **Float chip** (`0 2px 6px rgba(0,0,0,0.04)`): fee and status pills over the map.
- **Toast** (`0 6px 16px rgba(0,0,0,0.20)`): snack bars.
- **Dialog** (`0 8px 24px rgba(0,0,0,0.20)` on a 1dp Border Steel card, over a 45% black scrim, no blur): branded dialogs. The shadow is neutral, never tinted with the tone color.

### Named Rules
**The Flat-At-Rest Rule.** A surface in a list or a stack gets a border, not a shadow. Shadow is a response to being above something else.

## Shapes

Generously rounded, solid forms. The scale is 12dp (controls, inputs, snack bars), 16dp (cards), 24dp (large containers), and fully round (badges, pills). The code also contains some off-scale radii (10, 14, 20, 22) in single widgets; treat 12/16/24/full as canonical for new work. Borders are 1dp Border Steel on cards and inputs, and 1.5dp on focused inputs (Meter Yellow) and outlined buttons (Amber). Status accents use a thin 4dp edge bar plus a tinted icon tile.

## Components

### Buttons
- **Shape:** 12dp corners, 14dp vertical and 24dp horizontal padding, full-width in forms and sheets.
- **Primary:** filled Meter Yellow with On-Yellow Slate text, Title weight (700). No elevation. The one dominant action per screen.
- **Outlined:** Amber 1.5dp outline and Amber text, transparent fill; the secondary action.
- **Destructive:** Stop-Red Deep fill with white text (disabled at 40% alpha); for cancel and delete. A sibling of the primary, not a variation of it.
- **Neutral ("Go back", "Log out"):** outlined in Border Steel with Text Primary, optionally with a leading icon and a spinner while loading. It is the safe way out beside a destructive or primary action, and the style for calm, reversible actions such as logging out. It never wears the accent or danger color. Red is reserved for permanent actions like deleting the account.
- **Loading:** the label is replaced by a 20dp spinner (2.2dp stroke), and the button is disabled.

### Cards / Containers
- **Corner Style:** 16dp.
- **Background:** Dash Surface, with a 1dp Border Steel outline and no shadow.
- **Internal Padding:** 12–16dp.
- **Live Fee Card:** a signature card for waiting and pause timers. The surface is tinted 8% with its accent color and given a 30% accent border. A header row has a 24dp state icon, the title, and the elapsed mm:ss clock (tabular, heavy, always left-to-right). When a price applies, the hero is a labeled "Fee so far" in Display Small, heavy and tabular, scaled down to fit rather than squeezing the card. Below it are a status line in Text Primary (not accent-colored) and a rules line in Text Secondary, up to two lines. State is never color alone: free time is Go Green with a timer or pause icon, and charging is Amber with a payments icon (red is never used for "charging"). When nothing is charged, the fee and rules are left out. Screen readers get one spoken summary with durations in words, plus a single announcement when charging starts and at each new billable minute.
- **Wallet Summary / Profile Card:** the places where the yellow-to-amber brand gradient fills a surface (the wallet statement summary and the profile avatar and badges). Use it for a hero summary, not for routine cards.

### Inputs / Fields
- **Style:** Dash Surface fill, 12dp corners, 1dp Border Steel outline, 16 by 14dp padding, Text Tertiary hints.
- **Focus:** the border becomes Meter Yellow at 1.5dp.
- **Error / Disabled:** the theme defines no custom error or disabled border, so these fall back to Material 3 defaults on the dark scheme (error uses the scheme's Stop Red). Decide and tokenize them in a future pass.

### Chips / Badges
- **Role Badge:** a full-round pill in Meter-Yellow Wash with a Meter Yellow role icon and label, plus an Amber swap icon and "change". The whole pill is one 48dp button with a ripple, and a screen reader reads the role and the action together.
- **Fee Chip:** a full-round pill floating over the map: Dash Surface at 92% with a 1dp Border Steel outline, a yellow 16dp icon, and a tabular Text Primary label, with the float-chip shadow. It is dark, like the rest of the app, so the light label and the yellow icon keep their contrast over the dark map. (An earlier white pill had near-white text on it and was unreadable.) The same widget is used for the "Track trip" label on the customer's tracking screen.

### Navigation
- **Bottom Nav:** a custom shared bar, at least 60dp tall (it grows with the system text size), in Dash Surface with a Hairline top edge and a soft lift shadow. The active tab is shown three ways: a 56×32 Amber-Wash pill behind a filled Amber icon, and a bolder label; inactive tabs are Nav Inactive gray on no pill. Each tab is a real button with "selected" semantics and no ripple (a splash on a bar you tap constantly is noise): when pressed, the icon and label ease in to 92% and back, and keyboard focus keeps a faint amber wash. Labels are one line with an ellipsis, and the pill color change and the press ease are skipped under reduced motion. Each role supplies its own items (customer and driver shells).
- **Lists:** loading shows a spinner under the last row; a failed "load more" shows a short footer ("Couldn't load more") with a real Retry button; the full-area empty and error states are a 64dp round icon tile, a centered message and, for errors, a Retry button.
- **App Bar:** Dash Surface, flat, Meter Yellow title at 18px/700, with a hairline shadow only when content scrolls beneath it. The shared brand bar is the exception: its wordmark is the app name at 24px/800 beside a 40dp logo, with a line height of 1 and the leading split evenly so the letters sit on the logo's vertical center.

### Feedback
- **Snack Bar:** a floating card at 12dp radius with Border Steel, a 4dp colored accent edge, a 36dp tinted icon tile and up to three lines of 600-weight text. Four tones: success, error, warning, info.
- **Branded Dialog:** a flat card with a 64dp round icon tile (accent icon on its wash), a Headline Medium title, a centered body message and a confirm / "Go back" pair. The confirm is a solid fill with a contrast-safe foreground per tone: Stop-Red Deep with white, Meter Yellow and Amber with On-Yellow Slate, Go Green with Cabin Black. Entrance is a quick fade with a slight scale (200ms ease-out, no overshoot) and is skipped under reduced motion. Nothing pulses. A dialog that sets its barrier non-dismissible also blocks the Android back button.
- **Choice Chip:** a full-round pill that is Inset Fill with a Border Steel outline when idle and Meter-Yellow Wash with a yellow check mark, border and label when selected; tap area 48dp.
- **Trip Actions (driver):** each phase has exactly one yellow primary: "I've arrived" at pickup, Start the trip once arrived, Finish while driving, Resume while paused. Cancel is a separate red-outlined button (red icon and border, label in Text Primary) on its own row or in its own half, never beside the primary at thumb width. Finish asks for a one-line confirmation before ending the trip. While an action is in flight every button dims and a thin yellow progress bar runs above them; labels never turn into spinners. Buttons that sit on the map take a solid Dash Surface fill.
- **Vehicle Sheet (customer):** the price moment. The sheet names the trip it prices (pickup, drop-off, distance and time) and lists every vehicle type as a selectable tile; choosing a tile only selects it (yellow wash, yellow border and a check icon), and one yellow "Request {vehicle} · {price}" button commits. A type that is unavailable or has no price cannot be chosen and says why in readable text with an icon, never by dimming the row. Prices are whole units with a thousands separator and tabular figures. The estimate note sits beside the button, the waiting and stop rules fold under "Fare details", and a sheet with nothing to book says so with a Close button. With exactly one bookable type it starts selected.
- **Payment Due (customer):** when the driver finishes, a blocking dialog says how much to pay. The amount is the hero, a heavy tabular figure with a thousands separator that scales down instead of wrapping, above the fare rows, and the dialog scrolls so nothing overflows at a large text size. A trip with no price from the server leaves the amount out rather than showing "0". The dialog has no buttons: it closes when the driver confirms payment. **Money** is in SYP only (there is no other currency in the app) and, across the customer trip, the driver's offer card and the shared fee widgets, whole units with a thousands separator (`formatPrice`); the driver wallet, profile and fare dialog and the customer trip list still show unformatted numbers. An estimated trip price carries the "(estimated price)" tag under it instead of a "~" prefix, which can land at the wrong end in Arabic.
- **Trip History (customer):** the record of a fare shows what the live flow showed. A card names when the trip happened ("Today, 1:00 PM", "27 Sep 2026, 1:00 PM"), its price with a thousands separator and tabular figures, and the route with a glyph and a spoken label for each point (From, Stop 1, To), never by dot color. A cancelled trip shows no price, and a trip that isn't finished shows its price as an estimate. The status badge is an icon and a word on the status's wash, with the label in the primary text color. On the details screen the price is the hero, labelled "Estimated price" or "Final price"; a completed trip then lists where it came from (trip fare, stops, waiting, pauses) and ends with a "Paid" or "Waiting for payment" line with an icon. Addresses and cancellation reasons are never cut short on the details screen. Times are shown as the server sends them, with no zone conversion.
- **Before Sign-In (customer and driver):** every screen before an account exists carries a one-tap language switch at its top end, showing the language it will switch to in that language ("English" or "العربية"), as an amber 48dp text button, so the language is never locked behind signing in. The role screen is a scrollable, width-capped column whose two cards are one mutually exclusive choice (button, checked or not) with a visible ripple; the driver card says drivers sign in to a company-created account rather than "join". Sign-in offers "Forgot your password? Contact support" under the password field, because customers have no reset flow and support is the way out.
- **Settings (customer and driver):** a settings screen is three groups, not eight loose controls: a heading, then its rows. Help (privacy, contact, report) is one bordered list of 56dp rows with a mirrored chevron; a control that is already a card (the language picker, the search-radius slider) sits under its own heading and is never wrapped in another card. The account actions close the screen, with the permanent one (delete) a full 24dp below logout. Logout, and its confirm, are neutral and yellow; red is only for deleting the account, whose dialog puts "Cancel" first and the red action second and enables it only once a password is typed. The profile card is flat (a border, no shadow, no gradient, no verified badge: there is no such field). Phone numbers and emails are left-to-right values inside Arabic text.
- **Forms:** the shared field submits on the keyboard's Done key, offers autofill hints, shows a problem the server reported under the field it belongs to (until that field is edited), and locks while saving. Phone fields clean what is typed or pasted (Arabic and Persian digits become 0-9; spaces, dashes and parentheses are dropped) and keep numbers and passwords left-to-right, at the start edge. A form with edits asks before it is left (a discard confirm in the warning tone), and Save works only while something differs from what is saved.
- **Notifications (customer):** an unread notification is on the yellow wash with a bold title and a "New" label with a dot, never color alone; the whole card is a button that marks it read and opens its trip. "Mark all as read" sits in the app bar while anything is unread, and the bell carries a count badge (9+ above nine) that is also in its spoken name.
- **Wallet (driver):** the balance is the hero: a heavy tabular figure with its currency set smaller on the same baseline, the pair centered in the card, under a caption and above a one-line meaning. A negative balance is just the figure with a real minus sign, with no extra warning line. A month loads behind a loader, never zeros; another month's numbers never stay under this month's label; a failure says so with a Retry. Money in or out is a sign, an icon and the type's name together, and the direction comes from the type, not from the amount's sign. A fine's full reason and the balance after each movement are shown. Only the balance is yellow: earnings are green, bonuses amber, fines red, the rest neutral.
- **Profile (driver):** a headline first (photo, name, and the account status as an icon and a word, with a line saying what an under-review, suspended or rejected status means), then the wallet balance as the one figure (drivers have no rating, so none is shown), then contact details and the vehicle. Rows read as a table: every label starts one column and every value another, at the same edge on each row, and they wrap instead of overflowing; a plate or phone is a left-to-right value that still starts at that edge; every vehicle state is spoken (loading, a failure with Retry, none registered).
- **Version Gates:** the blocking screens name their one fact first: when maintenance ends, as a person would say it ("Back: Today, 3:00 PM", or "Should be back any minute" once the time has passed), in a highlighted line. "Try again" says what it found (still down, or no connection). The Back button leaves the app. The optional-update dialog is decided only by its two buttons; the scrim, Back, or being replaced by a required update never count as "Later".
- **GPS Guard (driver):** the dialog that asks for location to be switched on is the branded dialog in the warning (amber) tone, named and announced as a dialog, because switching GPS on is something the driver can fix in a moment, not an error.
- **Splash:** the first Flutter frame is the logo on the same black as the native splash, with the taxi loading animation under it, shown at once and for as long as startup (settings, the saved session, the version check) takes; it carries no text. The real app then replaces it.
- **Route Tab (driver):** the private route recorder follows the same rules with its own wording: "Start recording" is the one yellow primary in idle and waiting ("I've arrived" is neutral), Finish route is yellow while recording and Resume is yellow while stopped (Pause and the other is neutral with a solid fill), and both Finish and the finished-phase "Start a new route" ask for confirmation. "Start a new route" is a neutral button, because it deletes the route and its summary from the phone, and its confirm says so. The top of the map always says where the recording stands: a lock chip in idle ("A private route, kept on this phone only"), the waiting or stop timer card, or a "Recording · 12:41 · 4.2 km" chip while driving.
- **Fare Dialog (driver):** leads with "Collect from the customer" and the amount as a heavy, tabular, scale-to-fit figure, then the driver's earnings on a Go-Green wash chip. The rest of the bill is folded under "Fare details". A failed payment confirmation shows in the shared error banner above the button, which then reads "Retry". After confirming, the dialog shows what was paid, the driver's share and the wallet balance, with Done.
- **Online Control (driver home):** a card that states where the driver stands and offers the one next action. Offline: a yellow "Go online". Connecting: an amber car tile (no spinner) and "Connecting…" with a neutral "Go offline". Online: a Go-Green-wash card with a green car tile, "You're online", and a neutral "Go offline". A failure shows its reason in the shared error banner, with a real "Open settings" button when the fix is in the device settings. The title is a live region, so a screen reader hears each change. Going offline while offers are on screen asks for confirmation first.
- **Offers while reconnecting:** the section under the control follows the connection: a hint while offline or failed, an icon placeholder reading "Connecting…" while connecting (no spinner), the offers while online. If the connection drops while offers are showing, they stay on screen under an amber "Reconnecting… these offers may be out of date" banner instead of vanishing. The Accept button being worked on stays full yellow with a visible spinner, and the other cards' buttons dim to muted yellow.

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
