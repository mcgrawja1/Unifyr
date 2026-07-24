//
//  ContactEditorView.swift
//  Unifyr
//
//  Edit (or delete) a contact with the full Apple-Contacts card: names
//  (prefix/middle/suffix/nickname/phonetics), work, labeled emails/phones/
//  URLs, postal addresses, birthday + dates, related names, social profiles,
//  and instant messages. Saves via ContactsBroker.saveContact. Contact notes
//  are excluded — Apple gates that field behind a restricted entitlement.
//

import SwiftUI

struct ContactEditorView: View {
    /// nil = creating a brand-new contact.
    let contact: ContactSnapshot?
    var onSaved: () -> Void = {}

    @Environment(\.brokers) private var brokers
    @Environment(\.dismiss) private var dismiss

    @State private var edit: ContactEditData
    @State private var hasBirthday: Bool
    @State private var birthday: Date
    @State private var saving = false
    @State private var confirmingDelete = false
    @State private var errorText: String?

    init(contact: ContactSnapshot? = nil, onSaved: @escaping () -> Void = {}) {
        self.contact = contact
        self.onSaved = onSaved
        var data = ContactEditData()
        if let contact {
            data.namePrefix = contact.namePrefix
            data.givenName = contact.givenName
            data.middleName = contact.middleName
            data.familyName = contact.familyName
            data.nameSuffix = contact.nameSuffix
            data.nickname = contact.nickname
            data.phoneticGivenName = contact.phoneticGivenName
            data.phoneticFamilyName = contact.phoneticFamilyName
            data.organizationName = contact.organizationName ?? ""
            data.departmentName = contact.departmentName
            data.jobTitle = contact.jobTitle
            data.birthday = contact.birthday
            data.emails = contact.emails.isEmpty ? [LabeledValueSnapshot(label: "home", value: "")] : contact.emails
            data.phones = contact.phones.isEmpty ? [LabeledValueSnapshot(label: "mobile", value: "")] : contact.phones
            data.urls = contact.urls
            data.postalAddresses = contact.postalAddresses
            data.relations = contact.relations
            data.socialProfiles = contact.socialProfiles
            data.instantMessages = contact.instantMessages
            data.dates = contact.dates
        } else {
            // A fresh card starts with one empty phone/email row, like Apple's.
            data.emails = [LabeledValueSnapshot(label: "home", value: "")]
            data.phones = [LabeledValueSnapshot(label: "mobile", value: "")]
        }
        _edit = State(initialValue: data)
        _hasBirthday = State(initialValue: contact?.birthday != nil)
        _birthday = State(initialValue: contact?.birthday ?? Date())
    }

