#!/bin/bash
# =============================================================================
# INSTALLER CLEAN - Recommended Bash Integration Pattern
# =============================================================================
# Purpose: Shows cleanest way to add TUI prompts to shell scripts
# Audience: Shell script authors (START HERE for bash integration)
#
# Compare to: installer_demo.sh (verbose/raw approach)
#
# Run: ./examples/installer_clean.sh
# =============================================================================

set -e
source "$(dirname "$0")/swc.sh"

echo "=== MyApp Installer ==="
echo ""

# One-liner confirmation
swc_confirm "Ready to install MyApp?" || exit 0

# Simple choices - result goes to $SWC_CHOICE
swc_choice "Environment" development staging production
env=$SWC_CHOICE

swc_choice "Database" PostgreSQL MySQL SQLite
db=$SWC_CHOICE

# Multi-field form - results go to $SWC_name, $SWC_port, $SWC_author
swc_multi "Project Details" \
    "name:Project Name:my-app" \
    "port:Port:3000" \
    "author:Author:"

# Show summary
echo ""
echo "=== Configuration ==="
echo "  Environment: $env"
echo "  Database:    $db"
echo "  Project:     $SWC_name"
echo "  Port:        $SWC_port"
echo "  Author:      $SWC_author"
echo ""

# Final confirm
swc_confirm "Install with these settings?" || exit 0

echo "Installing... done!"
