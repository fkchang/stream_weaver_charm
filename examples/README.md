# StreamWeaverCharm Examples

## Directory Structure

```
examples/
├── basic/          # Start here - minimal examples
├── components/     # Form inputs, lists, tables, themes
├── agentic/        # One-shot forms (run_once!)
├── bash/           # Shell script integration
└── README.md
```

## Quick Start

```bash
# Simplest example - interactive counter
ruby examples/basic/counter.rb

# Mouse-enabled buttons
ruby examples/basic/buttons_simple.rb

# Bash integration
./examples/bash/installer_clean.sh
```

---

## basic/ - Getting Started

| File | Description |
|------|-------------|
| `counter.rb` | Minimal example - keyboard counter |
| `buttons_simple.rb` | Mouse-clickable buttons |
| `buttons.rb` | Buttons with hstack layout |

```bash
ruby examples/basic/counter.rb
```

---

## components/ - Form & Display Components

| File | Description |
|------|-------------|
| `form.rb` | Text inputs with focus management |
| `file_browser.rb` | List component for file selection |
| `themed.rb` | Theme system (dracula, nord, monokai) |
| `todo.rb` | Full todo app with multiple components |

```bash
ruby examples/components/form.rb
ruby examples/components/themed.rb dracula
```

---

## agentic/ - One-Shot Forms (run_once!)

For scripts that collect input and return data.

| File | Description |
|------|-------------|
| `quick_input.rb` | Simple one-shot form |
| `installer_wizard.rb` | Multi-step wizard in single TUI |

```bash
ruby examples/agentic/quick_input.rb
```

---

## bash/ - Shell Script Integration

Add rich TUI prompts to shell scripts.

| File | Description |
|------|-------------|
| `swc.sh` | **Helper library** - source this |
| `installer_clean.sh` | Clean demo (START HERE) |
| `installer_demo.sh` | Verbose demo (educational) |
| `installer_wizard.sh` | Wizard wrapper (smoothest UX) |
| `bash_form.rb` | CLI backend (internal) |
| `custom_deploy_form.rb` | Custom form template |

### Quick Start

```bash
#!/bin/bash
source "path/to/examples/bash/swc.sh"

swc_confirm "Ready?" || exit 0

swc_choice "Environment" dev staging prod
echo "Selected: $SWC_CHOICE"

swc_input "Project name" "my-app"
echo "Name: $SWC_INPUT"

swc_multi "Config" "name:Name:" "port:Port:3000"
echo "Project $SWC_name on port $SWC_port"
```

### Run Examples

```bash
./examples/bash/installer_clean.sh    # Recommended
./examples/bash/installer_wizard.sh   # Smoothest (no flashing)
./examples/bash/installer_demo.sh     # Verbose (educational)
```

---

## Key Patterns

### Interactive TUI
```ruby
tui "App" do
  # components...
end.run!
```

### Mouse Support
```ruby
tui "Clickable" do
  button "Click" { |s| s[:count] += 1 }
end.run!(mouse: true)
```

### One-Shot Form
```ruby
result = tui "Form" do
  text_input :name
  submit_on "ctrl+s"
end.run_once!(alt_screen: true)
```

### Multi-Step Wizard
```ruby
tui "Wizard" do
  on_key "enter" do |s|
    s[:step] += 1
    s[:_submit] = true if done
  end
end.run_once!(alt_screen: true)
```
