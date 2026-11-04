#!/usr/bin/env bash
set -euo pipefail
set +m 2>/dev/null || true

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
project_root="$PWD"
artifact_root="artifacts"

ready_pattern=""
name_prefix="app"
window_process_pattern=""
window_id=""
run_name=""
name=""
output_dir=""
warmup_secs="5"
timeout_secs="120"
repeat_count=1
interval_secs="0"
display_number=""
window_capture=0
keep_running=0
overwrite=0
dry_run=0
launch_requested=0
launch_pid=""
capture_pid=""
launch_args=()

usage() {
    cat <<'EOF'
Usage:
  capture_screenshot.sh [options]
  capture_screenshot.sh [options] --launch -- launch-command [args...]

Capture a macOS screenshot after the selected app is ready and warmed up.

Options:
  --project-root PATH     Target project directory (default: current directory).
  --artifact-root PATH    Artifact boundary, relative to project root (default: artifacts).
  --name-prefix NAME      Default PNG prefix (default: app).
  --run NAME              Write to artifacts/screenshots/NAME/.
  --name NAME             PNG stem. Defaults to <name-prefix>-<timestamp>.
  --output-dir PATH       Override output directory within the configured artifact root.
  --ready-pattern REGEX   pgrep -f pattern; required unless --window-process supplies it.
  --window-process REGEX  Resolve the visible window owned by the matching process.
  --window-id ID          Capture this macOS window ID directly.
  --timeout-secs N        Readiness timeout in whole seconds (default: 120).
  --warmup-secs N         Delay after readiness (default: 5).
  --repeat N              Capture N bounded frames (default: 1).
  --interval-secs N       Delay between repeated frames (default: 0).
  --display N             Capture display N instead of the full desktop.
  --window                Let screencapture interactively select a window.
  --launch                Opt in to launching and owning the command after --.
  --keep-running          Do not stop a process launched with --launch.
  --overwrite             Permit replacing an existing PNG.
  --dry-run               Validate and print the plan without side effects.
  -h, --help              Show this help.

Without --launch, no child process is started: an existing matching app process is
captured and never stopped. The command after -- is executed without a shell only
when --launch is present; keep it foregrounded and bounded.
EOF
}

die() {
    printf 'capture_screenshot: %s\n' "$*" >&2
    exit 1
}

require_value() {
    [[ $# -ge 2 && -n "${2:-}" ]] || die "missing value for $1"
}

valid_component() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

valid_nonnegative_decimal() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

valid_positive_integer() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

is_alive() {
    kill -0 "$1" 2>/dev/null
}

terminate_tree() {
    local pid="$1"
    local signal="$2"
    local child
    local children

    children="$(pgrep -P "$pid" 2>/dev/null || true)"
    for child in $children; do
        terminate_tree "$child" "$signal"
    done
    kill -"$signal" "$pid" 2>/dev/null || true
}

stop_owned_processes() {
    if [[ -n "$capture_pid" ]] && is_alive "$capture_pid"; then
        kill -TERM "$capture_pid" 2>/dev/null || true
        wait "$capture_pid" 2>/dev/null || true
    fi
    capture_pid=""

    if [[ -n "$launch_pid" && "$keep_running" -eq 0 ]]; then
        terminate_tree "$launch_pid" TERM
        sleep 0.5
        terminate_tree "$launch_pid" KILL
        wait "$launch_pid" 2>/dev/null || true
        launch_pid=""
    fi
}

cleanup() {
    local status=$?
    trap - EXIT INT TERM
    stop_owned_processes 2>/dev/null
    exit "$status"
}

on_signal() {
    exit 130
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-root)
            require_value "$@"
            project_root="$2"
            shift 2
            ;;
        --artifact-root)
            require_value "$@"
            artifact_root="$2"
            shift 2
            ;;
        --name-prefix)
            require_value "$@"
            name_prefix="$2"
            shift 2
            ;;
        --run)
            require_value "$@"
            run_name="$2"
            shift 2
            ;;
        --name)
            require_value "$@"
            name="$2"
            shift 2
            ;;
        --output-dir)
            require_value "$@"
            output_dir="$2"
            shift 2
            ;;
        --ready-pattern)
            require_value "$@"
            ready_pattern="$2"
            shift 2
            ;;
        --window-process)
            require_value "$@"
            window_process_pattern="$2"
            shift 2
            ;;
        --window-id)
            require_value "$@"
            window_id="$2"
            shift 2
            ;;
        --timeout-secs)
            require_value "$@"
            timeout_secs="$2"
            shift 2
            ;;
        --warmup-secs)
            require_value "$@"
            warmup_secs="$2"
            shift 2
            ;;
        --repeat)
            require_value "$@"
            repeat_count="$2"
            shift 2
            ;;
        --interval-secs)
            require_value "$@"
            interval_secs="$2"
            shift 2
            ;;
        --display)
            require_value "$@"
            display_number="$2"
            shift 2
            ;;
        --window)
            window_capture=1
            shift
            ;;
        --launch)
            launch_requested=1
            shift
            ;;
        --keep-running)
            keep_running=1
            shift
            ;;
        --overwrite)
            overwrite=1
            shift
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            launch_args=("$@")
            break
            ;;
        *)
            die "unknown option: $1 (use --help)"
            ;;
    esac
