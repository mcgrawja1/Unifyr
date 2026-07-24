# Unifyr

A personal "everything app" for macOS, iPadOS, and iOS: mail, messages, calendar,
reminders, notes, databases, files, photos, contacts, and an integrated Claude
assistant — one native SwiftUI app, one design language, one search.

Unifyr replaces a drawer full of first-party apps with a single window styled
after Microsoft Outlook for Mac's layout language (brand title bar, module icon
rail, nav pane, command bar, floating pane cards) — built entirely with
original assets: SF Symbols, system fonts, and a token-driven theme.

## Modules

| Module | What it is |
|---|---|
| **Dashboard** | Greeting, live clock, and pinned cards: today's events, due/overdue reminders, flagged mail, quick capture, Ask Claude, Home Assistant readings, pinned notes/databases |
| **Mail** | From-scratch IMAP/SMTP client (no MailKit): multi-account, unified mailboxes, smart mailboxes, rules, blocked senders, signatures, remote-image privacy blocking |
| **Messages** | macOS-only iMessage wrapper: reads chat.db directly (Full Disk Access), sends via Messages.app automation |
| **Calendar** | Day/week/month over EventKit: drag-to-move events, mini-month navigator, quick-create card |
| **Reminders** | Kanban board over EventKit reminder lists with a full detail editor |
| **Notes** | Notion-style workspace: nested page tree, block editor (TipTap/ProseMirror in a WKWebView), page links/mentions/embeds, covers, version history |
| **Databases** | Notion-style tables inside Notes: table/board/calendar views, saved views with filters & sorts, relations, row pages |
| **Drive** | Finder-lite file manager with security-scoped locations plus a from-scratch WebDAV "Connect to Server" client (iOS included) |
| **Photos / Contacts** | Photo grid and a full Apple-Contacts-card editor over the system frameworks |
| **Clock** | Stopwatch, timers, alarms wired into the app's notification hub (replaces Messages on iOS) |
| **Claude** | In-app chat with tool access, daily briefing, and an MCP server exposing the whole app to Claude Desktop |

## Architecture notes

- **SwiftUI + SwiftData + CloudKit**, Swift 6 with default MainActor isolation.
  One multiplatform target builds macOS and iOS/iPadOS.
- **Brokers** (`Unifyr/Unifyr/Brokers/`) wrap the system frameworks (EventKit,
  Contacts, Photos) behind actor-isolated snapshot APIs; per-module TCC access
  is requested lazily ("Connect" prompts, never a launch-time prompt wall).
- **Mail is local-first and CloudKit-free by design** — a server-authoritative
  cache in its own SwiftData container; only account *settings* sync (iCloud
  KVS + iCloud Keychain for the password).
- **Notes/Databases** share one CloudKit-synced container. A database is a
  `Note` with `kind == .database`; columns/rows/cells are UUID-linked records,
  so partial syncs degrade to missing rows, not broken graphs.
- **MCP**: the app runs a localhost HTTP tool server; `mcp-bridge/` is the
  stdio shim Claude Desktop launches. Tools cover notes, databases (create,
  schema, rows, dashboard pinning), calendar, reminders, contacts, photos,
  mail (draft-only — sending always goes through the in-app confirm), and
  messages. Every invocation is written to an in-app audit log.
- **Design system**: token-driven "Fluent" identity — see [DESIGN.md](DESIGN.md).
  `Theme/Theme.swift` is the single source for color/type/spacing/metrics,
  mirrored into the two WebKit surfaces (`Editor/editor.css`, mail paper CSS).

## Repository layout

```
Unifyr/            Xcode project (app target, unit + UI tests)
  Unifyr/          App source, one folder per module
editor-src/        Node/esbuild source for the TipTap block editor
                   (builds into Unifyr/Unifyr/Editor/editor.js)
mcp-bridge/        stdio ⇄ HTTP MCP shim for Claude Desktop
UNIFYR_SPEC.md     Architecture spec and locked decisions
DESIGN.md          Design-system reference (tokens, components, rules)
```

## Building

Requires Xcode with the macOS and iOS SDKs. Signing uses a personal team;
adjust `DEVELOPMENT_TEAM` to build under your own.

```sh
# macOS
xcodebuild -project Unifyr/Unifyr.xcodeproj -scheme Unifyr \
  -destination 'platform=macOS' -allowProvisioningUpdates build

# iOS Simulator
xcodebuild -project Unifyr/Unifyr.xcodeproj -scheme Unifyr \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Unit tests
xcodebuild test -project Unifyr/Unifyr.xcodeproj -scheme Unifyr \
  -destination 'platform=macOS' -only-testing:UnifyrTests
```

The editor bundle is checked in; rebuild it only when changing `editor-src/`:

```sh
cd editor-src && npm install && npm run build
```

### Connecting Claude Desktop

In-app: **Claude → Automation** — toggle the MCP server on and copy the
generated `claude_desktop_config.json` snippet (it points at `mcp-bridge/`).
Restart Claude Desktop and a `hyperview` tool server appears.

## History

Unifyr began life as "Hyperview" (the internal identifiers — bundle id
`com.mcgraw.Hyperview`, the MCP server name, deep-link scheme — deliberately
keep that name; renaming them would orphan CloudKit data, Keychain items, and
persisted links). The visual identity is the Outlook-style "Fluent" system,
which replaced the original "Serene" theme in July 2026.

This is a personal project, built for one household's daily use.
