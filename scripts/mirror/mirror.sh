#!/usr/bin/env bash
# mirror - bind-mount a source directory to a target location
# usage:
#   mirror mount  <source> [<target>]  - bind-mount source into target base dir
#   mirror umount [-l] <dir>           - unmount by source or target path (-l for lazy)
#   mirror status                      - show active mirrors
#
# Config: ~/.config/mirror/mirror.conf
#   target=/path/to/default/target/base

set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/mirror/mirror.conf"

usage() {
    echo "Usage:"
    echo "  mirror mount  <source> [<target>]  - bind-mount source into target dir"
    echo "  mirror umount [-l] <dir>           - unmount by source or target path (-l for lazy)"
    echo "  mirror status                      - show active mirrors"
    echo ""
    echo "Config: $CONFIG_FILE"
    echo "  target=/path/to/default/target/base"
    exit 1
}

load_default_target() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: config file not found: $CONFIG_FILE"
        echo "Create it with: mkdir -p ~/.config/mirror && echo 'target=/path/to/dir' > $CONFIG_FILE"
        exit 1
    fi
    local raw
    raw=$(grep -E '^target=' "$CONFIG_FILE" | head -1 | cut -d= -f2-)
    if [[ -z "$raw" ]]; then
        echo "Error: 'target' not set in $CONFIG_FILE"
        exit 1
    fi
    # Expand ~ and environment variables like $HOME
    eval echo "$raw"
}

# Find bind mount target for a given source directory
# ZFS bind mounts show SOURCE as pool[/subpath] rather than using "bind" in options
find_target_for_source() {
    local source_dir="$1"
    findmnt --pairs --output TARGET,SOURCE --noheadings | while read -r line; do
        eval "$line"
        # Standard bind mount: SOURCE is the exact path
        if [[ "$SOURCE" == "$source_dir" ]]; then
            echo "$TARGET"
            return
        fi
        # ZFS bind mount: SOURCE is pool[/subpath], where subpath is relative
        # to the dataset mountpoint. Resolve the full source path to compare.
        if [[ "$SOURCE" =~ ^(.+)\[(.+)\]$ ]]; then
            local dataset="${BASH_REMATCH[1]}"
            local subpath="${BASH_REMATCH[2]}"
            local dataset_mountpoint
            dataset_mountpoint=$(findmnt --noheadings --output TARGET --first-only --source "$dataset" 2>/dev/null || true)
            if [[ -n "$dataset_mountpoint" && "$dataset_mountpoint$subpath" == "$source_dir" ]]; then
                echo "$TARGET"
                return
            fi
        fi
    done
}

if [[ $# -lt 1 ]]; then
    usage
fi

cmd="$1"
shift

case "$cmd" in
    mount)
        if [[ $# -lt 1 || $# -gt 2 ]]; then
            echo "Error: mount requires <source> and optionally <target>"
            usage
        fi
        source_dir=$(realpath "$1")

        if [[ $# -eq 2 ]]; then
            target_dir=$(realpath -m "$2")
        else
            default_target=$(load_default_target)
            dir_name=$(basename "$source_dir")
            target_dir=$(realpath -m "${default_target}/${dir_name}")
        fi

        if [[ ! -d "$source_dir" ]]; then
            echo "Error: source directory does not exist: $source_dir"
            exit 1
        fi

        if mountpoint -q "$target_dir" 2>/dev/null; then
            echo "Error: target is already a mountpoint: $target_dir"
            exit 1
        fi

        mkdir -p "$target_dir"
        sudo mount --bind "$source_dir" "$target_dir"
        echo "Mirrored: $source_dir -> $target_dir"
        ;;
    umount)
        umount_opts=()
        if [[ "${1:-}" == "-l" ]]; then
            umount_opts+=(--lazy)
            shift
        fi
        if [[ $# -ne 1 ]]; then
            echo "Error: umount requires <dir>"
            usage
        fi
        dir=$(realpath "$1")

        if mountpoint -q "$dir" 2>/dev/null; then
            # Given path is itself a mountpoint — unmount directly
            sudo umount "${umount_opts[@]}" "$dir"
            rmdir "$dir" 2>/dev/null || true
            echo "Unmirrored: $dir"
        else
            # Assume it's a source dir — find the corresponding target
            target_dir=$(find_target_for_source "$dir")
            if [[ -z "$target_dir" ]]; then
                echo "Error: no mirror found for: $dir"
                exit 1
            fi
            sudo umount "${umount_opts[@]}" "$target_dir"
            rmdir "$target_dir" 2>/dev/null || true
            echo "Unmirrored: $dir -> $target_dir"
        fi
        ;;
    status)
        # Show bind mounts, including ZFS ones (which use pool[/subpath] in SOURCE)
        # grep for standard "bind" option or ZFS bracket notation in SOURCE
        output=$(findmnt --list --output TARGET,SOURCE,OPTIONS --noheadings | \
            grep -vE "^\s*/(nix|sys|proc|dev|run)(/|\s)" | \
            grep -E 'bind|\[.+\]' || true)
        if [[ -z "$output" ]]; then
            echo "No active mirrors found."
        else
            echo "$output"
        fi
        ;;
    *)
        echo "Error: unknown command '$cmd'"
        usage
        ;;
esac
