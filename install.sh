#!/usr/bin/env bash
# Links every skill in skills/ into ~/.claude/skills so Claude Code picks them up globally.
# Symlinks keep the installed skills in sync with this repo: edit here, commit, then `git pull` wherever the repo is cloned.
#
# Usage: ./install.sh            link all skills
#        ./install.sh --force    replace existing skills with the same name (moved to a backup first)
#
# Backups go next to the skills folder, not inside it, or Claude Code would load them as duplicate skills.

set -euo pipefail

repo_dir="$(cd "$(dirname "$0")" && pwd)"
target_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
backup_dir="${target_dir%/}-backup"
force=false
[[ "${1:-}" == "--force" ]] && force=true

mkdir -p "$target_dir"

for skill in "$repo_dir"/skills/*/; do
    name="$(basename "$skill")"
    dest="$target_dir/$name"

    if [[ -L "$dest" && "$(readlink "$dest")" == "${skill%/}" ]]; then
        echo "ok      $name (already linked)"
        continue
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        if ! $force; then
            echo "skip    $name ($dest exists; rerun with --force to replace it)"
            continue
        fi
        mkdir -p "$backup_dir"
        backup="$backup_dir/$name.backup-$(date +%Y%m%d%H%M%S)"
        mv "$dest" "$backup"
        echo "backup  $name -> $backup"
    fi

    ln -s "${skill%/}" "$dest"
    echo "linked  $name"
done
