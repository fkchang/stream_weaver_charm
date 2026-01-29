#!/bin/bash
# =============================================================================
# INSTALLER WIZARD (BASH) - Smoothest UX for Multi-Step
# =============================================================================
# Purpose: Wrapper for wizard.rb - single TUI session, no flashing
# Audience: Users wanting the smoothest multi-step experience
#
# Compare to:
#   - installer_clean.sh (multiple forms, some flashing)
#   - installer_demo.sh (verbose, educational)
#
# Run: ./examples/installer_wizard.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export BASH_FORM_RESULT="/tmp/installer_wizard_result.json"

echo "======================================"
echo "  MyApp Installer (Wizard Mode)"
echo "======================================"
echo ""
echo "Starting wizard..."
echo ""

# Run the wizard - single TUI session for all steps
if ruby "$SCRIPT_DIR/../agentic/installer_wizard.rb"; then
    echo ""
    echo "Reading configuration..."

    # Extract values from JSON result
    env=$(ruby -rjson -e "puts JSON.parse(File.read('$BASH_FORM_RESULT'))['environment']")
    db=$(ruby -rjson -e "puts JSON.parse(File.read('$BASH_FORM_RESULT'))['database']")
    name=$(ruby -rjson -e "puts JSON.parse(File.read('$BASH_FORM_RESULT'))['name']")
    port=$(ruby -rjson -e "puts JSON.parse(File.read('$BASH_FORM_RESULT'))['port']")
    author=$(ruby -rjson -e "puts JSON.parse(File.read('$BASH_FORM_RESULT'))['author']")

    echo ""
    echo "Installing with configuration:"
    echo "  Environment: $env"
    echo "  Database:    $db"
    echo "  Project:     $name"
    echo "  Port:        $port"
    echo "  Author:      $author"
    echo ""
    echo "Installing... (demo - not actually doing anything)"
    echo "Done!"

    rm -f "$BASH_FORM_RESULT"
else
    echo ""
    echo "Installation cancelled."
    exit 1
fi
