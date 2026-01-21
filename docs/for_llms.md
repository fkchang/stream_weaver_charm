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
│   └── text_area.rb    # Multi-line text area
├── focus_manager.rb    # Tab cycling between inputs
└── styles.rb           # ANSI escape codes, box drawing
```

## DSL Methods

**Display:** `text`, `header1/2/3`, `divider`, `help_text`
**Layout:** `vstack`, `hstack`, `box`, `alert`
**Input:** `text_input`, `text_area`
**Behavior:** `on_key`, `quit_on`, `focus`

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
- Phase 3: Selection components (list, table, select) - next
- See docs/ROADMAP.md for full plan
