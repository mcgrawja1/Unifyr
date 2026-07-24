//
//  AppShell.swift
//  Unifyr
//
//  Outlook-style application chrome (regular-width layouts — Mac and iPad):
//  a brand title bar with the centered search pill, the far-left module icon
//  rail, and the floating-pane card treatment for module content. iPhone keeps
//  its stacked navigation and receives only the styling (see ContentView).
//
//  Deliberate omissions (design-language elements with no existing feature
//  behind them — adding them would be new behavior, not a reskin):
//   • the rail's global "+" quick-create button
//   • the title-bar notification bell
//

import SwiftUI

// MARK: - Title bar

/// Full-width brand band: 48pt, `primaryFill`, centered pill search field.
/// On macOS the native title bar is hidden and the traffic lights float over
/// this band, so it stays draggable and clears their footprint.
struct AppTitleBar: View {
    @Binding var showingSearch: Bool

    /// Clearance so the centered pill never sits under the macOS traffic
    /// lights (or looks cramped on iPad).
    private var edgeClearance: CGFloat { Theme.Spacing.xxl + Theme.Metrics.railWidth }

    var body: some View {
        ZStack {
            Button {
                showingSearch = true
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: Theme.Metrics.iconInline, weight: .regular))
                    Text("Search")
                        .font(Theme.Font.body)
                }
                .foregroundStyle(Theme.Palette.textOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.Metrics.controlHeight)
                .background(
                    Capsule().fill(Theme.Palette.textOnAccent.opacity(0.16))
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)
            .help("Search Unifyr (⌘K)")
            .accessibilityLabel("Search Unifyr")
            .frame(maxWidth: 720)
            .padding(.horizontal, edgeClearance)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Theme.Metrics.titleBarHeight)
        .background(Theme.Palette.primaryFill)
        #if os(macOS)
        .gesture(WindowDragGesture())
        #endif
    }
}

// MARK: - Module icon rail

/// Far-left fixed 64pt rail: one icon per module. Active module wears a
/// pane-colored rounded tile with the brand icon; the Claude item keeps its
/// amber channel when inactive.
struct ModuleRail: View {
    @Binding var selection: SidebarItem?
    let badgeCount: (SidebarItem) -> Int

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(SidebarItem.available) { item in
                RailButton(
                    item: item,
                    isActive: selection == item,
                    count: badgeCount(item)
                ) {
                    selection = item
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, Theme.Spacing.md)
        .frame(width: Theme.Metrics.railWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.Palette.rail)
    }
}

private struct RailButton: View {
    let item: SidebarItem
    let isActive: Bool
    let count: Int
    let action: () -> Void

    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var iconColor: Color {
        if isActive { return Theme.Palette.primary }
        if item == .claude { return Theme.Palette.claude }
        return Theme.Palette.textSecondary
    }

    private var tileFill: Color {
        if isActive { return Theme.Palette.pane }
        if hovering { return Theme.Palette.hover }
        return .clear
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: item.systemImage)
                .font(.system(size: Theme.Metrics.iconToolbar, weight: .regular))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .fill(tileFill)
                )
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text(count > 99 ? "99+" : "\(count)")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Palette.textOnAccent)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, Theme.Spacing.xxs)
                            .background(Capsule().fill(Theme.Palette.primaryFill))
                            .offset(x: Theme.Spacing.xs, y: -Theme.Spacing.xxs)
                            .accessibilityLabel("\(count) unread")
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(.plain)
        .onHover { isOver in
            if reduceMotion {
                hovering = isOver
            } else {
                withAnimation(Theme.Motion.hover) { hovering = isOver }
            }
        }
        .help(item.title)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

// MARK: - Floating pane card

extension View {
    /// Wraps module content as a floating white card on the window wash —
    /// radius-8 pane, 1px subtle border, no shadow (Fluent elevation rules).
    func paneCard() -> some View {
        self
            .background(Theme.Palette.pane)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .strokeBorder(Theme.Palette.separator, lineWidth: 1)
            )
    }
}
