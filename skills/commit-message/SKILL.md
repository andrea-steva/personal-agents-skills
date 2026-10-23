---
name: commit-message
description: Write git commit messages (and PR titles) following Conventional Commits 1.0.0 in any repository. Use whenever creating a commit, amending a commit message, suggesting a commit message, or titling a pull request.
---

# Conventional Commit messages

Commit messages follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/#specification). PR titles use the same format: when PRs are squash-merged, the title becomes the commit subject (GitHub appends ` (#N)`).

The project's own instructions win: if `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md` or a commitlint config defines types, scopes, trailers or ticket footers, follow them.

## Structure

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Rules from the spec

1. The subject **must** start with a type, then an optional scope in parentheses, an optional `!`, then `: ` (colon and space), then the description.
2. `feat` **must** be used when a commit adds a new feature; `fix` **must** be used when it fixes a bug.
3. The scope, if present, is a noun describing a section of the codebase in parentheses, e.g. `fix(parser):`.
4. The description **must** immediately follow `: ` and is a short summary of the change.
5. A longer body **may** follow the description, separated from it by **one blank line**. It is free-form and may have several paragraphs.
6. One or more footers **may** follow the body, separated from it by one blank line. Each footer is a token, then `: ` or ` #`, then a value (inspired by git trailers), e.g. `Refs: #12`, `Reviewed-by: Z`.
7. Footer tokens use `-` instead of spaces (`Acked-by`), except `BREAKING CHANGE`, which may be written with a space.
8. Breaking changes **must** be marked either with `!` just before the `:` in the subject, or with a `BREAKING CHANGE: <description>` footer (uppercase), or both. `BREAKING-CHANGE` is a synonym of `BREAKING CHANGE` in footers.
9. Types other than `feat` and `fix` are allowed. The spec treats all units as case-insensitive except `BREAKING CHANGE`, which must be uppercase.

SemVer mapping: `fix` → PATCH, `feat` → MINOR, any breaking change → MAJOR.

## Types to use

| Type | Use for |
|------|---------|
| `feat` | New user-facing feature or new module/package |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests only |
| `docs` | Documentation only (README, CHANGELOG, agent instructions such as `CLAUDE.md`, `AGENTS.md`, `.claude/`, doc comments) |
| `style` | Formatting or lint fixes with no behavior change |
| `build` | `Package.swift`, project generators (Tuist, XcodeGen), dependencies, build settings |
| `ci` | CI configuration and scripts |
| `chore` | Maintenance that fits nothing else (e.g. `.gitignore`, tooling config) |
| `revert` | Reverting a previous commit; the body says `Reverts <sha>` |

## Scopes

Scopes are optional. Use the project's documented scopes if it has any. Otherwise, when the change is confined to one module, package or top-level folder, use its short name in lowercase (e.g. `core`, `ui`, `auth`, `api`, `deps`), and stay consistent with the scopes already used in `git log`. Leave the scope out when a change spans several areas.

## House style

- Description in the imperative mood and lowercase: "add profile screen", not "Added" or "Add…". No trailing period.
- Keep the subject line at 72 characters or fewer.
- One logical change per commit. If the description needs "and", consider splitting the commit; otherwise use the body for the details.
- Wrap body lines at 72 characters. Explain *what* and *why*, not how.
- Reference issues or PRs in footers (`Refs: #12`, `Closes: #12`), not in the subject. GitHub adds ` (#N)` on squash merge, so don't add it yourself.
- Attribution trailers (e.g. `Co-Authored-By:`) only when the project's instructions allow them, and as the last footers.

## Examples

```
feat(auth): add sign in with Apple
```

```
fix(core): keep other items when deleting one

deleteItem cleared the whole store before re-adding the remaining
items, so a failure mid-way lost all data. Delete the single object
by id instead.

Closes: #14
```

```
refactor(api)!: rename UserService.getUsers to fetchAll

BREAKING CHANGE: callers must use fetchAll() instead of getUsers().
```

```
build(deps): bump swift-collections to 1.2.0
```

## Procedure

1. Run `git diff --staged` (or `git diff` if nothing is staged) and `git log --oneline -10` to see the change and the repository's commit conventions.
2. Choose the type, and a scope if the change stays in one area. Decide whether the change is breaking: a change to a public API other modules or clients use, a persistence schema change that needs a migration, or a changed config or CLI contract.
3. Write the message following the rules above. Pass it with a heredoc so the blank lines survive:
   ```sh
   git commit -F- <<'EOF'
   feat(profile): add avatar upload

   Body here.
   EOF
   ```
4. Before committing, check the subject against `^(feat|fix|refactor|perf|test|docs|style|build|ci|chore|revert)(\([a-z0-9-]+\))?!?: [^A-Z].{0,70}[^.]$`.
