---
name: quotations-swift
description: Develop the Quotations macOS SwiftUI app with SwiftData persistence. Use when editing Swift files in this repo, adding features to Authors/Sources/Quotations, working with NavigationSplitView, search, forms, or SwiftData models in Quotations-swift.
---

# Quotations Swift

macOS-only SwiftUI app for managing literary quotations. Swift 5, macOS 15.7+, SwiftData for persistence.

## Project layout

```
Quotations/
├── QuotationsApp.swift      # @main, ModelContainer setup
├── ContentView.swift        # NavigationSplitView shell, search, inspector
├── SearchState.swift        # Debounced search (@Observable)
├── Models/                  # SwiftData @Model classes
└── Views/                   # SwiftUI views (forms, lists, rows)
```

For file-by-file responsibilities, see [reference.md](reference.md).

## Data model

Three `@Model` classes with relationships:

- **Author** → has many **Source** (via `source.author`)
- **Source** → has many **Quotation** (via `quotation.source`)

All models include `createdAt`, `updatedAt`, and `deletedAt`. **Never hard-delete** — set `deletedAt = Date()` and call `modelContext.save()`.

Every `@Query` must filter soft-deleted records:

```swift
@Query(filter: #Predicate<Source> { $0.deletedAt == nil }, sort: \.name)
```

When updating records, set `updatedAt = Date()`.

## Architecture patterns

### Navigation

`ContentView` uses `NavigationSplitView`:
- **Sidebar**: source list with inline create form
- **Detail**: `SourceDetailView` or `UnifiedSearchResultsView` when searching
- **Inspector**: trailing panel for quotation page numbers

Selection uses `PersistentIdentifier?` (`selectedSourceId`, `selectedQuotationId`), not model instances.

### Search

`SearchState` is `@Observable`, owned as `@State` in `ContentView`. Search is debounced (200ms), case-insensitive, and matches quotation content, source title, and author name. Results flow through `MatchSets` (sets of author/source/quotation IDs).

When adding searchable fields, update `SearchState.runSearchIfNeeded` and use `HighlightMatch` in views.

### Forms

Forms follow a callback pattern — no dismiss environment:

```swift
var onSuccess: () -> Void
var onCancel: () -> Void
var onError: (String) -> Void  // when validation/save can fail
```

- `SourceFormView` — create/edit sources; author autocomplete via `textInputSuggestions`
- `QuotationFormView` — inline add; commits on blur or submit
- `AuthorFormView` — sheet for author management

Create vs edit: pass `existingSource` (or equivalent) and branch on `isEditing`.

### Reusable view composition

- `SourceSectionView<BelowContent>` — header (title, author, link) + divider + content slot
- `QuotationListView` — quotations for one source
- `HighlightMatch` — case-insensitive search term highlighting

Prefer extracting reusable blocks over duplicating header/list markup.

## UI conventions

### Typography and color

- Quotation body: `.system(size: 16, design: .serif)` with `lineSpacing: 6`
- App "ink" color adapts to color scheme (warm dark in light mode, cream in dark mode) — see `ContentView.inkColor`
- Edit focus border: `Color(red: 0.35, green: 0.55, blue: 0.92)`
- Section headers use platform background (`windowBackgroundColor` on macOS)

### Dividers and spacing

Use `.padding(.vertical, 6)` around quotation row content.

### Accessibility

Toolbar buttons use `.accessibilityLabel` and `.help`. Prefer `Label` or explicit labels over icon-only buttons without accessibility text.

## Platform conditionals

App targets macOS only (`SDKROOT = macosx`), but some views use `#if canImport(UIKit)` / `#elseif canImport(AppKit)` for shared color APIs. New platform-specific code should follow this pattern in `SourceSectionView` and `QuotationListView`.

## Adding features checklist

1. **New model field**: Update `@Model` class, any forms, list/row views, and search if searchable
2. **New view**: Place in `Views/`, add file header comment, include `#Preview` with in-memory container
3. **New query**: Always filter `deletedAt == nil`; use `#Predicate` with captured IDs for relationship filters (see `QuotationListView.init`)
4. **New Xcode file**: Add to `Quotations.xcodeproj/project.pbxproj` (or ask user to add via Xcode)
5. **State ownership**: App-level state in `ContentView`; feature state in dedicated `@Observable` types (like `SearchState`), not scattered `@State` in leaf views

## Code style

- File header: `//  FileName.swift` / `//  Quotations` / `//`
- Import order: `SwiftUI` then `SwiftData`; platform imports after `#if`
- `try? modelContext.save()` for non-critical saves; `do/catch` with `onError` in forms
- `@Environment(\.modelContext)` for persistence; `@Query` for lists
- `onChange(of:)` uses two-parameter form: `{ _, newValue in }`

## Previews

```swift
#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}
```

Use in-memory containers. Seed sample data in preview when the view needs content.

## What to avoid

- Hard deletes or queries without `deletedAt == nil` filter
- iOS-only APIs without macOS fallback
- Storing selection as model references (use `PersistentIdentifier`)
- Large logic in `ContentView` — extract to views or observable state types
- Breaking the ink/serif visual language without intentional design change
