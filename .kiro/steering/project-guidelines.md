---
inclusion: auto
---

# Project Guidelines — Instagram Clone

You are working on an iOS Instagram clone built with Clean Architecture + MVVM. Follow these rules strictly.

## References

Before making changes, consult these documents:

- #[[file:Documentations/DEVELOPMENT_RULES.md]] — Mandatory coding rules
- #[[file:Documentations/PROJECT_ARCHITECTURE.md]] — System architecture
- #[[file:Documentations/DEVELOPMENT_NOTES.md]] — Tips, pitfalls, how-to guides
- #[[file:Documentations/PROJECT_STATUS.md]] — Current progress and what's done

## Critical Rules

### Layer Dependencies (NEVER violate)

- Domain imports NOTHING (pure Swift only)
- Presentations depends on Domain (via UseCases), never on Data directly
- Data implements Domain protocols
- Core is shared — any layer can import Core

### When Adding Code

1. Entity → `Domain/Entities/`
2. Repository protocol method → `Domain/Repositories/`
3. UseCase → `Domain/UseCases/{Feature}/`
4. Mock data → `Data/DataSources/Mock/`
5. Repository impl → `Data/Repositories/`
6. DI registration → `Core/DI/{Module}Assembly.swift`
7. ViewModel → `Presentations/{Feature}/`
8. View → `Presentations/{Feature}/`
9. Route → Add to `AppRoute` enum + destination in `MainTabView`

### Code Patterns

- ViewModels: `@MainActor @Observable final class`
- Entities: `struct` conforming to `Identifiable, Hashable, Sendable`
- Repositories: `final class: {Protocol}, @unchecked Sendable`
- UseCases: `final class: {Protocol}, Sendable` with `func execute(_ input:) async throws -> Output`
- Navigation: Always via `AppRouter.shared.push(...)`, never inline `NavigationLink(destination:)`
- Errors: `enum: LocalizedError` with `errorDescription`

### Performance (MUST follow)

- NEVER create a new `CIContext` — use `FilterEngine.shared.ciContext`
- NEVER hard-code numeric values (spacing, sizes, radius, font) — use `DS.*` constants
- Use `LazyVStack` / `LazyVGrid` for scrollable lists
- Use `LazyImage` (NukeUI) for remote images
- Heavy work (filters, I/O) must be `async` on background
- Thumbnail previews render at 150x150, never full resolution

### Design Constants (MUST follow)

- ALL spacing/padding: `DS.Spacing.*` or `DS.Padding.*`
- ALL sizes (avatar, icon, button): `DS.Size.*`
- ALL corner radius: `DS.Radius.*`
- ALL fonts: `DS.Font.*`
- ALL durations/timings: `DS.Duration.*`
- ALL layout limits: `DS.Layout.*`
- Colors: `ColorTokens.*`
- Example: `.padding(.horizontal, DS.Padding.horizontal)` not `.padding(.horizontal, 16)`

### Concurrency

- All entities are `Sendable`
- ViewModels are `@MainActor`
- Use `actor` for shared mutable state (e.g., caches)
- Repositories use `@unchecked Sendable` (stateless data source delegation)

### DI

- Services → `ServiceAssembly`
- Repositories → `RepositoryAssembly`
- UseCases → `UseCaseAssembly`
- ViewModels → `ViewModelAssembly`
- Resolve with `resolver.resolve(Type.self)!` in assemblies (fail-fast)

### Naming

- Files: `{Action}{Subject}UseCase.swift`, `{Feature}ViewModel.swift`, `{Feature}View.swift`
- Booleans: prefix `is/has/should`
- Data retrieval: prefix `fetch/load`
- Event handlers: prefix `handle`
- Toggle actions: prefix `toggle`

## When in doubt

- Check existing code in the same folder for patterns
- Follow the "Khi thêm Feature mới" checklist in DEVELOPMENT_NOTES.md
- Keep the Domain layer framework-free
- Prefer protocols over concrete types for dependencies
