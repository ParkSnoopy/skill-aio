#!/usr/bin/env bash
set -euo pipefail
exec 2>&1  # Send errors to stdout.

fail() {
    printf 'Failed: %s\n' "$*"
    exit 1
}

# Expand leading ~ and environment variables ($VAR / ${VAR}) without eval.
expand_path() {
    local raw=$1 out="" var_name
    if [[ "$raw" == "~" || "$raw" == "~/"* ]]; then
        raw="${HOME}${raw:1}"
    fi
    while [[ "$raw" =~ ^([^$]*)\$([A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\})(.*)$ ]]; do
        out+="${BASH_REMATCH[1]}"
        var_name="${BASH_REMATCH[2]}"
        var_name="${var_name#\{}"
        var_name="${var_name%\}}"
        out+="${!var_name-}"
        raw="${BASH_REMATCH[3]}"
    done
    printf '%s%s' "$out" "$raw"
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

if [[ $# -gt 1 ]]; then
    fail 'Usage: install.sh [install_directory]'
elif [[ $# -eq 1 ]]; then
    target=$1
elif ! read -e -r -p 'Install directory: ' target; then
    fail 'Install directory is required.'
fi

target=$(expand_path "$target")
[[ -n "$target" ]] || fail 'Install directory is required.'

mkdir -p -- "$target"
target=$(cd -- "$target" && pwd -P)

linked=0
while IFS= read -r -d '' skill_dir; do
    dest="$target/${skill_dir##*/}"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        printf 'Skipped (existing non-symlink): %s\n' "$dest"
        continue
    fi
    ln -snf -- "$skill_dir" "$dest"
    linked=$((linked + 1))
done < <(
    find "$script_dir" -mindepth 1 \
        \( -name .git -o -samefile "$target" \) -prune -o \
        -type d -exec test -f '{}/SKILL.md' \; -print0
)

if ((linked == 0)); then
    fail 'No skills (SKILL.md) found. Initialize submodules first: git submodule update --init --recursive'
fi

printf 'Linked %d skills into %s\n' "$linked" "$target"
