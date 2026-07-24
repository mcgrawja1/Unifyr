//
//  Theme.swift
//  Unifyr — "Fluent" visual identity (Outlook-for-Mac design language, 2026-07-23)
//
//  D11 / §8 — the ONLY place a color, font, radius, spacing, or metric constant
//  may be defined. Every view reads from `Theme`.
//
//  Rules:
//   • Two accent CHANNELS, never merged:
//       Palette.primary — ordinary interactive elements (links, selection,
//       accent text, badges); Palette.primaryFill for filled chrome (title
//       bar, primary buttons) with `textOnAccent` on top.
//       Palette.claude  — AI surfaces ONLY (chat, daily briefing, Ask Claude).
//   • NO GREEN: success/done is intentionally the SAME blue as `primary`.
//   • Dark mode first-class — every token has its own dark value (brand blue
//     lightens to keep AA contrast on dark surfaces).
//   • Mail reading pane is ALWAYS white paper (`mailPaper`/`mailPaperText`).
//   • Panes are white cards on the window wash: 1px `border` + gutter, no
//     shadows. Shadows exist only on popovers/menus/detached-style sheets.
//
//  ⚠️ WEB MIRRORS — changing a value here requires updating the SAME value in:
//     1. Unifyr/Unifyr/Editor/editor.css   (`:root` block + dark `@media`)
//     2. Unifyr/Unifyr/Mail/MailBodyWebView.swift (inline <style> paper CSS)
//     Xcode will not flag drift; grep for the old hex when editing.
//

import SwiftUI

/// Namespaced design tokens. Purely static — no state, no instances.
enum Theme {

    // MARK: - Color palette (Fluent)

    enum Palette {
        // Brand
        /// Primary interactive accent — links, selected text/icons, counts,
        /// "+ Add …" actions. Lightens in dark mode for contrast.
        static let primary = Color(
            light: Color(hex: 0x0F6CBD),
            dark: Color(hex: 0x479EF5)
        )
        /// Filled brand chrome — title bar, primary buttons, active-rail tile
        /// icon backgrounds. Always paired with `textOnAccent`.
        static let primaryFill = Color(
            light: Color(hex: 0x0F6CBD),
            dark: Color(hex: 0x115EA3)
        )
        /// Hover/pressed state of `primaryFill`.
        static let primaryFillHover = Color(
            light: Color(hex: 0x115EA3),
            dark: Color(hex: 0x0F548C)
        )
        /// Reserved exclusively for Claude / AI surfaces — amber, retuned to
        /// sit against the Fluent blue (AA on white; original warmth in dark).
        static let claude = Color(
            light: Color(hex: 0xB45309),
            dark: Color(hex: 0xF2A65A)
        )

        // Surfaces
        /// App wash behind panes (the visible gutter between cards).
        static let windowBackground = Color(
            light: Color(hex: 0xF3F3F3),
            dark: Color(hex: 0x1B1A19)
        )
        /// White content cards / panes.
        static let pane = Color(
            light: Color(hex: 0xFFFFFF),
            dark: Color(hex: 0x252423)
        )
        /// Far-left module icon rail.
        static let rail = Color(
            light: Color(hex: 0xF0F0F0),
            dark: Color(hex: 0x201F1E)
        )
        /// Second-column navigation pane (folders, page tree, lists).
        static let navPane = Color(
            light: Color(hex: 0xF5F5F5),
            dark: Color(hex: 0x201F1E)
        )
        /// Toolbar strip under the title bar.
        static let commandBar = Color(
            light: Color(hex: 0xFFFFFF),
            dark: Color(hex: 0x292827)
        )
        /// Gray command strip in record-editor sheets (detached-window look).
        static let secondaryChrome = Color(
            light: Color(hex: 0xE8E8E8),
            dark: Color(hex: 0x3B3A39)
        )
        /// Selected list-row fill.
        static let selected = Color(
            light: Color(hex: 0xEAF2FB),
            dark: Color(hex: 0x1E3A5F)
        )
        /// Row / toolbar-button hover fill.
        static let hover = Color(
            light: Color(hex: 0xF0F0F0),
            dark: Color(hex: 0x323130)
        )