done

[[ -d "$project_root" ]] || die "--project-root must be an existing directory"
project_root="$(CDPATH= cd -- "$project_root" && pwd -P)"
valid_component "$name_prefix" || die "invalid --name-prefix: $name_prefix"
[[ -n "$ready_pattern" ]] || ready_pattern="$window_process_pattern"
[[ -n "$ready_pattern" ]] || die "--ready-pattern or --window-process is required"

if [[ -n "$run_name" ]]; then
    valid_component "$run_name" || die "invalid --run name: $run_name"
fi
if [[ "$name" == "" ]]; then
    name="$name_prefix-$(date +%Y%m%d-%H%M%S)"
else
    name="${name%.png}"
fi
valid_component "$name" || die "invalid --name: $name"
valid_positive_integer "$timeout_secs" || die "--timeout-secs must be a positive integer"
valid_nonnegative_decimal "$warmup_secs" || die "--warmup-secs must be a non-negative number"
valid_positive_integer "$repeat_count" || die "--repeat must be a positive integer"
valid_nonnegative_decimal "$interval_secs" || die "--interval-secs must be a non-negative number"
if [[ -n "$display_number" ]]; then
    [[ "$display_number" =~ ^[1-9][0-9]*$ ]] || die "--display must be a positive integer"
fi
if [[ -n "$window_id" ]]; then
    [[ "$window_id" =~ ^[1-9][0-9]*$ ]] || die "--window-id must be a positive integer"
fi
window_mode_count=0
[[ "$window_capture" -eq 1 ]] && window_mode_count=$((window_mode_count + 1))
[[ -n "$window_id" ]] && window_mode_count=$((window_mode_count + 1))
[[ -n "$window_process_pattern" ]] && window_mode_count=$((window_mode_count + 1))
(( window_mode_count <= 1 )) || die "choose only one of --window, --window-id, or --window-process"
if [[ "$window_mode_count" -gt 0 && -n "$display_number" ]]; then
    die "--display cannot be combined with a window selector"
fi

if [[ "$launch_requested" -eq 1 && "${#launch_args[@]}" -eq 0 ]]; then
    die "--launch requires a command after --"
fi
if [[ "$launch_requested" -eq 0 && "${#launch_args[@]}" -gt 0 ]]; then
    die "a command after -- requires explicit --launch; capture mode is independent by default"
fi
if [[ "$keep_running" -eq 1 && "$launch_requested" -eq 0 ]]; then
    die "--keep-running is valid only with --launch"
fi

# Resolve existing ancestors without creating directories, including in dry runs.
# Checking the physical path also rejects a symlink that escapes the artifact root.
canonical_directory() {
    local ancestor="${1%/}"
    [[ -n "$ancestor" ]] || ancestor="/"
    local suffix=""
    while [[ ! -d "$ancestor" ]]; do
        [[ ! -e "$ancestor" && ! -L "$ancestor" ]] || die "not a directory: $ancestor"
        suffix="/${ancestor##*/}$suffix"
        ancestor="${ancestor%/*}"
        [[ -n "$ancestor" ]] || ancestor="/"
    done
    (CDPATH= cd -- "$ancestor" && printf '%s%s\n' "$(pwd -P)" "$suffix")
}

