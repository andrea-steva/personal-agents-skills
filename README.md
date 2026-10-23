# Personal agent skills

My [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills), kept in one place and installed with a single script.

| Skill | What it does |
|-------|--------------|
| [`swift-code-review`](skills/swift-code-review/SKILL.md) | Reviews Swift/SwiftUI code against SOLID, DRY, KISS, YAGNI, Clean Architecture, TDD and Swift 6 best practices, after learning the project's own conventions. Checklist with examples in [`references/checklist.md`](skills/swift-code-review/references/checklist.md). |
| [`task-recap`](skills/task-recap/SKILL.md) | Ends every completed task with a short, structured recap: what is now true, how we know, what is left. |
| [`commit-message`](skills/commit-message/SKILL.md) | Writes commit messages and PR titles following Conventional Commits 1.0.0. |
| [`pull-request`](skills/pull-request/SKILL.md) | Opens, updates and merges pull requests following the repository's branching model: gitflow (`develop` integration branch, `release/*` and `hotfix/*` to `main`) or trunk-based. |

Every skill defers to the project's own instructions (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`) when they define conventions.

## Install

```sh
git clone https://github.com/andrea-steva/personal-agents-skills.git
cd personal-agents-skills
./install.sh
```

The script symlinks each folder in `skills/` into `~/.claude/skills/`, so editing a skill here updates it everywhere. Skills already present with the same name are skipped; `./install.sh --force` replaces them after moving the old copy to `~/.claude/skills-backup/<name>.backup-<timestamp>` (outside the skills folder, so it isn't loaded as a duplicate skill). Set `CLAUDE_SKILLS_DIR` to install somewhere else.

To update: `git pull` in the repo (symlinks need nothing else). New skills need `./install.sh` again.

## Global vs project skills

Personal skills in `~/.claude/skills` take precedence over a project's `.claude/skills` with the same name. When a project needs its own variant, give it a project-prefixed name (for example `<project>-code-review`) so both stay reachable.

## Add a skill

1. Create `skills/<name>/SKILL.md` with `name` and `description` frontmatter (plus optional `references/`, `scripts/`).
2. Run `./install.sh`, commit and push.
