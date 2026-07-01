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
│   ├── select.rb       # Single-select (radio buttons)
│   ├── button.rb       # Clickable button (mouse support)
│   └── markdown.rb     # Glamour-rendered markdown
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
**Interactive:** `button` (requires `run!(mouse: true)`)
**Loading/Progress:** `spinner`, `progress` (via `bubbles` gem; state lives
directly in `App`'s `@spinners`/`@progress_bars` hashes, not a dedicated
`components/spinner.rb` or `components/progress.rb` file)
**Rich Text:** `markdown` (via `glamour` gem)
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
- `bubbles` ~> 0.1 (Spinner, Progress)
- `glamour` ~> 0.2 (markdown rendering)
- `lipgloss` >= 0.2.2 (transitive dependency of `bubbles`' Progress; the
  version floor matters — 0.2.0 segfaults under repeated Style creation)
- Display/layout components still use raw ANSI codes (`Styles` module), not
  Lipgloss directly

## Current Status

- Phase 1: Core components ✓
- Phase 2: Input components ✓
- Phase 3: Selection components ✓
- Phase 5b: Agentic mode (run_once!) ✓
- Phase 4: Theming & Polish ✓
- Phase 5a: Mouse Support ✓
- Phase 5c: Spinner, Progress ✓ (via `bubbles` gem, plus Markdown via `glamour`)
- Phase 5d: Toggle, Confirm - next (no Charm-Ruby gem available, still hand-rolled)
- See docs/ROADMAP.md for full plan
