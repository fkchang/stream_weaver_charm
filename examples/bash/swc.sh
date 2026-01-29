#!/bin/bash
# =============================================================================
# SWC.SH - Bash Integration Helper Library
# =============================================================================
# Purpose: Add rich TUI prompts to shell scripts with minimal code
# Audience: Shell script authors wanting better user interaction
#
# Usage: source this file, then use swc_* functions
#
#   source swc.sh
#
#   swc_confirm "Delete files?" && rm -rf tmp/
#
#   swc_choice "Select DB" postgres mysql sqlite
#   echo "Selected: $SWC_CHOICE"
#
#   swc_input "Project name" "my-app"
#   echo "Name: $SWC_INPUT"
#
# See: installer_clean.sh for a complete example
# =============================================================================

_SWC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_SWC_FORM="$_SWC_DIR/bash_form.rb"
_SWC_RESULT_FILE="/tmp/swc_result_$$.json"

export BASH_FORM_RESULT="$_SWC_RESULT_FILE"

# Internal: run form and parse result
_swc_run() {
    ruby "$_SWC_FORM" "$@"
}

_swc_get() {
    ruby -rjson -e "puts JSON.parse(File.read('$_SWC_RESULT_FILE'))['$1']" 2>/dev/null
}

# Confirm dialog - returns 0 for Yes, 1 for No/Cancel
# Usage: swc_confirm "Are you sure?" && do_something
swc_confirm() {
    local question="${1:-Are you sure?}"
    if _swc_run confirm "$question"; then
        [[ "$(_swc_get answer)" == "Yes" ]]
    else
        return 1
    fi
}

# Choice selection - result in $SWC_CHOICE
# Usage: swc_choice "Pick one" opt1 opt2 opt3
swc_choice() {
    local title="$1"; shift
    if _swc_run choice "$title" "$@"; then
        SWC_CHOICE="$(_swc_get choice)"
        return 0
    else
        SWC_CHOICE=""
        return 1
    fi
}

# Text input - result in $SWC_INPUT
# Usage: swc_input "Your name" "default"
swc_input() {
    local prompt="${1:-Enter value}"
    local placeholder="${2:-}"
    if _swc_run input "$prompt" "$placeholder"; then
        SWC_INPUT="$(_swc_get value)"
        return 0
    else
        SWC_INPUT=""
        return 1
    fi
}

# Multi-field form - results in $SWC_name, $SWC_email, etc.
# Usage: swc_multi "Details" "name:Name:default" "email:Email:"
swc_multi() {
    local title="$1"; shift
    if _swc_run multi "$title" "$@"; then
        # Export each field as SWC_fieldname
        for field in "$@"; do
            local key="${field%%:*}"
            local value="$(_swc_get "$key")"
            eval "SWC_$key=\"\$value\""
        done
        return 0
    else
        return 1
    fi
}

# Cleanup on exit
_swc_cleanup() {
    rm -f "$_SWC_RESULT_FILE"
}
trap _swc_cleanup EXIT
