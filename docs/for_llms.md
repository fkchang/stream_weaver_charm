# StreamWeaverCharm - LLM Reference

## What It Is

StreamWeaverCharm is a declarative Ruby DSL for building reactive terminal UIs (TUIs). It uses the same reactive model as StreamWeaver (web) but targets terminal interfaces via Charm's Bubbletea.

**Core insight:** The Ruby block re-executes on every user interaction. No manual event handling or screen updates needed.

## Architecture

- Wraps Bubbletea (Elm Architecture): Model (state hash) → Update (key handlers) → View (DSL block)
- State persists across renders; components rebuild each view() call
- Input components persist instances for cursor/focus state

## Key Files

```
lib/stream_weaver_charm/
├── app.rb              # Main App class, DSL methods, Bubbletea integration
├── components.rb       # Display components (Text, Header, Box, etc.)
├── components/
│   ├── text_input.rb   # Single-line text input
│   ├── text_area.rb    # Multi-line text area
│   ├── list.rb         # Scrollable, selectable list
│   ├── table.rb        # Tabular data display
│   └── select.rb       # Single-select (radio buttons)
├── focus_manager.rb    # Tab cycling between inputs
├── styles.rb           # ANSI escape codes, theme-aware rendering
└── themes/
    ├── base.rb         # Theme structure and color conversion
    ├── registry.rb     # Theme lookup by name
    ├── default.rb      # Default ANSI colors
    ├── dracula.rb      # Dracula dark theme
    ├── nord.rb         # Nord arctic theme
    └── monokai.rb      # Monokai warm theme
```

## DSL Methods

**Display:** `text`, `header1/2/3`, `divider`, `help_text`
**Layout:** `vstack`, `hstack`, `box`, `alert`
**Input:** `text_input`, `text_area`
**Selection:** `list`, `table`, `select`
**Behavior:** `on_key`, `quit_on`, `focus`, `submit_on`
**Styling:** `style` (define custom styles)
**Execution:** `run!` (interactive), `run_once!` (agentic - returns state hash)
**Theming:** Pass `theme: :dracula` (or :nord, :monokai, or custom hash) to `tui`

## Input Component Pattern

```ruby
# In App#text_input:
input = @input_components[key] ||= Components::TextInput.new(key, ...)
@focus_manager.register(key)
@components << Components::Text.new(input.render)

# In App#update:
# Tab → focus_next, KeyMessage → forward to focused input, sync value to state
```

## Important Implementation Details

1. **ANSI-aware width calculation:** `Styles.visible_length` strips escape codes before measuring
2. **Focus persists across renders:** FocusManager.clear preserves focused_key, only clears registration list
3. **Ctrl+C always quits:** Even when input is focused (other quit keys blocked during typing)
4. **Input components live in @input_components hash:** Persist cursor position across re-renders

## Dependencies

- `bubbletea` ~> 0.1 (Ruby bindings for Charm's Bubbletea)
- Uses raw ANSI codes (not Lipgloss, due to Go runtime issues)

## Current Status

- Phase 1: Core components ✓
- Phase 2: Input components ✓
- Phase 3: Selection components ✓
- Phase 5b: Agentic mode (run_once!) ✓
- Phase 4: Theming & Polish ✓
- Phase 5a: Mouse Support - next
- See docs/ROADMAP.md for full plan