        // Text
        static let textPrimary = Color(
            light: Color(hex: 0x242424),
            dark: Color(hex: 0xF3F2F1)
        )
        static let textSecondary = Color(
            light: Color(hex: 0x616161),
            dark: Color(hex: 0xB3B0AD)
        )
        /// Placeholders, disabled controls, out-of-month dates.
        static let textTertiary = Color(
            light: Color(hex: 0x9A9A9A),
            dark: Color(hex: 0x797775)
        )
        static let textOnAccent = Color(hex: 0xFFFFFF)

        // Borders
        /// Pane separators, dividers, field underlines.
        static let separator = Color(
            light: Color(hex: 0xE5E5E5),
            dark: Color(hex: 0x3B3A39)
        )
        /// Grid lines, control outlines (calendar day lines, table grids).
        static let separatorStrong = Color(
            light: Color(hex: 0xD1D1D1),
            dark: Color(hex: 0x504F4D)
        )

        // Semantic
        /// Success/done — intentionally the SAME blue as `primary` (no green).
        static let success = primary
        static let warning = Color(
            light: Color(hex: 0x9D5D00),
            dark: Color(hex: 0xF7B955)
        )
        static let danger = Color(
            light: Color(hex: 0xC50F1F),
            dark: Color(hex: 0xF1707B)
        )

        // Calendar
        /// Default event chip (Outlook peach) + its text.
        static let eventChip = Color(
            light: Color(hex: 0xF8C9A6),
            dark: Color(hex: 0x6E4A26)
        )
        static let eventChipText = Color(
            light: Color(hex: 0x3B2A1C),
            dark: Color(hex: 0xF5D9BC)
        )
        /// Current-time line + dot.
        static let indicatorNow = primary

        // Fixed (both appearances): the email reading pane is white paper.
        static let mailPaper = Color(hex: 0xFFFFFF)
        static let mailPaperText = Color(hex: 0x242424)

        // MARK: Legacy aliases (Serene names still used across modules;
        // retire during Phase 5 cleanup — do not add new call sites).

        /// Old "app background". Panes stay white; the window wash is
        /// `windowBackground`.
        static let background = pane
        static let surface = pane
        static let surfaceRaised = hover
    }

    // MARK: - Typography
    //
    // Outlook scale: caption 11 · label 12 · body 13 · bodyStrong 13sb ·
    // subtitle 15sb · title 17sb · display 22sb.
    // Mapped to SEMANTIC styles per platform so Dynamic Type / text scaling
    // keeps working (the defaults land exactly on the Outlook pixel sizes).

    enum Font {
        #if os(macOS)
        /// 11 — timestamps, badges, metadata.
        static let caption = SwiftUI.Font.subheadline
        /// 12 — field labels, secondary rows.
        static let label = SwiftUI.Font.callout
        /// 13 — default body.
        static let body = SwiftUI.Font.body
        /// 13 semibold — emphasis, section headers in nav panes.
        static let bodyStrong = SwiftUI.Font.body.weight(.semibold)
        /// 15 semibold — pane headlines, empty-state titles.
        static let subtitle = SwiftUI.Font.title3.weight(.semibold)
        /// 17 semibold — view titles.
        static let title = SwiftUI.Font.title2.weight(.semibold)
        /// 22 semibold — display headings (dashboard greeting).
        static let display = SwiftUI.Font.title.weight(.semibold)
        #else
        static let caption = SwiftUI.Font.caption2
        static let label = SwiftUI.Font.caption
        static let body = SwiftUI.Font.footnote
        static let bodyStrong = SwiftUI.Font.footnote.weight(.semibold)
        static let subtitle = SwiftUI.Font.subheadline.weight(.semibold)
        static let title = SwiftUI.Font.body.weight(.semibold)
        static let display = SwiftUI.Font.title2.weight(.semibold)
        #endif

