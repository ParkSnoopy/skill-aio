#!/usr/bin/env bash
set -euo pipefail
exec 2>&1  # Send errors to stdout.

fail() {
    printf 'Failed: %s\n' "$*"
    exit 1
}

printf 'Warning: this script uses eval; input can execute shell commands. Enter trusted input only.\n'

# Enable Tab completion; require a destination with no default.
if ! read -e -r -p 'Install directory: ' target || [[ -z "$target" ]]; then
    fail 'Install directory is required.'
fi

# Expand shell expressions, including ~, $VARIABLE, and ${VARIABLE}.
eval "target=$target"
[[ -n "$target" ]] || fail 'Install directory is empty after expansion.'

mkdir -p -- "$target"
target=$(realpath -e -- "$target")

# Skip the destination; link subfolders containing SKILL.md.
find "$(pwd -P)" -mindepth 1 \
    -samefile "$target" -prune -o \
    -type d -exec test -f '{}/SKILL.md' \; \
    -exec ln -snf -t "$target" -- {} +
