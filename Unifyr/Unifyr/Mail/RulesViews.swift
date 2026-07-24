//
//  RulesViews.swift
//  Unifyr
//
//  Editors for Smart Mailboxes (saved searches) and Rules (conditions →
//  actions). Both build on the shared ConditionFormView from MailFilters.
//

import SwiftUI
import SwiftData

// MARK: - Smart Mailbox editor

struct SmartMailboxEditorTarget: Identifiable {
    let id = UUID()
    var box: SmartMailbox?
}

struct SmartMailboxEditorView: View {
    let target: SmartMailboxEditorTarget
    let accounts: [MailAccount]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var color: Color = Theme.Palette.primary
    @State private var condition = MailCondition()

    private var isNew: Bool { target.box == nil }

    var body: some View {
        RecordEditorChrome(title: isNew ? "New Smart Mailbox" : "Edit Smart Mailbox") {
            Button { save() } label: {
                Label(isNew ? "Create" : "Save", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.fluentToolbar)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            Button { dismiss() } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(.fluentToolbar)
        } content: {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HStack(spacing: Theme.Spacing.md) {
                    FluentFormField(label: "Name", text: $name)
                    ColorPicker("", selection: $color, supportsOpacity: false)
                        .labelsHidden()
                }

                ConditionFormView(condition: $condition, accounts: accounts)

                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(width: 420)
        .onAppear {
            if let box = target.box {
                name = box.name
                color = Color(hexString: box.colorHex) ?? Theme.Palette.primary
                condition = box.condition
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let hex = color.hexRGB ?? ""
        if let box = target.box {
            box.name = trimmed
            box.colorHex = hex
            box.condition = condition
        } else {
            context.insert(SmartMailbox(name: trimmed, colorHex: hex, condition: condition))
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Rules manager

struct RulesManagerView: View {
    let accounts: [MailAccount]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \MailRule.sortIndex) private var rules: [MailRule]

    @State private var editing: RuleEditorTarget?

    var body: some View {
        RecordEditorChrome(title: "Rules") {
            Button {
                editing = RuleEditorTarget(rule: nil)
            } label: {
                Label("Add Rule", systemImage: "plus")
            }
            .buttonStyle(.fluentToolbar)
            Button { dismiss() } label: {
                Label("Done", systemImage: "checkmark")
            }
            .buttonStyle(.fluentToolbar)
        } content: {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Rules run on newly arrived Inbox messages when a mailbox syncs, in order.")
                    .font(Theme.Font.label)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                if rules.isEmpty {
                    FluentEmptyState(
                        systemImage: "arrow.branch",
                        headline: "No rules yet",
                        subline: "Rules file, tag, or flag new mail for you.",
                        compact: true
                    )
                } else {
                    List {
                        ForEach(rules) { rule in
                            ruleRow(rule)
                        }
                    }
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                }
            }
        }
        .frame(width: 480, height: 380)
        .sheet(item: $editing) { target in
            RuleEditorView(target: target, accounts: accounts)
        }
    }

    private func ruleRow(_ rule: MailRule) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { rule.isEnabled = $0; try? context.save() }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)

            Text(rule.name)
                .font(Theme.Font.body)
                .foregroundStyle(rule.isEnabled ? Theme.Palette.textPrimary : Theme.Palette.textSecondary)
            Spacer()
            Button("Edit") { editing = RuleEditorTarget(rule: rule) }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.Palette.primary)
            Button {
                context.delete(rule)
                try? context.save()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.xxs)
    }
}

// MARK: - Rule editor

struct RuleEditorTarget: Identifiable {
    let id = UUID()
    var rule: MailRule?
}

struct RuleEditorView: View {
    let target: RuleEditorTarget
    let accounts: [MailAccount]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.tagsStore) private var tagsStore
    @Query(sort: \Mailbox.sortIndex) private var mailboxes: [Mailbox]

    @State private var name = ""
    @State private var condition = MailCondition()
    @State private var action = RuleAction()

    private var isNew: Bool { target.rule == nil }

    /// Move-to targets require the condition to pin one account.
    private var moveTargets: [Mailbox] {
        guard let accountID = condition.accountID else { return [] }
        return mailboxes.filter { $0.accountID == accountID && $0.path.uppercased() != "INBOX" }
    }

    var body: some View {
        RecordEditorChrome(title: isNew ? "New Rule" : "Edit Rule") {
            Button { save() } label: {
                Label(isNew ? "Create" : "Save", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.fluentToolbar)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || action.isEmpty)
            Button { dismiss() } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(.fluentToolbar)
        } content: {
            ruleForm
        }
        .frame(width: 440, height: 520)
        .onAppear {
            if let rule = target.rule {
                name = rule.name
                condition = rule.condition
                action = rule.action
            }
        }
    }

    private var ruleForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                FluentFormField(label: "Rule name", text: $name)

                sectionLabel("If (all that are set)")
                ConditionFormView(condition: $condition, accounts: accounts)

                sectionLabel("Then")
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Toggle("Mark as read", isOn: $action.markRead)
                    Toggle("Flag", isOn: $action.flag)
                    Picker("Add tag", selection: $action.addTagID) {
                        Text("None").tag(UUID?.none)
                        ForEach(tagsStore?.tags ?? []) { tag in
                            Text(tag.name).tag(Optional(tag.id))
                        }
                    }
                    Toggle("Move to Trash", isOn: $action.moveToTrash)
                    if moveTargets.isEmpty {
                        Picker("Move to mailbox", selection: $action.moveToMailboxPath) {
                            Text("Pick an account above to enable").tag("")
                        }
                        .disabled(true)
                    } else {
                        Picker("Move to mailbox", selection: $action.moveToMailboxPath) {
                            Text("Don't move").tag("")
                            ForEach(moveTargets) { box in
                                Text(box.displayName).tag(box.path)
                            }
                        }
                    }
                }

            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.subtitle)
            .foregroundStyle(Theme.Palette.textPrimary)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let rule = target.rule {
            rule.name = trimmed
            rule.condition = condition
            rule.action = action
        } else {
            let rule = MailRule(name: trimmed, condition: condition, action: action)
            rule.sortIndex = ((try? context.fetch(FetchDescriptor<MailRule>()))?.map(\.sortIndex).max() ?? -1) + 1
            context.insert(rule)
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Blocked senders

/// Manage the blocked-senders list: newly arrived mail from these addresses
/// goes straight to Trash. Add manually here or via a message's context menu.
struct BlockedSendersView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BlockedSender.address) private var blocked: [BlockedSender]

    @State private var newAddress = ""

    var body: some View {
        RecordEditorChrome(title: "Blocked Senders") {
            Button { dismiss() } label: {
                Label("Done", systemImage: "checkmark")
            }
            .buttonStyle(.fluentToolbar)
            .keyboardShortcut(.defaultAction)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                if blocked.isEmpty {
                    FluentEmptyState(
                        systemImage: "nosign",
                        headline: "No blocked senders",
                        subline: "Right-click a message and choose “Block Sender”.",
                        compact: true
                    )
                } else {
                    List {
                        ForEach(blocked) { sender in
                            HStack {
                                Image(systemName: "nosign")
                                    .foregroundStyle(Theme.Palette.danger)
                                Text(sender.address)
                                    .font(Theme.Font.body)
                                Spacer()
                                Button {
                                    context.delete(sender)
                                    try? context.save()
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(Theme.Palette.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .help("Unblock")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Rectangle().fill(Theme.Palette.separator).frame(height: 1)

                HStack(spacing: Theme.Spacing.sm) {
                    FluentFormField(label: "", text: $newAddress, prompt: "email@example.com")
                        .onSubmit(addManually)
                    Button("Block", action: addManually)
                        .buttonStyle(.fluentSecondary)
                        .disabled(!newAddress.contains("@"))
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .frame(width: 420, height: 380)
    }

    private func addManually() {
        let address = newAddress.trimmingCharacters(in: .whitespaces).lowercased()
        guard address.contains("@"), !blocked.contains(where: { $0.address == address }) else { return }
        context.insert(BlockedSender(address: address))
        try? context.save()
        newAddress = ""
    }
}
