//
//  MCPDatabaseToolTests.swift
//  UnifyrTests
//
//  The MCP database tools added 2026-07-24 (db_create / db_add_property /
//  db_pin_dashboard / notes_rename) — the capabilities Claude lacked when
//  asked to build a package tracker: create a new database with a schema,
//  rename it, and pin it to the Dashboard.
//

import Testing
import Foundation
import SwiftData
@testable import Unifyr

@MainActor
struct MCPDatabaseToolTests {

    /// Executor over fresh in-memory stores (no CloudKit, no disk). The
    /// CONTAINERS are returned too — the executor holds only their contexts,
    /// and a deallocated ModelContainer makes every fetch trap.
    private func makeExecutor() -> (MCPToolExecutor, ModelContainer, ModelContainer) {
        let configuration = ModelConfiguration(
            schema: UnifyrSchema.schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let notesContainer = try! ModelContainer(for: UnifyrSchema.schema, configurations: [configuration])
        let mailContainer = MailStore.makeContainer(inMemory: true)
        let executor = MCPToolExecutor(
            brokers: Brokers(),
            notesContainer: notesContainer,
            mailContainer: mailContainer,
            mailService: MailService(),
            onAudit: { _, _, _ in }
        )
        return (executor, notesContainer, mailContainer)
    }

    @Test func createRenamePinRoundTrip() async throws {
        let (executor, notesContainer, _) = makeExecutor()
        let context = notesContainer.mainContext

        // Create with a custom schema — no seed junk rows.
        let create = await executor.execute(name: "db_create", arguments: [
            "title": "Packages Arriving Today",
            "properties": [
                ["name": "Arrived", "kind": "checkbox"],
                ["name": "Carrier", "kind": "select", "options": ["UPS", "FedEx", "USPS"]],
            ],
        ])
        #expect(create.ok, "db_create failed: \(create.content)")

        let store = DatabaseStore(context: context)
        let database = try #require(store.databaseNotes().first { $0.title == "Packages Arriving Today" })
        let columns = store.fetchProperties(databaseNoteID: database.id)
            .map { "\($0.name):\($0.propertyKind.rawValue)" }
        #expect(columns == ["Name:text", "Arrived:checkbox", "Carrier:select"])
        #expect(store.fetchRows(databaseNoteID: database.id).isEmpty)

        // Rows flow through the existing tool; the checkbox works as a cell.
        let add = await executor.execute(name: "db_add_row", arguments: [
            "database": database.id.uuidString,
            "values": ["Name": "New monitor", "Arrived": false, "Carrier": "UPS"],
        ])
        #expect(add.ok, "db_add_row failed: \(add.content)")
        #expect(store.fetchRows(databaseNoteID: database.id).count == 1)

        // Rename (the gap that left it called "Untitled").
        let rename = await executor.execute(name: "notes_rename", arguments: [
            "id": database.id.uuidString,
            "title": "Package Tracker",
        ])
        #expect(rename.ok, "notes_rename failed: \(rename.content)")
        #expect(database.title == "Package Tracker")

        // Pin → visible to the Dashboard's PinStore; unpin restores state
        // (tests share the app's UserDefaults, so always clean up).
        let pin = await executor.execute(
            name: "db_pin_dashboard", arguments: ["database": "Package Tracker"]
        )
        #expect(pin.ok, "db_pin_dashboard failed: \(pin.content)")
        #expect(PinStore.isPinned(databaseView: database.id, viewID: nil))

        let unpin = await executor.execute(
            name: "db_pin_dashboard",
            arguments: ["database": "Package Tracker", "pinned": false]
        )
        #expect(unpin.ok)
        #expect(!PinStore.isPinned(databaseView: database.id, viewID: nil))
    }

    @Test func addPropertyAndRejectedKinds() async throws {
        let (executor, notesContainer, _) = makeExecutor()
        let context = notesContainer.mainContext
        _ = await executor.execute(name: "db_create", arguments: ["title": "T"])

        let ok = await executor.execute(name: "db_add_property", arguments: [
            "database": "T", "name": "Due", "kind": "date",
        ])
        #expect(ok.ok)
        let store = DatabaseStore(context: context)
        let database = try #require(store.databaseNotes().first { $0.title == "T" })
        #expect(store.fetchProperties(databaseNoteID: database.id).contains { $0.name == "Due" })

        // Context-dependent kinds are refused with a readable error.
        let rejected = await executor.execute(name: "db_add_property", arguments: [
            "database": "T", "name": "Owner", "kind": "relation",
        ])
        #expect(!rejected.ok)
    }
}
