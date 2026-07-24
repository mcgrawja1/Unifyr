//
//  Components.swift
//  Unifyr — Fluent component library (Outlook design language)
//
//  The shared building blocks every module consumes; no bespoke variants.
//  Everything here is purely visual chrome over existing behavior — a
//  component never owns data flow, only presentation.
//

import SwiftUI

// MARK: - Hover highlight

/// Rounded hover tile shared by toolbar buttons and list rows. iOS has no
/// pointer hover; the modifier is inert there unless a pointer is attached
/// (iPad trackpad still delivers onHover).
private struct HoverHighlight: ViewModifier {
    var radius: CGFloat = Theme.Radius.sm
    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(hovering ? Theme.Palette.hover : Color.clear)
            )
            .onHover { isOver in
                if reduceMotion {
                    hovering = isOver
                } else {
                    withAnimation(Theme.Motion.hover) { hovering = isOver }
                }
            }
    }
}

extension View {
    /// Fluent hover tile (row/toolbar-button hover state).
    func fluentHover(radius: CGFloat = Theme.Radius.sm) -> some View {
        modifier(HoverHighlight(radius: radius))
    }
}

// MARK: - Buttons

/// Filled brand button — "New Mail", "Save", "Connect".
struct FluentPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.bodyStrong)
            .foregroundStyle(Theme.Palette.textOnAccent)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(height: Theme.Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(configuration.isPressed
                          ? Theme.Palette.primaryFillHover
                          : Theme.Palette.primaryFill)
            )
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

/// Outlined neutral button — "Discard", "Cancel".
struct FluentSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.bodyStrong)
            .foregroundStyle(Theme.Palette.textPrimary)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(height: Theme.Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(configuration.isPressed ? Theme.Palette.hover : Theme.Palette.pane)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .strokeBorder(Theme.Palette.separatorStrong, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

/// Command-bar action — icon beside label, transparent, hover tile.
/// Disabled actions render in `textTertiary`, visible but inert.
struct FluentToolbarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.titleAndIcon)
            .font(Theme.Font.body)
            .foregroundStyle(isEnabled ? Theme.Palette.textPrimary : Theme.Palette.textTertiary)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(height: Theme.Metrics.buttonHeight)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .fluentHover()
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }
}

extension ButtonStyle where Self == FluentPrimaryButtonStyle {
    static var fluentPrimary: FluentPrimaryButtonStyle { .init() }
}
extension ButtonStyle where Self == FluentSecondaryButtonStyle {
    static var fluentSecondary: FluentSecondaryButtonStyle { .init() }
}
extension ButtonStyle where Self == FluentToolbarButtonStyle {
    static var fluentToolbar: FluentToolbarButtonStyle { .init() }
}

// MARK: - Command bar

/// The 44pt action strip that sits at the top of a module's content card.
/// Callers fill it with `.fluentToolbar` buttons; trailing utilities go in
/// `trailing`.
struct CommandBar<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    init(
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            leading()
            Spacer(minLength: Theme.Spacing.sm)
            trailing()
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .frame(height: Theme.Metrics.commandBarHeight)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.commandBar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Palette.separator).frame(height: 1)
        }
    }
}

// MARK: - Segmented control

