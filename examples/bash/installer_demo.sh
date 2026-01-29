#!/bin/bash
# =============================================================================
# INSTALLER DEMO - Verbose Bash Integration (Educational)
# =============================================================================
# Purpose: Shows raw integration without helper library (for understanding)
# Audience: Users wanting to understand how bash integration works internally
#
# Note: Has screen flashing between forms. For clean UX, see:
#   - installer_clean.sh (uses swc.sh helper)
#   - installer_wizard.sh (single TUI session)
#
# Run: ./examples/installer_demo.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORM="$SCRIPT_DIR/bash_form.rb"

# Result file - TUI writes here, we read after
export BASH_FORM_RESULT="/tmp/installer_demo_result.json"

# Helper: extract field from JSON file
json_get() {
    ruby -rjson -e "puts JSON.parse(File.read('$BASH_FORM_RESULT'))['$1']"
}

echo "======================================"
echo "  MyApp Installer Demo"
echo "  (StreamWeaverCharm bash integration)"
echo "======================================"
echo ""

# --- Step 1: Confirm installation ---
echo "Step 1: Confirmation"
# Run TUI directly (no $() capture - TUI needs terminal!)
if ! ruby "$FORM" confirm "Do you want to install MyApp?"; then
    echo "Installation cancelled."
    exit 0
fi

answer=$(json_get "answer")
if [ "$answer" = "No" ]; then
    echo "Installation cancelled."
    exit 0
fi
echo "Confirmed!"
echo ""

# --- Step 2: Choose environment ---
echo "Step 2: Environment Selection"
if ! ruby "$FORM" choice "Select Environment" "development" "staging" "production"; then
    echo "Installation cancelled."
    exit 0
fi

env=$(json_get "choice")
echo "Selected: $env"
echo ""

# --- Step 3: Configure database ---
echo "Step 3: Database Configuration"
if ! ruby "$FORM" choice "Select Database" "PostgreSQL" "MySQL" "SQLite"; then
    echo "Installation cancelled."
    exit 0
fi

db=$(json_get "choice")
echo "Selected: $db"
echo ""

# --- Step 4: Enter project details ---
echo "Step 4: Project Details"
if ! ruby "$FORM" multi "Project Details" \
    "name:Project Name:my-app" \
    "port:Port:3000" \
    "author:Author:"; then
    echo "Installation cancelled."
    exit 0
fi

name=$(json_get "name")
port=$(json_get "port")
author=$(json_get "author")
echo "Name: $name"
echo "Port: $port"
echo "Author: $author"
echo ""

# --- Summary ---
echo "======================================"
echo "  Installation Summary"
echo "======================================"
echo "  Environment: $env"
echo "  Database:    $db"
echo "  Project:     $name"
echo "  Port:        $port"
echo "  Author:      $author"
echo "======================================"
echo ""

# --- Final confirmation ---
if ! ruby "$FORM" confirm "Proceed with installation?"; then
    echo "Installation cancelled."
    exit 0
fi

answer=$(json_get "answer")
if [ "$answer" = "No" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "Installing... (demo - not actually doing anything)"
echo "Done!"

# Cleanup
rm -f "$BASH_FORM_RESULT"
