# Unifyr Design System — "Fluent" (Outlook design language)

Adopted 2026-07-23/24, replacing the "Serene" identity. The visual language
follows Microsoft Outlook for Mac's layout patterns — brand title bar, module
icon rail, nav pane, command bar, floating white pane cards — implemented
entirely with original assets (SF Symbols, system fonts; no Microsoft-owned
artwork anywhere in the repo).

## The one rule

**Every color, font, radius, spacing, and chrome metric comes from
`Unifyr/Unifyr/Theme/Theme.swift`.** No hex literals, no ad-hoc point sizes in
views. If a value you need doesn't exist, add a token first.

## Token source and its two mirrors

`Theme.swift` is canonical, but two WebKit surfaces re-declare values Xcode
cannot check. **Any palette change must be applied in all three places:**

1. `Unifyr/Unifyr/Theme/Theme.swift` — `Theme.Palette` / `Font` / `Spacing` /
   `Radius` / `Metrics` / `Shadow` / `Motion`.
2. `Unifyr/Unifyr/Editor/editor.css` — `:root` block + the dark-mode
   `@media` override (`--hv-text`, `--hv-secondary`, `--hv-rule`,
   `--hv-code-bg`, `--hv-accent`). The `--hv-*` names and the
   `window.hyperview` JS namespace must never be renamed (see
   memory/unifyr-rename).
3. `Unifyr/Unifyr/Mail/MailBodyWebView.swift` — the inline `<style>` paper
   CSS. The mail body is ALWAYS white paper in both appearances; never
   auto-darken it.

## Palette essentials

- `primary` #0F6CBD (dark #479EF5) — links, selection text/icons, counts,
  "+ Add" actions. `primaryFill` (#0F6CBD / dark #115EA3) — title bar,
  primary buttons; pair with `textOnAccent`.
- Two accent channels, never merged: `primary` for ordinary UI,
  **`claude` (amber, #B45309 / dark #F2A65A) exclusively for AI surfaces**
  (chat, briefing, Ask Claude); filled amber controls use `textOnClaude`.
- **No green** in chrome: `success == primary`. The single sanctioned green
  is `smsGreen` (iMessage SMS-bubble semantics).
- Surfaces: `windowBackground` (wash) · `pane` (white cards) · `rail` ·
  `navPane` · `commandBar` · `secondaryChrome` (record-editor strip) ·
  `selected` · `hover`. Borders: `separator` (1px rules) /
  `separatorStrong` (grids).
- Calendar: `eventChip`/`eventChipText` (peach), `indicatorNow` (= primary).
- Mail reading pane: `mailPaper`/`mailPaperText`, fixed light.

## Typography

Outlook scale — caption 11 · label 12 · body 13 · bodyStrong 13sb ·
subtitle 15sb · title 17sb · display 22sb — mapped to **semantic** SwiftUI
styles per platform (`Theme.Font.*`) so Dynamic Type keeps working. Never
introduce `.font(.system(size:))` for text; icon glyph sizing may use
`Theme.Metrics.iconInline` (16) / `iconToolbar` (20).

## Geometry

Spacing 2/4/8/12/16/20/24/32 (`Theme.Spacing`). Radii: `sm` 4 (rows, chips,
inputs) · `md` 6 (buttons, popovers, menus) · `lg` 8 (panes, rail tile) ·
`pill`. Chrome metrics in `Theme.Metrics`: title bar 48, command bar 44,
rail 64, nav pane 240, control 28, button 32, rows 28/32, pane gutter 8.

## Elevation & motion

Panes are FLAT: 1px `separator` border + the wash gutter — no shadows.
The only shadows are `Shadow.popover` (menus/popovers/quick-create) and
`Shadow.raised` (selected segment pill). Motion: `Motion.hover` (100ms) /
`Motion.surface` (150ms); nothing above 200ms; respect Reduce Motion
(`accessibilityReduceMotion`) at every animated call site.

## Component library (`Theme/Components.swift` + `App/AppShell.swift`)

Shell: `AppTitleBar`, `ModuleRail`, `paneCard()`.
Controls: `.fluentPrimary` / `.fluentSecondary` / `.fluentToolbar` /
`.fluentClaude` button styles, `CommandBar`, `FluentSegmentedControl`,
`FluentSearchField` (+ `CompactSearchable` for iPhone nav-bar search),
`FluentListRow`, `FluentRowCount`, `FluentAddLink`,
`FluentCollapsibleSection`, `FluentEmptyState` (list `compact:` and detail
variants), `FluentFormField` (underlined, `secure:` supported),
`RecordEditorChrome` (blue `Title • account` band + gray command strip —
**always a styled sheet, never a real window** — owner decision 2026-07-23),
`QuickCreateCard` (popover form with More options/Discard/Save footer),
`MiniMonthCalendar`, `fluentHover()`.

Never build a bespoke variant of any of these; extend the component.

## Layout conventions

- Regular widths (Mac, iPad): Outlook chrome — title bar, rail, module
  content as one floating pane card; module nav panes at
  `Metrics.navPaneWidth` on `Palette.navPane` with a hamburger + filled
  primary-action button header; command bar spans nav + content.
- iPhone (`\.isCompactLayout`): stacked navigation, native toolbars and
  `.searchable`, same tokens. The Outlook chrome is never rendered compact.
- Disabled command-bar actions render in `textTertiary` — visible, not
  hidden.

## Known, deliberate exceptions

- WebDAV `ConnectServerSheet` remains a grouped `Form` (platform-idiomatic
  connection dialog).
- Clock's and the Databases view-mode switchers keep the native segmented
  picker (icon-bearing segments; `FluentSegmentedControl` is text-only).
- `PhotosCard`'s heart glyph keeps a 2pt legibility shadow over photos
  (function, not elevation).
- Dense grid micro-type (9–11pt in Calendar/Messages/Clock/Drive glyph
  labels) still uses a handful of fixed sizes; shrink this list over time —
  do not grow it.
- Syntax-highlight colors in `editor.css` (`.hljs-*`) are data colors, not
  chrome.

## Adding new UI — checklist

1. Colors/fonts/radii/spacing only via `Theme.*`; components via
   `Components.swift`.
2. Both appearances checked (dark values are tuned, not inverted).
3. WCAG AA contrast; focus order and VoiceOver labels; Reduce Motion.
4. Compact layout path exists and uses native navigation.
5. If it's a create/edit surface: `QuickCreateCard` (light, in-context) or
   `RecordEditorChrome` (full record) — not a bespoke sheet.
