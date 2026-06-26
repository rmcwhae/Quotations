# Quotations — Reference

## Models

| Model | Key fields | Relationships |
|-------|-----------|---------------|
| `Author` | `name` | Referenced by `Source.author` |
| `Source` | `title`, `url?`, `publicationYear?` | `author?`; parent of quotations |
| `Quotation` | `content`, `startPage?`, `endPage?` | `source?` |

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
| `inspectorStartPage` / `inspectorEndPage` | Inspector text fields |

## ModelContainer

Registered in `QuotationsApp.swift`:

```swift
Schema([Author.self, Source.self, Quotation.self])
ModelConfiguration(isStoredInMemoryOnly: false)
```

Injected via `.modelContainer(sharedModelContainer)` on `WindowGroup`.