/// Pill segmented control (Outlook's Focused/Other look): gray track,
/// selected segment as a white pill with a whisper of shadow.
struct FluentSegmentedControl<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(options, id: \.value) { option in
                let isSelected = selection == option.value
                Button {
                    if reduceMotion {
                        selection = option.value
                    } else {
                        withAnimation(Theme.Motion.hover) { selection = option.value }
                    }
                } label: {
                    Text(option.label)
                        .font(isSelected ? Theme.Font.bodyStrong : Theme.Font.body)
                        .foregroundStyle(isSelected ? Theme.Palette.primary : Theme.Palette.textSecondary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .frame(height: Theme.Metrics.controlHeight - Theme.Spacing.xs)
                        .background(
                            Capsule().fill(isSelected ? Theme.Palette.pane : Color.clear)
                                .shadow(
                                    color: isSelected ? Theme.Shadow.raised.color : .clear,
                                    radius: Theme.Shadow.raised.radius,
                                    y: Theme.Shadow.raised.y
                                )
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(Theme.Spacing.xxs)
        .background(Capsule().fill(Theme.Palette.hover))
    }
}

// MARK: - Search field (in-pane variant)

/// Pill search input for use inside panes (the on-brand title-bar variant
/// lives in AppShell).
struct FluentSearchField: View {
    @Binding var text: String
    var prompt: String = "Search"

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Theme.Metrics.iconInline - 3))
                .foregroundStyle(Theme.Palette.textSecondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(Theme.Font.body)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Theme.Metrics.iconInline - 3))
                        .foregroundStyle(Theme.Palette.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: Theme.Metrics.controlHeight)
        .background(Capsule().fill(Theme.Palette.hover))
    }
}

// MARK: - List row

/// Nav-pane / list-pane row: 28pt, 16pt leading icon, optional trailing
/// accessory (count, badge). Selection = `surface.selected` + brand text.
struct FluentListRow<Trailing: View>: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool = false
    var relaxed: Bool = false
    let action: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    init(
        _ title: String,
        systemImage: String? = nil,
        isSelected: Bool = false,
        relaxed: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.relaxed = relaxed
        self.action = action
        self.trailing = trailing
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: Theme.Metrics.iconInline))
                        .foregroundStyle(isSelected ? Theme.Palette.primary : Theme.Palette.textSecondary)
                        .frame(width: Theme.Metrics.iconInline + Theme.Spacing.xs)
                }
                Text(title)
                    .font(isSelected ? Theme.Font.bodyStrong : Theme.Font.body)
                    .foregroundStyle(isSelected ? Theme.Palette.primary : Theme.Palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.xs)
                trailing()
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: relaxed ? Theme.Metrics.listRowHeightRelaxed : Theme.Metrics.listRowHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(isSelected ? Theme.Palette.selected : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .buttonStyle(.plain)
        .fluentHover()
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Right-aligned count in brand blue (unread counts, item totals).
struct FluentRowCount: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Palette.primary)
                .monospacedDigit()
        }
    }
}

/// "+ Add Calendar"-style secondary action link.
struct FluentAddLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: Theme.Metrics.iconInline - 3, weight: .medium))
                Text(title)
                    .font(Theme.Font.body)
            }
            .foregroundStyle(Theme.Palette.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: Theme.Metrics.listRowHeight)
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .buttonStyle(.plain)
        .fluentHover()
    }
}

// MARK: - Collapsible section

/// Chevron + semibold label disclosure header (nav-pane sections).
struct FluentCollapsibleSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    @State private var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: String,
        initiallyExpanded: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Button {
                if reduceMotion {
                    isExpanded.toggle()
                } else {
                    withAnimation(Theme.Motion.surface) { isExpanded.toggle() }
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: Theme.Metrics.iconInline - 6, weight: .semibold))
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    Text(title)
                        .font(Theme.Font.bodyStrong)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .frame(height: Theme.Metrics.listRowHeight)
                .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            }
            .buttonStyle(.plain)
            .fluentHover()
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                content()
            }
        }
    }
}

// MARK: - Empty state

