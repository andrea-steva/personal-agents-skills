---
name: pull-request
description: Open, update and merge pull requests following the repository's branching model (gitflow when a develop branch exists, where only release and hotfix branches go to main; otherwise trunk-based on the default branch). Use whenever creating a branch for new work, pushing a branch, opening or merging a PR, or cutting a release or hotfix.
---

# Pull requests

## Detect the branching model first

The project's own instructions win: read `CLAUDE.md`, `AGENTS.md` and `CONTRIBUTING.md` for the branching model, base branch, merge method and pre-PR checks. Otherwise detect it:

```sh
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
git ls-remote --heads origin develop
```

**Gitflow** (a `develop` branch exists): `develop` is the integration branch; `main` only holds released versions.

| Branch | Starts from | PR base | Example |
|--------|-------------|---------|---------|
| `feature/<name>` | `develop` | `develop` | `feature/user-profile` |
| `fix/<name>` | `develop` | `develop` | `fix/login-crash` |
| `release/<version>` | `develop` | `main`, then back-merge to `develop` | `release/1.1.0` |
| `hotfix/<name>` | `main` | `main`, then back-merge to `develop` | `hotfix/crash-on-launch` |

Every feature and fix PR targets `develop`. Never open a PR against `main` from any branch other than `release/*` or `hotfix/*`.

**Trunk-based** (no `develop`): `feature/<name>` and `fix/<name>` start from the default branch and merge back into it.

Below, `<base>` is the PR base chosen above. `gh pr create` defaults to the repository's default branch, but always pass `--base` explicitly anyway.

Branch names are lowercase kebab-case after the prefix and describe the change, not a ticket number.

## Start a branch

```sh
git fetch origin
git switch -c feature/<name> origin/<base>
```

If the working tree has uncommitted changes that belong to the new work, they carry over to the new branch; if they belong to something else, ask before moving or stashing them.

## Commit

Commit with the `commit-message` skill. Keep one logical change per commit: even if the PR is squash-merged, separate commits make review easier. Before opening the PR, make sure the work is complete:

- `CHANGELOG.md` has an entry (e.g. under `## Unreleased`) for user-facing changes, if the project keeps one.
- The PR body links the issue (`Closes #<issue>`) when the work has one.
- Any check the project's instructions require is done (translations, generated files, docs).
- The project builds and the tests touched by the change pass, using the commands from its docs.

## Open the PR

```sh
git push -u origin HEAD
gh pr create --base <base> --head "$(git branch --show-current)" --title "<conventional commit subject>" --body-file - <<'EOF'
## Summary

- What changed and why, one bullet per logical change.

## Notes

- Decisions the reviewer should know about, and anything left for later.

Closes #<issue>

## Test plan

- [x] What you ran or checked
- [ ] What still needs a manual check (e.g. on a device)
EOF
```

- The title is a Conventional Commits subject (`commit-message` skill), because it becomes the squash commit subject and GitHub appends ` (#N)`. For a PR with several commits, use the type of the most significant change (`feat` over `fix` over `chore`).
- `Closes #<issue>` closes the issue when the PR merges into the default branch. Drop the line when there is no issue; use `Refs #<issue>` for partial work that shouldn't close it.
- In gitflow, use `--base main` only for `release/*` and `hotfix/*`.
- After opening it, use the `ccd_pr` tools (`get_status`, and `bind_pr` if needed) to read its status when they are available, instead of polling `gh pr checks`.

To update an open PR, commit on the same branch and `git push`. If `<base>` moved and the PR conflicts, merge `origin/<base>` into the branch and resolve the conflicts; don't rebase a branch that is already pushed unless asked.

## Merge the PR

Merging changes `<base>` on GitHub for everyone, so **always ask the user before merging**, naming the PR, its base and the merge method, and wait for a clear yes. Approval to merge one PR does not cover others.

Before asking, check that the PR is open, targets the right base, is mergeable and has no failing checks:

```sh
gh pr view <number> --json state,baseRefName,mergeable,mergeStateStatus,statusCheckRollup
```

Then merge with the project's merge method, a squash by default, keeping the PR title as the commit subject:

```sh
gh pr merge <number> --squash --delete-branch
git switch <base> && git pull --ff-only
```

`--delete-branch` removes the branch on GitHub and locally.

## Releases and hotfixes (gitflow)

Only when the user asks for a release or a hotfix:

1. **Release:** `git switch -c release/<version> origin/develop`, bump the version where the project keeps it (Xcode `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`, a project generator manifest followed by regenerating the project, `package.json`, …), move the `## Unreleased` entries in `CHANGELOG.md` under `## <version>`, then open a PR with `--base main`.
2. **Hotfix:** `git switch -c hotfix/<name> origin/main`, fix, then open a PR with `--base main`.
3. After either is merged into `main` (with the user's approval), tag it (`git tag v<version> && git push origin v<version>`) and open a second PR from `main` into `develop` so `develop` gets the release changes back. Merge `main` into `develop` with a merge commit (`gh pr merge --merge`), not a squash, so the history of the two branches stays connected.

In trunk-based repos, a release is a tag on the default branch (plus the version bump and CHANGELOG move in a regular PR first).