    /// Live name for the blue title band ("Record Name" pattern).
    private var editorTitle: String {
        let name = [edit.givenName, edit.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if !name.isEmpty { return name }
        return contact == nil ? "New Contact" : "Edit Contact"
    }

    var body: some View {
        RecordEditorChrome(title: editorTitle) {
            Button {
                Task { await save() }
            } label: {
                if saving {
                    Label {
                        Text("Save")
                    } icon: {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: Theme.Metrics.iconInline, height: Theme.Metrics.iconInline)
                    }
                } else {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
            }
            .buttonStyle(.fluentToolbar)
            .keyboardShortcut(.defaultAction)
            .disabled(saving)

            Button { dismiss() } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(.fluentToolbar)

            if contact != nil {
                Button { confirmingDelete = true } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.fluentToolbar)
            }
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg2) {
                    // Reference-3 header: large circular avatar beside names.
                    HStack(alignment: .top, spacing: Theme.Spacing.lg2) {
                        ContactAvatar(
                            data: contact?.thumbnail,
                            name: editorTitle,
                            size: 96
                        )
                        nameSection
                    }
                    sectionRule
                    workSection
                    sectionRule
                    labeledList(title: "Phone Numbers", items: $edit.phones, valuePrompt: "(555) 555-5555", defaultLabel: "mobile")
                    sectionRule
                    labeledList(title: "Email Addresses", items: $edit.emails, valuePrompt: "email@example.com", defaultLabel: "home")
                    sectionRule
                    labeledList(title: "URLs", items: $edit.urls, valuePrompt: "https://example.com", defaultLabel: "homepage")
                    sectionRule
                    addressSection
                    sectionRule
                    birthdaySection
                    datesSection
                    sectionRule
                    labeledList(title: "Related Names", items: $edit.relations, valuePrompt: "Name", defaultLabel: "spouse", labelPrompt: "relation")
                    sectionRule
                    labeledList(title: "Social Profiles", items: $edit.socialProfiles, valuePrompt: "username", defaultLabel: "X", labelPrompt: "service")
                    sectionRule
                    labeledList(title: "Instant Messages", items: $edit.instantMessages, valuePrompt: "handle", defaultLabel: "Signal", labelPrompt: "service")

                    if let errorText {
                        Text(errorText)
                            .font(Theme.Font.label)
                            .foregroundStyle(Theme.Palette.danger)
                    }
                }
                .padding(Theme.Spacing.lg2)
            }
        }
        .frame(width: 520, height: 680)
        .confirmationDialog("Delete \(contact?.displayName ?? "Contact")?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { Task { await delete() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the contact from your address book everywhere.")
        }
    }

    // MARK: Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("Name")
            HStack(spacing: Theme.Spacing.xs) {
                TextField("Prefix", text: $edit.namePrefix).textFieldStyle(.roundedBorder).frame(width: 70)
                TextField("First name", text: $edit.givenName).textFieldStyle(.roundedBorder)
                TextField("Middle", text: $edit.middleName).textFieldStyle(.roundedBorder).frame(width: 80)
                TextField("Last name", text: $edit.familyName).textFieldStyle(.roundedBorder)
                TextField("Suffix", text: $edit.nameSuffix).textFieldStyle(.roundedBorder).frame(width: 70)
            }
            HStack(spacing: Theme.Spacing.xs) {
                TextField("Nickname", text: $edit.nickname).textFieldStyle(.roundedBorder)
                TextField("Phonetic first", text: $edit.phoneticGivenName).textFieldStyle(.roundedBorder)
                TextField("Phonetic last", text: $edit.phoneticFamilyName).textFieldStyle(.roundedBorder)
            }
        }
    }

    private var workSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("Work Information")
            TextField("Company", text: $edit.organizationName).textFieldStyle(.roundedBorder)
            HStack(spacing: Theme.Spacing.xs) {
                TextField("Job title", text: $edit.jobTitle).textFieldStyle(.roundedBorder)
                TextField("Department", text: $edit.departmentName).textFieldStyle(.roundedBorder)
            }
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("Addresses")
            ForEach($edit.postalAddresses) { $address in
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        TextField("label", text: $address.label)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                        TextField("Street", text: $address.street).textFieldStyle(.roundedBorder)
                        removeButton { edit.postalAddresses.removeAll { $0.id == address.id } }
                    }
                    HStack(spacing: Theme.Spacing.xs) {
                        TextField("City", text: $address.city).textFieldStyle(.roundedBorder)
                        TextField("State", text: $address.state).textFieldStyle(.roundedBorder).frame(width: 70)
                        TextField("ZIP", text: $address.postalCode).textFieldStyle(.roundedBorder).frame(width: 80)
                        TextField("Country", text: $address.country).textFieldStyle(.roundedBorder).frame(width: 110)
                    }
                }
                .padding(.bottom, 2)
            }
            addButton("Add Address") {
                edit.postalAddresses.append(PostalAddressSnapshot())
            }
        }
    }

    private var birthdaySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("Birthday")
            HStack(spacing: Theme.Spacing.sm) {
                Toggle("Has birthday", isOn: $hasBirthday).platformCheckbox()
                if hasBirthday {
                    DatePicker("", selection: $birthday, displayedComponents: .date).labelsHidden()
                }
            }
        }
    }

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("Dates")
            ForEach($edit.dates) { $entry in
                HStack(spacing: Theme.Spacing.xs) {
                    TextField("label", text: $entry.label)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                    DatePicker("", selection: $entry.date, displayedComponents: .date).labelsHidden()
                    removeButton { edit.dates.removeAll { $0.id == entry.id } }
                    Spacer()
                }
            }
            addButton("Add Date") {
                edit.dates.append(ContactDateSnapshot())
            }
        }
    }

    private func labeledList(
        title: String,
        items: Binding<[LabeledValueSnapshot]>,
        valuePrompt: String,
        defaultLabel: String,
        labelPrompt: String = "label"
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel(title)
            ForEach(items) { $item in
                HStack(spacing: Theme.Spacing.xs) {
                    TextField(labelPrompt, text: $item.label)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                    TextField(valuePrompt, text: $item.value).textFieldStyle(.roundedBorder)
                    removeButton { items.wrappedValue.removeAll { $0.id == item.id } }
                }
            }
            addButton("Add") {
                items.wrappedValue.append(LabeledValueSnapshot(label: defaultLabel, value: ""))
            }
        }
    }

    // MARK: Small pieces

    /// 1px rule between record-editor sections (reference-3 anatomy).
    private var sectionRule: some View {
        Rectangle().fill(Theme.Palette.separator).frame(height: 1)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.subtitle)
            .foregroundStyle(Theme.Palette.textPrimary)
    }


    private func removeButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus.circle").foregroundStyle(Theme.Palette.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private func addButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        FluentAddLink(title: title, action: action)
    }

    // MARK: Actions

    private func save() async {
        saving = true
        var data = edit
        data.birthday = hasBirthday ? birthday : nil
        do {
            // nil id = create (see ContactsBroker.saveContact).
            _ = try await brokers.contacts.saveContact(id: contact?.id, edit: data)
            saving = false
            onSaved()
            dismiss()
        } catch {
            saving = false
            errorText = "Couldn't save — check Contacts access."
        }
    }

    private func delete() async {
        guard let contact else { return }   // nothing persisted yet
        do {
            try await brokers.contacts.deleteContact(id: contact.id)
            onSaved()
            dismiss()
        } catch {
            errorText = "Couldn't delete the contact."
        }
    }
}
