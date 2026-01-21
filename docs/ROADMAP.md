# StreamWeaverCharm Roadmap

**Phase 1 Complete:** Core App, basic components (text, header, divider, box, alert, vstack, hstack), on_key handlers, state management.

**Phase 2 Complete:** Input components (text_input, text_area), focus management with Tab/Shift+Tab cycling, state sync.

---

## Phase 2: Input Components (DONE)

**Goal:** Wrap Bubbles input components to enable form-like TUIs with focus management.

### Components to Add

#### `text_input`
Wraps `Bubbles::TextInput` for single-line text entry.

```ruby
tui "Form" do
  text_input :name, placeholder: "Your name"
  text_input :email, placeholder: "Email address"

  text "Hello, #{state[:name]}!" if state[:name]
end.run!
```

**Implementation:**
- Create `Components::TextInput` that holds a `Bubbles::TextInput` instance
- Sync component value to `state[:key]` after each update
- Forward `Bubbletea::KeyMessage` to focused input
- Render with focus indicator (highlight/cursor visible when focused)

#### `text_area`
Wraps `Bubbles::TextArea` for multi-line text.

```ruby
text_area :bio, placeholder: "Tell us about yourself", rows: 4
```

### Focus Management

Need a focus system since TUIs can only have one active input at a time.

```ruby
tui "Multi-field" do
  state[:_focus] ||= :name  # Internal focus tracking

  text_input :name, focused: state[:_focus] == :name
  text_input :email, focused: state[:_focus] == :email

  on_key "tab" do |s|
    # Cycle focus between inputs
  end
end
```

**Implementation approach:**
- Track `@focused_key` in App
- Track `@input_components` hash mapping keys to Bubbles instances
- In `update()`, forward messages to the focused component
- After each update, sync `@input_components[key].value` → `state[key]`
- Tab cycles focus, Enter may submit or move to next field

### Files to Create/Modify

```
lib/stream_weaver_charm/
├── components/
│   ├── text_input.rb      # NEW
│   └── text_area.rb       # NEW
├── focus_manager.rb       # NEW - handles focus cycling
├── app.rb                 # MODIFY - add input DSL, focus handling
└── components.rb          # MODIFY - require new components
```

### Key Decisions

1. **Focus indicator style:** Bracket the focused field? Color change? Cursor blink?
2. **Tab behavior:** Cycle through all inputs? Or explicit focus control?
3. **Enter behavior:** Submit form? Move to next field? Configurable?

---

## Phase 3: Selection Components

**Goal:** Add list and table components for data display and selection.

### Components to Add

#### `list`
Wraps `Bubbles::List` for scrollable, selectable lists.

```ruby
tui "File Browser" do
  state[:files] ||= ["app.rb", "Gemfile", "README.md"]

  list :selected_file, state[:files]

  text "Selected: #{state[:selected_file]}" if state[:selected_file]
end.run!
```

**Features:**
- j/k navigation (or arrow keys)
- Enter to select
- Optional filtering/search
- Scrolling for long lists