[[ "$artifact_root" == /* ]] || artifact_root="$project_root/$artifact_root"
case "$artifact_root" in
    */..|*/../*|../*|..) die "--artifact-root cannot contain parent-directory traversal" ;;
esac
artifact_root="$(canonical_directory "$artifact_root")"
[[ "$artifact_root" != / ]] || die "--artifact-root must not be the filesystem root"
[[ -n "$output_dir" ]] || output_dir="$artifact_root/screenshots"
[[ "$output_dir" == /* ]] || output_dir="$project_root/$output_dir"
case "$output_dir" in
    */..|*/../*|../*|..) die "--output-dir cannot contain parent-directory traversal" ;;
esac
if [[ -n "$run_name" ]]; then
    output_dir="$output_dir/$run_name"
fi
output_dir="$(canonical_directory "$output_dir")"
case "$output_dir" in
    "$artifact_root"|"$artifact_root"/*) ;;
    *) die "--output-dir must be inside $artifact_root" ;;
esac

cd -- "$project_root"

if [[ "$dry_run" -eq 0 ]]; then
    [[ "$(uname -s)" == "Darwin" ]] || die "macOS is required for /usr/sbin/screencapture"
    [[ -x /usr/sbin/screencapture ]] || die "/usr/sbin/screencapture is not available"
    command -v pgrep >/dev/null 2>&1 || die "pgrep is required for readiness polling"
    trap on_signal INT TERM
    trap cleanup EXIT
fi

if [[ "$launch_requested" -eq 1 ]]; then
    if [[ "$dry_run" -eq 0 ]] && pgrep -f "$ready_pattern" >/dev/null 2>&1; then
        die "a matching app process already exists; refuse to overlap a live session"
    fi
    printf 'Launching:'
    printf ' %q' "${launch_args[@]}"
    printf '\n'
    if [[ "$dry_run" -eq 0 ]]; then
        "${launch_args[@]}" &
        launch_pid=$!
    fi
else
    printf 'Using an existing app process matching: %s\n' "$ready_pattern"
fi

wait_for_ready() {
    local deadline=$((SECONDS + timeout_secs))
    local exit_code

    while (( SECONDS < deadline )); do
        if [[ -n "$launch_pid" ]] && ! is_alive "$launch_pid"; then
            set +e
            wait "$launch_pid"
            exit_code=$?
            set -e
            die "launch command exited before readiness (status $exit_code)"
        fi
        if pgrep -f "$ready_pattern" >/dev/null 2>&1; then
            printf 'Ready process observed; warming up for %s seconds.\n' "$warmup_secs"
            sleep "$warmup_secs"
            pgrep -f "$ready_pattern" >/dev/null 2>&1 || die "the ready process exited during warm-up"
            return 0
        fi
        sleep 0.25
    done
    die "timed out after ${timeout_secs}s waiting for: $ready_pattern"
}

resolve_target_window() {
    local process_pid
    local resolved_id

    [[ -n "$window_process_pattern" ]] || return 0
    [[ -x /usr/bin/swift ]] || die "/usr/bin/swift is required for --window-process"
    process_pid="$(pgrep -f "$window_process_pattern" | head -n 1 || true)"
    [[ -n "$process_pid" ]] || die "no process matched --window-process: $window_process_pattern"
    resolved_id="$(/usr/bin/swift "$script_dir/resolve_window_id.swift" --pid "$process_pid")" || die "could not resolve a visible window for PID $process_pid"
    [[ "$resolved_id" =~ ^[1-9][0-9]*$ ]] || die "window resolver returned an invalid window ID: $resolved_id"
    window_id="$resolved_id"
    printf 'Resolved window ID %s for PID %s.\n' "$window_id" "$process_pid"
}

next_destination() {
    local index="$1"
    local stem="$output_dir/$name"
    local candidate
    local suffix=1

    if (( repeat_count > 1 )); then
        stem="$stem-$(printf '%02d' "$index")"
    fi
    candidate="$stem.png"
    if [[ "$overwrite" -eq 1 && -L "$candidate" ]]; then
        die "refuse to overwrite a screenshot symlink: $candidate"
    fi
    if [[ "$overwrite" -eq 1 || ( ! -e "$candidate" && ! -L "$candidate" ) ]]; then
        printf '%s\n' "$candidate"
        return 0
    fi
    while :; do
        candidate="$stem-$(printf '%02d' "$suffix").png"
        [[ ! -e "$candidate" && ! -L "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
        suffix=$((suffix + 1))
    done
}

capture_one() {
    local index="$1"
    local destination
    local capture_rc
    local capture_args=(-x)

    destination="$(next_destination "$index")"
    if [[ -n "$window_id" ]]; then
        capture_args+=(-l "$window_id")
    elif [[ "$window_capture" -eq 1 ]]; then
        capture_args+=(-w)
    fi
    [[ -n "$display_number" ]] && capture_args+=(-D "$display_number")
    printf 'Screenshot %s/%s: %s\n' "$index" "$repeat_count" "$destination"
    if [[ "$dry_run" -eq 1 ]]; then
        printf 'Would run: /usr/sbin/screencapture'
        printf ' %q' "${capture_args[@]}" "$destination"
        printf '\n'
        return 0
    fi

    mkdir -p "$output_dir"
    /usr/sbin/screencapture "${capture_args[@]}" "$destination" &
    capture_pid=$!
    set +e
    wait "$capture_pid"
    capture_rc=$?
    set -e
    capture_pid=""
    [[ "$capture_rc" -eq 0 ]] || die "screencapture failed with status $capture_rc"
    [[ -s "$destination" ]] || die "screencapture produced no file: $destination"
}

if [[ "$dry_run" -eq 1 ]]; then
    printf 'Dry run: output directory %s\n' "$output_dir"
    printf 'Would wait for readiness pattern: %s\n' "$ready_pattern"
    printf 'Would warm up for %s seconds.\n' "$warmup_secs"
    [[ -n "$window_process_pattern" ]] && printf 'Would resolve a window for process pattern: %s\n' "$window_process_pattern"
else
    wait_for_ready
    resolve_target_window
fi
for (( index=1; index<=repeat_count; index++ )); do
    capture_one "$index"
    if (( index < repeat_count && dry_run == 0 )); then
        sleep "$interval_secs"
    fi
done

printf 'Capture complete: %s\n' "$output_dir"
