# Quotations — Reference

## Models

| Model | Key fields | Relationships |
|-------|-----------|---------------|
| `Author` | `name` | Referenced by `Source.author` |
| `Source` | `title`, `url?`, `publicationYear?`, `format?`, `dateReadMonth?`, `dateReadYear?` | `author?`; parent of quotations |
| `Quotation` | `content`, `location?` | `source?` |

All models: `createdAt`, `updatedAt`, `deletedAt` (soft delete).

## Utilities

| Utility | Role |
|---------|------|
| `SoftDelete` | Centralized soft-delete for authors, sources, quotations (cascade + `saveAndNotify`) |
| `ModelContext.saveAndNotify()` | Save and post `.quotationsDataDidChange` for search refresh |
| `SearchMatcher` | Pure match logic: content, title, author, location |
| `QuotationLocationMigration` | One-time legacy `startPage`/`endPage` → `location` migration |
| `LayoutMetrics` | Shared column width and list padding constants |
| `View.deselectQuotationOnBackgroundTap` | Tap empty detail space to clear quotation selection |

## Views

| View | Role |
|------|------|
| `ContentView` | App shell: sidebar, detail routing, search, inspector, sheets/alerts |
| `SourceListRowView` | Sidebar row for one source |
| `SourceDetailView` | Detail pane for selected source (scrollable parchment) |
| `SourceSectionView` | Reusable source header + content slot |
| `QuotationListView` | Quotations for a source via `@Query`; uses `QuotationRowsContent` |
| `QuotationRowsContent` | Lazy quotation list for a fixed array (search results) |
| `QuotationRowView` | Single quotation display/edit (inline, save on blur) |
| `QuotationInspectorView` | Trailing inspector: location, source details, delete |
| `SourceFormView` | Create/edit source with author autocomplete |
| `AuthorFormView` / `AuthorListView` | Author management |
| `UnifiedSearchResultsView` | Multi-source search results (no per-section `@Query`) |
| `HighlightMatch` / `FormattedQuotationText` | Search highlighting and cached markdown display |

New quotations are added inline via the detail toolbar (`addQuotation()` in `ContentView`), not a separate form.

## SearchState API

```swift
@Observable final class SearchState {
    var query: String
    var searchResults: [SearchResultItem]   // quotationId + sourceId pairs
    var isSearching: Bool
    var matchSets: MatchSets?
    var quotationsBySourceId: [PersistentIdentifier: [PersistentIdentifier]]

    func runSearchIfNeeded(modelContext: ModelContext)
    func matchSetsForQuery() -> MatchSets?
}
```

`MatchSets` contains `authorIds`, `sourceIds`, `quotationIds` as `Set<PersistentIdentifier>`.

Search clears stale `matchSets` when a new query starts; empty query cancels any in-flight task.

## ContentView state map

| State | Purpose |
|-------|---------|
| `searchState` | Query and search results |
| `selectedSourceId` | Sidebar selection (manual tap + tan highlight) |
| `selectedQuotationId` | Quotation selection (detail + inspector) |
| `newQuotationId` | Fresh inline draft opened for editing |
| `showSourceForm` | Inline sidebar create form |
| `sourceToEdit` / `sourceToDelete` | Sheet edit / delete confirmation |
| `isInspectorShown` | Trailing inspector visibility |

Detail routing: when search is active, detail shows `UnifiedSearchResultsView` only if `matchSets` has results; otherwise empty state. Non-search mode shows `SourceDetailView` or “Select a source”.

Inspector fields: **Location** binds to `quotation.location` (debounced save; flushes on quotation change). **Format** and **Date read** are edited in `SourceFormView` and shown read-only under **Source Details**.

Escape: `ContentView` deselects the quotation when one is selected; `QuotationRowView` ends edit mode only.

## Migration

`QuotationLocationMigration` runs at launch on whichever `ModelContainer` loads (persistent or in-memory fallback). Migration flag is keyed by store URL. Combines legacy `startPage`/`endPage` into `location` using an en-dash (e.g. `35–36`).

## ModelContainer

Registered in `QuotationsApp.swift`:

```swift
Schema([Author.self, Source.self, Quotation.self])
ModelConfiguration(isStoredInMemoryOnly: false)
```

Injected via `.modelContainer(sharedModelContainer)` on `WindowGroup`. Falls back to in-memory container with a user-facing warning if the persistent store cannot be opened.