        /// Monospace — briefing action-items block, code.
        static let mono = SwiftUI.Font.system(.body, design: .monospaced)

        // MARK: Legacy aliases (retire in Phase 5).
        static let dashboardTitle = display
        static let cardTitle = bodyStrong
        static let cardBody = body
        static let cardCaption = label
        static let metricNumber = SwiftUI.Font.system(.title, design: .default).weight(.semibold)
    }

    // MARK: - Spacing (4pt grid + Outlook's 20)

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let lg2: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner radii

    enum Radius {
        /// List rows, chips, inputs, toolbar-button hover tiles.
        static let sm: CGFloat = 4
        /// Buttons, popovers, cards-within-panes, menus.
        static let md: CGFloat = 6
        /// Panes (the floating white cards) and the active rail tile.
        static let lg: CGFloat = 8
        static let pill: CGFloat = 999

        // Legacy aliases (retire in Phase 5).
        static let card: CGFloat = lg
        static let control: CGFloat = md
    }

    // MARK: - Fixed chrome metrics (Outlook shell geometry)

    enum Metrics {
        static let titleBarHeight: CGFloat = 48
        static let commandBarHeight: CGFloat = 44
        static let railWidth: CGFloat = 64
        static let navPaneWidth: CGFloat = 240
        /// Standard control height (inputs, segmented controls).
        static let controlHeight: CGFloat = 28
        /// Primary/secondary buttons.
        static let buttonHeight: CGFloat = 32
        static let listRowHeight: CGFloat = 28
        static let listRowHeightRelaxed: CGFloat = 32
        /// Gap between floating panes.
        static let paneGutter: CGFloat = 8
        static let iconInline: CGFloat = 16
        static let iconToolbar: CGFloat = 20
    }

    // MARK: - Elevation
    //
    // Panes: NO shadow — 1px separator border + the window-wash gutter.
    // Popovers/menus/record-editor sheets: the one allowed shadow.

    enum Shadow {
        /// Popover / menu / quick-create-card elevation.
        static let popover = (color: Color.black.opacity(0.14), radius: CGFloat(16), y: CGFloat(4))
        /// Barely-raised chrome (the selected segment pill).
        static let raised = (color: Color.black.opacity(0.10), radius: CGFloat(2), y: CGFloat(1))
        /// Legacy card shadow — Fluent panes are flat; kept for old call
        /// sites, now renders nothing (retire in Phase 5).
        static let card = (color: Color.clear, radius: CGFloat(0), y: CGFloat(0))
    }

    // MARK: - Motion (100ms hover, 150ms surfaces; nothing over 200ms.
    // Call sites must respect Reduce Motion via `accessibilityReduceMotion`.)

    enum Motion {
        static let hover = Animation.easeOut(duration: 0.10)
        static let surface = Animation.easeOut(duration: 0.15)
    }
}

// MARK: - Color helpers (kept here so no view constructs a raw color)

extension Color {
    /// Resolves to `light` or `dark` with the current appearance.
    init(light: Color, dark: Color) {
        #if os(macOS)
        self = Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        })
        #else
        self = Color(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
        #endif
    }

    /// Build a color from a 24-bit hex literal, e.g. `Color(hex: 0x0F6CBD)`.
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// Parse "#RRGGBB" (leading # optional). Nil for anything else.
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        self.init(hex: value)
    }

    /// "#RRGGBB" of this color in sRGB (for persisting user-picked colors).
    var hexRGB: String? {
        #if os(macOS)
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int((c.redComponent * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
        #endif
    }

    /// Soft accent fill for selected rows / active nav (Fluent's
    /// `surface.selected` derives from this where a tinted fill is needed).
    func softFill(_ opacity: Double = 0.16) -> Color { self.opacity(opacity) }
}
