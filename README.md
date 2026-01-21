# StreamWeaverCharm

**Reactive TUI applications using StreamWeaver's declarative Ruby DSL, powered by Charm's Bubbletea.**

StreamWeaverCharm brings the same reactive model from [StreamWeaver](https://github.com/fkchang/stream_weaver) (web UIs) to terminal interfaces. Your Ruby block re-executes on every user interaction, creating reactive TUIs without manual event handling.

## Installation

```ruby
gem 'stream_weaver_charm'
```

Or install directly:

```bash
gem install stream_weaver_charm
```

**Requirements:** Ruby 3.2+

## Quick Start

```ruby
require 'stream_weaver_charm'

tui "Counter" do
  state[:count] ||= 0

  box title: "Simple Counter" do
    text "Count: #{state[:count]}"
  end

  help_text "[+/-] change  [q] quit"

  on_key "+" do |s|
    s[:count] += 1
  end

  on_key "-" do |s|
    s[:count] -= 1
  end
end.run!
```

Run: `ruby counter.rb`

## The Key Insight

**Your Ruby block re-executes on every key press.**

Press `+`:
1. The `on_key "+"` callback runs: `s[:count] += 1`
2. The entire block re-executes with updated state
3. The TUI re-renders showing the new count

No manual screen updates. No state synchronization. Just Ruby.

## Components

### Display

```ruby
text "Plain text"
text "Dimmed", style: :dim
text "Success!", style: :success

header1 "Big Title"
header "Section"      # h2
header3 "Subsection"

divider              # ────────────
```

### Layout

```ruby
vstack spacing: 1 do
  text "Vertical"
  text "Stack"
end

hstack spacing: 2 do
  text "Side"
  text "by"
  text "Side"
end

box title: "Card" do
  text "Content inside a bordered box"
end
```

### Alerts

```ruby
alert variant: :info do
  text "Information"
end

alert variant: :success do
  text "It worked!"
end

alert variant: :warning do
  text "Be careful"
end

alert variant: :error do
  text "Something went wrong"
end
```

### Key Bindings

```ruby
on_key "+" do |s|
  s[:count] += 1
end

on_key "enter" do |s|
  s[:submitted] = true
end

on_key "ctrl+s" do |s|
  # Save
end

# Default quit keys: q, ctrl+c
# Customize with:
quit_on "q", "esc"
```

### Input Components

```ruby
# Single-line text input
text_input :name, placeholder: "Your name", label: "Name"
text_input :email, placeholder: "Email address"

# Multi-line text area
text_area :bio, placeholder: "Tell us about yourself", rows: 4, label: "Bio"

# Access values via state
text "Hello, #{state[:name]}!" if state[:name]
```

**Focus management:** Tab cycles between inputs, Shift+Tab goes backward. First input auto-focuses.

### Help Text

```ruby
help_text "j/k: move | space: toggle | q: quit"
```

## State

State is a hash. Access with `state[:key]`:

```ruby
tui "Example" do
  state[:name] ||= "World"
  state[:items] ||= []

  text "Hello, #{state[:name]}!"
  text "Items: #{state[:items].join(', ')}"
end
```

## Examples

### Todo List

```ruby
tui "Todo" do
  state[:todos] ||= [
    { text: "Learn StreamWeaverCharm", done: false },
    { text: "Build something cool", done: false }
  ]
  state[:selected] ||= 0

  header1 "My Tasks"
  divider

  state[:todos].each_with_index do |todo, i|
    prefix = state[:selected] == i ? ">" : " "
    check = todo[:done] ? "[x]" : "[ ]"
    style = todo[:done] ? :dim : nil
    text "#{prefix} #{check} #{todo[:text]}", style: style
  end

  divider
  help_text "j/k: move | space: toggle | q: quit"

  on_key "j" do |s|
    s[:selected] = [s[:selected] + 1, s[:todos].size - 1].min
  end

  on_key "k" do |s|
    s[:selected] = [s[:selected] - 1, 0].max
  end

  on_key "space" do |s|
    s[:todos][s[:selected]][:done] ^= true
  end
end.run!
```

## Architecture

StreamWeaverCharm wraps Charm's [Bubbletea](https://github.com/charmbracelet/bubbletea) (the Elm Architecture for TUIs):

- **Model**: Your `state` hash
- **Update**: Key handlers (`on_key`) modify state
- **View**: Your DSL block renders the UI

The block re-executes on every `view()` call, just like StreamWeaver re-renders on every HTTP request.

## Style System

StreamWeaverCharm uses ANSI escape codes for styling (not Lipgloss, due to Go runtime issues with the Ruby bindings). Built-in styles:

- `:dim` - Muted gray text
- `:help` - Italic gray (for hints)
- `:success` - Green
- `:warning` - Orange
- `:error` - Red

## StreamWeaver Family

| Project | Target | Status |
|---------|--------|--------|
| [StreamWeaver](https://github.com/fkchang/stream_weaver) | Web (browser) | Stable |
| StreamWeaverCharm | TUI (terminal) | Alpha |
| StreamWeaverNative | Native (desktop) | Planned |
| StreamWeaverMobile | Mobile | Planned |

Same DSL. Different targets. One mental model.

## License

MIT
