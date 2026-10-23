---
name: swift-code-review
description: Review Swift and SwiftUI code in any iOS/macOS project against software design principles (SOLID, DRY, KISS, YAGNI, Clean Architecture, TDD and testability) and Swift 6 / Apple-platform best practices (value semantics, concurrency, memory, error handling, API design). Use when asked to review code, a diff, a branch, a PR or a file for quality, design or best practices, or before opening a PR. Not a bug hunt only: use the built-in `/code-review` for correctness-focused reviews.
---

# Swift code review (principles and best practices)

Review a change the way a senior iOS engineer would: is it correct, is it in the right place, will it be easy to change and to test? Every finding names a principle, a location and a concrete fix. Praise nothing, pad nothing: if the code is good, say so in one line.

If the repository has its own project-specific review skill (for example `<project>-code-review`), use that one instead: it knows the project's conventions.

## 1. Learn the project first

The project's own rules are the baseline, and a finding that breaks one of them outranks a generic principle. Before judging anything, skim (only what exists):

- `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `CONTRIBUTING.md`, `README.md` architecture sections.
- `.swiftlint.yml` / `.swiftformat` — style the tooling already enforces; don't repeat it as findings.
- `Package.swift` / `Project.swift` / `project.yml` / the xcodeproj build settings — module boundaries, Swift version, language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION`, strict concurrency.
- The architecture in use (MVVM, TCA, VIPER, MV, Clean layers) and the DI approach (initializer injection, Factory, Resolver, Swinject, environment). Find one well-built feature to use as the reference and compare against it.
- Test framework (Swift Testing `import Testing` vs `XCTest`), test targets, and how fakes are provided.

Judge the code by the architecture the project chose, not one you'd prefer. Suggest changing the architecture only when the change itself breaks it.

## 2. Scope the review

Pick the target from the request, defaulting to the current branch's diff against its base:

| Request | Command |
|---------|---------|
| nothing specified | find the base (`develop` if it exists, else `main`/`master`): `git diff <base>...HEAD` plus `git diff` |
| a PR number | `gh pr diff <n>` and `gh pr view <n>` |
| a file or folder | read it whole |
| staged changes | `git diff --cached` |

Read every changed file **in full**, not only the hunks: most design problems (a God object, duplicated logic, a wrong dependency) are invisible in a hunk. Open the collaborators the change touches (protocols, injected services, tests) before judging.

Skip generated and vendored code: `*.xcodeproj`, `*.xcworkspace`, `.build/`, `DerivedData`, `Pods/`, `Carthage/`, Tuist/XcodeGen output, SwiftGen/R.swift output, `*.xcstrings` JSON (check keys exist, not their JSON).

## 3. Check, in this order

Work from the most expensive mistakes to the cheapest. Detailed questions and Swift examples are in [references/checklist.md](references/checklist.md); read the sections that apply.

1. **Correctness** — logic errors, unhandled states (loading/empty/error), off-by-one, optional handling, data loss on save/delete, persistence context misuse.
2. **Architecture (Clean Architecture)** — dependencies point inward (UI → presentation → domain ← data). Domain models don't import SwiftUI, UIKit, CoreData or SwiftData. Feature modules don't depend on each other. Persistence and networking types don't leak above the data layer.
3. **SOLID** — one reason to change per type; extend through protocols or new types, not by growing `switch`es; substitutable conformances; small focused protocols; depend on abstractions that are injected, not on concrete services created inline or singletons.
4. **Concurrency (Swift 6)** — correct isolation (`@MainActor` on UI-facing types where the module isn't MainActor by default), `Sendable` across boundaries; no `@unchecked Sendable` / `nonisolated(unsafe)` without a written justification; no unstructured `Task {}` that outlives its owner; cancellation honored. Load the `swift-concurrency` skill for anything non-trivial.
5. **Testability and TDD** — new behavior has tests; tests exercise behavior through public API; dependencies are injectable so tests can use fakes; tests are deterministic (no real dates, sleeps, shared state). A bug fix comes with a test that fails without the fix.
6. **DRY, KISS, YAGNI** — duplicated knowledge (not just lines) extracted once; no speculative generics, flags or single-conformer protocols "for the future"; the simplest code that passes the tests.
7. **Swift idioms and API design** — value types by default, `final class` otherwise; `let` over `var`; narrowest access control; no force unwraps / `try!`; typed, meaningful errors; names clear at the call site ([Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)).
8. **SwiftUI / UIKit** — small dedicated views, correct state ownership (`@State` + `@Observable` on modern targets), no work in `body`, stable `ForEach` identity, design-system tokens over literals, accessibility. Load `swiftui-pro` for a deep pass on view-heavy diffs.
9. **Project conventions** — localization of user-facing strings, changelog, generated-project rules, commit/PR conventions, anything from step 1.

Principles are tools, not laws. Don't flag a violation that makes the code simpler and has no real cost (a 10-line view model doesn't need a use case layer; two similar lines aren't a DRY problem). Ask: *what breaks or gets harder to change because of this?* If nothing, drop it.

## 4. Verify before reporting

Confirm each candidate finding against the code: open the file, follow the call, check the test target. Drop anything you can't point at a line for. When useful and cheap, run what the project uses: `swiftlint`, `swift test` for packages, or `xcodebuild test` for the affected scheme (run long builds in the background). Report what you ran and its result; never claim tests pass if you didn't run them.

## 5. Report

Group findings by severity, most severe first. Each finding is one bullet:

```markdown
## Review: <target> — <verdict: Ready / Ready after nits / Needs changes>

<One or two sentences: overall assessment and the main theme.>

### 🔴 Must fix
- **[Dependency Inversion]** [`ProfileViewModel.swift:42`](Sources/Profile/ProfileViewModel.swift:42) — The view model creates `APIClient()` directly, so it can't be tested with a fake and couples presentation to networking. → Inject `ProfileServiceProtocol` through the initializer.

### 🟡 Should fix
- **[DRY]** …

### 🔵 Consider
- **[YAGNI]** …

### ✅ Tests
<What is covered, what is missing (name the test you'd write), what was run and its result.>
```

Severity guide:

- **🔴 Must fix** — bugs, data loss, crashes, data races, broken layering, a project rule broken, new behavior with no tests.
- **🟡 Should fix** — SOLID/DRY violations with a real maintenance cost, weak or brittle tests, unclear public API naming.
- **🔵 Consider** — style and small simplifications. Cap at five; drop the rest.

Every fix is concrete: show the replacement code for anything non-obvious (a few lines, not a rewrite). Use clickable `path:line` links. Omit empty severity headings.

## 6. After the review

Don't edit code unless the user asks. If they ask to apply the fixes, make them in severity order, write the missing tests first (red → green → refactor), then run lint and the affected tests.