/// Centered empty state: soft grayscale glyph, semibold headline, secondary
/// subline. `compact` fits list panes; the default fits detail panes.
struct FluentEmptyState: View {
    let systemImage: String
    let headline: String
    var subline: String?
    var compact: Bool = false

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: compact ? 34 : 48, weight: .light))
                .foregroundStyle(Theme.Palette.textTertiary)
                .padding(compact ? Theme.Spacing.lg : Theme.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg * 2)
                        .fill(Theme.Palette.hover.opacity(0.6))
                )
            VStack(spacing: Theme.Spacing.xs) {
                Text(headline)
                    .font(Theme.Font.subtitle)
                    .foregroundStyle(Theme.Palette.textPrimary)
                if let subline {
                    Text(subline)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Form field

/// Small gray label above an underlined input; label + underline turn brand
/// blue on focus (Outlook record-editor fields).
struct FluentFormField: View {
    let label: String
    @Binding var text: String
    var prompt: String = ""
    var systemImage: String?
    var secure: Bool = false

    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.md) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: Theme.Metrics.iconInline))
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .frame(width: Theme.Metrics.iconInline + Theme.Spacing.xs)
                    .padding(.bottom, Theme.Spacing.sm)
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                if !label.isEmpty {
                    Text(label)
                        .font(Theme.Font.label)
                        .foregroundStyle(focused ? Theme.Palette.primary : Theme.Palette.textSecondary)
                }
                Group {
                    if secure {
                        SecureField(prompt.isEmpty ? label : prompt, text: $text)
                    } else {
                        TextField(prompt.isEmpty ? label : prompt, text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Palette.textPrimary)
                .focused($focused)
                .padding(.bottom, Theme.Spacing.xs)
                Rectangle()
                    .fill(focused ? Theme.Palette.primary : Theme.Palette.separator)
                    .frame(height: focused ? 2 : 1)
            }
        }
    }
}

// MARK: - Record editor chrome (styled sheet, "detached window" anatomy)

/// Sheet chrome that mimics Outlook's detached record editor: blue title
/// band (`Title • account`), gray command strip, white content card.
/// Behavior stays a plain SwiftUI sheet by design decision (2026-07-23).
struct RecordEditorChrome<Commands: View, Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var commands: () -> Commands
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(spacing: 0) {
                    Text(subtitle == nil ? title : "\(title) • \(subtitle!)")
                        .font(Theme.Font.bodyStrong)
                        .foregroundStyle(Theme.Palette.textOnAccent)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Metrics.commandBarHeight)
            .background(Theme.Palette.primaryFill)

            HStack(spacing: Theme.Spacing.xxs) {
                commands()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: Theme.Metrics.commandBarHeight)
            .frame(maxWidth: .infinity)
            .background(Theme.Palette.secondaryChrome)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Palette.pane)
        }
    }
}

// MARK: - Quick-create card (popover form chrome)

/// Outlook's quick-create popover anatomy: blue two-line header with an
/// optional expand affordance, white form body, footer with "More options"
/// + Discard/Save.
struct QuickCreateCard<Content: View>: View {
    let headerLine1: String
    var headerLine2: String?
    var onExpand: (() -> Void)?
    var onMoreOptions: (() -> Void)?
    let discardTitle: String
    let saveTitle: String
    var saveDisabled: Bool = false
    let onDiscard: () -> Void
    let onSave: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(headerLine1)
                        .font(Theme.Font.bodyStrong)
                    if let headerLine2 {
                        Text(headerLine2)
                            .font(Theme.Font.label)
                            .opacity(0.85)
                    }
                }
                Spacer()
                if let onExpand {
                    Button(action: onExpand) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: Theme.Metrics.iconInline - 2))
                    }
                    .buttonStyle(.plain)
                    .help("Open full editor")
                    .accessibilityLabel("Open full editor")
                }
            }
            .foregroundStyle(Theme.Palette.textOnAccent)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.primaryFill)

            content()
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.lg)

            HStack(spacing: Theme.Spacing.sm) {
                if let onMoreOptions {
                    Button("More options", action: onMoreOptions)
                        .buttonStyle(.plain)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Palette.primary)
                }
                Spacer()
                Button(discardTitle, action: onDiscard)
                    .buttonStyle(.fluentSecondary)
                Button(saveTitle, action: onSave)
                    .buttonStyle(.fluentPrimary)
                    .disabled(saveDisabled)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .background(Theme.Palette.pane)
    }
}
