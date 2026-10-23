---
name: task-recap
description: Write a short, well-structured recap as the final message of every completed task (a feature, fix, refactor, docs change, investigation, release step). Use at the end of any turn that changed files, ran builds or tests, or finished multi-step work. Not for one-line answers or pure conversation.
---

# Task recap

Every completed task ends with one recap: the last thing in the reply, after all tool calls. It tells the reader in ten seconds **what is now true, how we know, and what is left**. It is a summary, not a log of the session.

If the current project has its own `task-recap` skill, follow that one instead: it carries the project's check names and conventions.

## Template

```markdown
### <status> <Title: what is now true, ≤ 8 words>

<One or two sentences: the outcome and why it matters. No process narration.>

**Changes**
- [`File.ext`](path/to/File.ext) — what changed, in a few words
- [`Other.ext`](path/to/Other.ext:42) — …

**Checks** · `build ✓` · `tests 14/14 ✓` · `lint ✓`

**Next** — <the one open item, decision or follow-up>
```

### Status glyph

Exactly one glyph, in the heading only:

| Glyph | Meaning |
|-------|---------|
| ✅ | Done and verified |
| ⚠️ | Done, but something is unverified or a check failed |
| ⛔ | Blocked: could not finish (say why in the summary) |
| 🔎 | Investigation or question answered, no code changed |

### Sections

- **Title** — the result, not the activity: "Search results keep their order", not "Fixed bug in SearchService".
- **Summary** — one or two sentences. Name the user-visible effect first, then the cause or approach if it is non-obvious.
- **Changes** — one bullet per file or logical group, at most 6; group the rest ("+ 4 translations in `Localizable.xcstrings`"). Files are markdown links relative to the working directory, with `:line` when one spot matters. Omit the section when nothing changed.
- **Checks** — one line of inline-code badges, only for what was actually run this task, named after the project's own tools:
  - `build ✓` / `build ✗`, `tests N/M ✓`, `ui ✓` (UI or end-to-end tests), `lint ✓`, `types ✓` (type checker), `changelog ✓`, plus any check the project's instructions require (for example a translation check).
  - A check that applies but was not run is written as `build –` and named in **Next** or the summary. Never mark ✓ what was not run.
  - Omit the line for docs-only or investigation tasks.
- **Next** — one line: the decision waiting on the user, the follow-up, or the state of git (`uncommitted on main`, `PR open`). Omit when nothing is pending.

## Rules

- **Concise**: 4–12 lines in total. If it needs more, the Changes list is too detailed; group it.
- **Honest**: a failing test or skipped step is stated plainly with ⚠️, never buried.
- **No narration**: no "I first looked at…, then…". No restating the request. No closing pleasantries or "let me know if…".
- **No code blocks** unless the user must run a command; then one `bash` block with one command, placed after **Next**.
- **Plain markdown only**: one `###` heading, bold labels, bullets, inline code. No tables, no extra emoji, no horizontal rules.
- Write in the language the user wrote in; keep file names, code and badge labels in English.
- Refer to PRs and issues as full links (`[owner/repo#94](https://github.com/owner/repo/pull/94)`), never a bare `#94`.
- In the Claude desktop app, the recap is the closing message written after the `wrap_up` call; it does not repeat the question shown in the next-step box.

## Examples

A feature:

```markdown
### ✅ Profile screen shows the join date

Each profile now shows when the user joined, under the name, formatted for the user's locale.

**Changes**
- [`ProfileHeader.swift`](Sources/Profile/ProfileHeader.swift) — join date label
- [`Localizable.xcstrings`](Sources/Profile/Resources/Localizable.xcstrings) — `Joined %@` string
- [`CHANGELOG.md`](CHANGELOG.md) — entry under Unreleased

**Checks** · `build ✓` · `tests 32/32 ✓` · `lint ✓`

**Next** — uncommitted on `feature/profile-join-date`; ready to open the PR.
```

A partial result:

```markdown
### ⚠️ Upload progress survives backgrounding

Progress is now derived from the bytes the server acknowledged instead of a local counter, so it stays correct after the app is suspended.

**Changes**
- [`UploadViewModel.swift`](Sources/Upload/UploadViewModel.swift:58) — progress read from `acknowledgedBytes`

**Checks** · `build ✓` · `tests 11/12 ✗` · `lint ✓`

**Next** — `testPauseResume` still expects the old counter; update it or keep the old pause behavior?
```

An investigation:

```markdown
### 🔎 Dashboard lags because the cache saves late

The dashboard reads the cache before the background save finishes, so it shows the previous data until the next refresh.

**Next** — fix by refreshing after the save completes in `SyncService`; do it here?
```
