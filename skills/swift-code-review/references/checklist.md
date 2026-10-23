# Review checklist with Swift examples

Questions to ask per principle, with what a violation and a fix look like. Read only the sections that apply to the change, and adapt the examples to the project's architecture and DI style.

## Contents

- [SOLID](#solid)
- [DRY, KISS, YAGNI](#dry-kiss-yagni)
- [Clean Architecture](#clean-architecture)
- [TDD and testability](#tdd-and-testability)
- [Swift concurrency](#swift-concurrency)
- [Swift language and API design](#swift-language-and-api-design)
- [Memory and performance](#memory-and-performance)
- [SwiftUI and UIKit](#swiftui-and-uikit)
- [Error handling](#error-handling)

## SOLID

### S — Single Responsibility

*Does this type have one reason to change?* Smells: a view model that formats dates, validates input, calls two services and builds share text; a file over ~300 lines; a type named `…Manager`, `…Helper` or `…Utils`; a `UIViewController` that also does networking.

```swift
// ✗ Formatting, validation and persistence in one view model
func save() async {
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty, Double(amount) ?? 0 > 0 else { ... }
    let formatter = DateFormatter(); formatter.dateFormat = "dd/MM/yyyy"
    ...
}

// ✓ Validation is a pure, testable value; formatting uses FormatStyle
struct ExpenseDraft {
    var name: String
    var amount: Double?
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0 }
}
Text(expense.date, format: .dateTime.day().month().year())
```

### O — Open/Closed

*Can a new case be added without editing existing code in many places?* Smell: the same `switch` over an enum repeated in several files (icon, title, color). Fix: put the behavior on the enum (computed properties) or behind a protocol, so a new case is one edit the compiler guides.

```swift
// ✓ One place to extend; the exhaustive switch flags new cases
extension PaymentMethod {
    var title: LocalizedStringResource { switch self { case .card: "Card"; case .cash: "Cash" } }
    var systemImage: String { switch self { case .card: "creditcard"; case .cash: "banknote" } }
}
```

No `default:` in switches over your own enums: it silences the compiler when a case is added.

### L — Liskov Substitution

*Can every conformance stand in for the protocol without surprises?* Smells: a fake or mock that `fatalError`s on methods tests don't call; a conformance that ignores a parameter the protocol promises to honor; subclass overrides that no-op or throw "not supported".

### I — Interface Segregation

*Does each client use most of the protocol it depends on?* Smell: a read-only screen takes a protocol with 15 CRUD methods, so its fake implements 15. Fix: split (`ExpenseReading` / `ExpenseWriting`) only when there are real distinct clients; otherwise leave it (YAGNI).

### D — Dependency Inversion

*Do high-level modules depend on abstractions that are injected?* Smells: `let api = APIClient()` inside a view model, `URLSession.shared` / `UserDefaults.standard` / `FileManager.default` / `Date()` called directly in logic, singletons reached from everywhere.

```swift
// ✗ Concrete and untestable
final class ProfileViewModel { private let service = ProfileService() }

// ✓ Abstraction injected (initializer, or the project's DI container)
final class ProfileViewModel {
    private let service: ProfileServiceProtocol
    init(service: ProfileServiceProtocol) { self.service = service }
}
```

## DRY, KISS, YAGNI

- **DRY is about knowledge, not text.** Flag the same rule written twice (a limit, a validation, a date calculation, a URL, a localized key built by concatenation). Don't flag two views that look alike but will evolve separately: the wrong abstraction costs more than duplication. Rule of three: extract on the third copy, or the second if it's a business rule.
- Before suggesting a new helper, search the project's shared/UI/utility modules for an existing one. Reinventing an existing component is a 🟡.
- **KISS:** prefer the standard library and Foundation (`FormatStyle`, `Measurement`, `Duration`, `sorted(using:)`, `URL.appending(path:)`) over hand-rolled code; a computed property over a stored copy kept in sync manually; one state enum over several booleans (`isLoading` + `error` + `items` → `enum State { case loading, loaded([Item]), failed(Error) }`).
- **YAGNI:** flag protocols with one conformer and no test fake, generic parameters with one concrete use, configuration flags nothing sets, "for later" code paths. Delete rather than abstract.

## Clean Architecture

Dependencies point inward, toward the domain:

```
UI (SwiftUI / UIKit) ─► Presentation (ViewModel / Presenter / Reducer) ─► Domain (models, use cases, repository protocols)
                                                                              ▲
                                       Data (repositories, API clients, persistence) ─┘
```

Check:

- Domain models are plain Swift values: no `import SwiftUI`, `UIKit`, `CoreData`, `SwiftData`. Display concerns (colors, icons, formatting) live in the UI layer as extensions.
- `NSManagedObject`, `@Model` types, DTOs (`Codable` API responses) and `URLResponse` don't leave the data layer; mapping to domain models happens there.
- Feature modules don't import each other; cross-feature navigation goes through closures, coordinators or a router owned by the app layer.
- Business rules live in the domain (use case, repository, model), not in views or view controllers, so they are shared and unit-testable.
- Navigation decisions aren't scattered: views raise intents; the coordinator/router/navigation stack owner decides.
- Public surface is minimal: `public` only for the module's API, everything else `internal`/`private`.

## TDD and testability

- **New behavior has a test.** Logic in unit tests; user flows in UI tests (XCUITest, Maestro, snapshot tests) where the project has them. No tests for a new service method or view-model rule is 🔴.
- **A bug fix has a regression test** that fails without the fix. If the diff can't show it was written first, suggest the test.
- Tests check behavior through the public API, one behavior per test, named for the behavior.
- Swift Testing (new code, if the project uses it): `#require` to unwrap and stop, `#expect` to assert, `@Test(arguments:)` instead of copy-pasted tests, `@Suite` for grouping. XCTest: `XCTUnwrap` over force unwraps, `await fulfillment(of:)` over `wait(for:)` in async tests.
- Deterministic: inject clocks (`Clock`, `Date` providers), `Calendar`, `Locale`, `UUID` generators; in-memory persistence instead of the real store; no `sleep` / `Task.sleep` to wait for async work — `await` it.
- Fakes over mocks where possible: a small in-memory implementation of the protocol is easier to read than call-count assertions.
- Hard-to-test code is a design signal: if a test needs the real database or network to check a formatting rule, the rule is in the wrong layer.
- Load `swift-testing-pro` when reviewing a substantial test diff.

## Swift concurrency

- Know the module's default isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION`, `defaultIsolation` in `Package.swift`). Where it isn't MainActor, UI-facing types (view models, coordinators) need `@MainActor`; services crossing isolation must be `Sendable` (immutable `final class`, `struct`, or `actor`).
- `@unchecked Sendable`, `nonisolated(unsafe)` and `MainActor.assumeIsolated` need a comment explaining why they're safe; otherwise 🔴.
- `Task {}` in a view model or controller: is it stored and cancelled, or tied to the view with `.task {}` / `.task(id:)`? Prefer the SwiftUI modifiers so cancellation is automatic.
- No new `DispatchQueue.main.async`, semaphores or completion handlers when async/await is available; wrap legacy callbacks with `withCheckedThrowingContinuation` (resumed exactly once).
- Actor reentrancy: state read before an `await` may have changed after it.
- Core Data / SwiftData objects aren't `Sendable`: work inside `perform` / a `ModelActor`, and pass only IDs or value types across isolation.
- Long loops check `Task.isCancelled` / `try Task.checkCancellation()`.

## Swift language and API design

- `struct` / `enum` by default; `final class` when identity or reference semantics are needed; `actor` for shared mutable state.
- `let` over `var`; `private` / `private(set)` by default.
- No `!`, `try!`, `as!` outside tests and truly impossible cases (with a `preconditionFailure` message); `guard let` early exits over nested `if let`.
- `some Protocol` over `any Protocol` unless heterogeneity is needed.
- Naming follows the Swift API Design Guidelines: clear at the call site, no type names in variable names (`usersArray`), Booleans read as assertions (`isEnabled`, `canSave`), factory methods start with `make`, mutating/non-mutating pairs (`sort`/`sorted`).
- No magic numbers or strings: named constants placed with their owner; user-facing text in the String Catalog / `Localizable.strings`.
- Dead code, commented-out code and `print` are removed; logging uses `Logger` (os) with privacy annotations.

## Memory and performance

- Stored closures in classes that capture `self` use `[weak self]`, or the closure's lifetime is clearly bounded; delegates are `weak`; Combine `sink`s are stored in a cancellable set the owner releases.
- No heavy work on the main actor: image decoding/downsampling, large fetches, JSON parsing, file I/O.
- Persistence fetches use predicates, limits and sorting in the store, not "fetch all then filter in Swift"; no N+1 relationship faulting in lists.
- Formatters aren't created per call in hot paths; prefer `FormatStyle`.
- Images are downsampled to display size, not stored or rendered at full resolution.

## SwiftUI and UIKit

- `body` is cheap and side-effect free: no sorting/filtering of large data, no service calls, no formatter creation.
- Long bodies split into small `struct` subviews, not `@ViewBuilder` computed properties or functions.
- State ownership: `@State` for owned values and `@Observable` models (iOS 17+), `@Bindable` for bindings, `@Environment` for shared dependencies; no `@ObservedObject` for objects the view creates.
- `ForEach` over stable `Identifiable` ids, never indices or `\.self` on mutable values.
- Colors, fonts, spacing and symbols from the project's design system, not literals.
- Accessibility: labels on icon-only buttons, Dynamic Type not broken by fixed frames, sensible grouping, sufficient contrast.
- Previews compile and use fake data.
- UIKit: no business logic in view controllers, Auto Layout constraints activated once, cells reset in `prepareForReuse`, diffable data sources with stable identifiers.

## Error handling

- Errors are typed and meaningful (`enum ProfileError: Error`), not strings or bare `NSError`; user-facing ones are `LocalizedError` with localized messages.
- No empty `catch {}` and no `try?` that hides a failure the user should see; errors reach the UI as an error state or alert.
- Typed throws (`throws(ProfileError)`) where the error set is closed and callers switch on it.
- Errors are mapped at layer boundaries (an HTTP or database error becomes a domain error in the data layer).
