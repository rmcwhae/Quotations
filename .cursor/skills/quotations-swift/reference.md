# Quotations — Reference

## Models

| Model | Key fields | Relationships |
|-------|-----------|---------------|
| `Author` | `name` | Referenced by `Source.author` |
| `Source` | `title`, `url?`, `publicationYear?`, `format?`, `dateReadMonth?`, `dateReadYear?` | `author?`; parent of quotations |
| `Quotation` | `content`, `location?` | `source?` |

All models: `createdAt`, `updatedAt`, `deletedAt` (soft delete).

## Views

| View | Role |
|------|------|
| `ContentView` | App shell: sidebar, detail routing, search, inspector, sheets/alerts |
| `SourceListRowView` | Sidebar row for one source |
| `SourceDetailView` | Detail pane for selected source |
| `SourceSectionView` | Reusable source header + content slot |
| `QuotationListView` | Quotations for a source; `@Query` filtered by source ID |
| `QuotationRowView` | Single quotation display/edit |
| `QuotationInspectorView` | Trailing inspector: format, location, date read, delete |
| `QuotationFormView` | Inline quotation creation |
| `SourceFormView` | Create/edit source with author autocomplete |
| `AuthorFormView` | Author management sheet |
| `UnifiedSearchResultsView` | Multi-source search results layout |
| `SearchBarView` | (if used standalone) search UI |
| `HighlightMatch` | Search term highlighting via `AttributedString` |

## SearchState API

```swift
@Observable final class SearchState {
    var query: String
    var searchResults: [SearchResultItem]
    var isSearching: Bool
    var matchSets: MatchSets?

    func runSearchIfNeeded(modelContext: ModelContext)
    func matchSetsForQuery() -> MatchSets?
}
```

`MatchSets` contains `authorIds`, `sourceIds`, `quotationIds` as `Set<PersistentIdentifier>`.

## ContentView state map

| State | Purpose |
|-------|---------|
| `searchState` | Query and search results |
| `selectedSourceId` | Sidebar selection |
| `selectedQuotationId` | Quotation selection (detail + inspector) |
| `showSourceForm` | Inline sidebar create form |
| `showQuotationForm` | Detail toolbar add quotation |
| `sourceToEdit` / `sourceToDelete` | Sheet edit / delete confirmation |
| `isInspectorShown` | Trailing inspector visibility |

Inspector fields: **Location** binds to `quotation.location` (helper: "Page number or percentage" on focus). **Format** and **Date read** are edited in `SourceFormView` and shown read-only under **Source Details** in the inspector.

## Migration

`QuotationLocationMigration` runs once at launch (see `QuotationsApp.swift`) to combine legacy `startPage`/`endPage` into `location` using an en-dash (e.g. `35–36`).

## ModelContainer

Registered in `QuotationsApp.swift`:

```swift
Schema([Author.self, Source.self, Quotation.self])
ModelConfiguration(isStoredInMemoryOnly: false)
```

Injected via `.modelContainer(sharedModelContainer)` on `WindowGroup`.