#### `table`
Display tabular data (simpler than StreamWeaver's table, no sorting initially).

```ruby
table headers: ["Name", "Size"], rows: [
  ["app.rb", "12kb"],
  ["cli.rb", "8kb"]
]

# Or from array of hashes
table [
  { name: "Alice", role: "Admin" },
  { name: "Bob", role: "User" }
]
```

**Implementation:**
- Calculate column widths from content
- Render with box-drawing characters for borders
- Optional: row selection, striping

#### `select` (dropdown alternative)
Since TUIs can't do dropdowns, this becomes a list with single selection.

```ruby
select :priority, ["Low", "Medium", "High"]
# Renders as a navigable list, stores selection in state[:priority]
```

### Files to Create

```
lib/stream_weaver_charm/
├── components/
│   ├── list.rb            # NEW
│   ├── table.rb           # NEW
│   └── select.rb          # NEW (alias for single-select list)
```

---

## Phase 4: Theming & Polish

**Goal:** Add theme support and polish the visual appearance.

### Theme System

```ruby
tui "App", theme: :dracula do
  # Uses Dracula color palette
end

# Or custom theme
tui "App", theme: {
  title: { fg: "#FF6B6B", bold: true },
  header: { fg: "#74B9FF", bold: true },
  box_border: "#636E72",
  focus: { fg: "#00B894" }
} do
  # ...
end
```

### Style DSL

Allow inline style definitions:

```ruby
tui "Styled" do
  style :highlight, fg: :yellow, bold: true
  style :muted, fg: :gray, dim: true

  text "Important!", style: :highlight
  text "Less important", style: :muted
end
```

### Built-in Themes

- `:default` - Current ANSI colors
- `:dracula` - Popular dark theme
- `:nord` - Cool blue-gray palette
- `:monokai` - Warm syntax-highlighting colors
- `:solarized_dark` / `:solarized_light`

### Files to Create/Modify

```
lib/stream_weaver_charm/
├── themes/
│   ├── base.rb            # NEW - theme structure
│   ├── default.rb         # NEW
│   ├── dracula.rb         # NEW
│   └── nord.rb            # NEW
├── styles.rb              # MODIFY - theme-aware rendering
└── app.rb                 # MODIFY - accept theme option
```

---

## Phase 5: Advanced Features

### 5a: Mouse Support

Use `Bubblezone` for clickable regions.

```ruby
tui "Clickable" do
  button "Save" do |s|
    s[:saved] = true
  end
  # Renders as: [Save] - clickable with mouse
end
```

**Implementation:**
- Wrap clickable areas with Bubblezone regions
- Handle `Bubbletea::MouseMessage` in update()
- Map mouse clicks to button callbacks

### 5b: Agentic Mode (`run_once!`)

One-shot form that returns data and exits:

```ruby
result = tui "Quick Input" do
  text_input :name
  text_input :email

  submit_on "ctrl+s"  # Or "enter" when all fields filled
end.run_once!

puts result  # => { name: "Alice", email: "alice@example.com" }
```

**Implementation:**
- `run_once!` sets a flag for single-shot mode
- On submit trigger, capture state and call `Bubbletea.quit`
- Return the state hash to caller

### 5c: Spinner / Progress

Show loading states:

```ruby
spinner "Loading..."

progress :download, value: 45, max: 100
# Renders: [████████░░░░░░░░] 45%
```

### 5d: Confirm Dialog

Simple yes/no confirmation:

```ruby
if confirm("Delete this file?")
  # User pressed y
end
```

### Files to Create

```
lib/stream_weaver_charm/
├── components/
│   ├── button.rb          # NEW - clickable button
│   ├── spinner.rb         # NEW
│   └── progress.rb        # NEW
├── mouse_handler.rb       # NEW - Bubblezone integration
└── app.rb                 # MODIFY - run_once!, mouse handling
```

---

## Implementation Priority

| Phase | Effort | Value | Priority |
|-------|--------|-------|----------|
| Phase 2 (Inputs) | Medium | High | **1st** |
| Phase 3 (Lists/Tables) | Medium | High | **2nd** |
| Phase 5b (run_once!) | Low | High | **3rd** |
| Phase 4 (Theming) | Medium | Medium | 4th |
| Phase 5a (Mouse) | High | Medium | 5th |
| Phase 5c/d (Spinner/Confirm) | Low | Low | 6th |

**Recommended order:** 2 → 3 → 5b → 4 → 5a → 5c/d

---

## API Comparison: StreamWeaver vs StreamWeaverCharm

| StreamWeaver (Web) | StreamWeaverCharm (TUI) | Notes |
|-------------------|------------------------|-------|
| `text_field :name` | `text_input :name` | Same pattern |
| `text_area :bio` | `text_area :bio` | Same |
| `select :choice, [...]` | `select :choice, [...]` | Renders as list |
| `button "Click"` | `on_key "enter"` | Key-based (Phase 5a adds mouse) |
| `checkbox :agree` | `toggle :agree` | Space to toggle |
| `table headers:, rows:` | `table headers:, rows:` | Same API |
| `.run!` | `.run!` | Same |
| `.run_once!` | `.run_once!` | Same (Phase 5b) |

---

## Dependencies

Current:
- `bubbletea` ~> 0.1 (core TUI framework)

Phase 2+ may need:
- `bubbles` - Input components (if available as separate gem)
- `bubblezone` - Mouse support (Phase 5a)

Check gem availability:
```bash
gem search bubbles
gem search bubblezone
```

If not available as separate gems, may need to implement input components directly using raw terminal escape sequences.
