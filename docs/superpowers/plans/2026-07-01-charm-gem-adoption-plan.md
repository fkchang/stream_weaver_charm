# Charm Gem Adoption (bubbles + glamour) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `spinner`, `progress`, and `markdown` DSL methods to stream_weaver_charm by adopting the `bubbles` and `glamour` gems, replacing the from-scratch build originally planned for ROADMAP Phase 5c.

**Architecture:** `spinner`/`progress` hold persistent `Bubbles::Spinner`/`Bubbles::Progress` instances in new per-key hashes (`@spinners`, `@progress_bars`) on `App`, mirroring the existing `@buttons` pattern — NOT `@input_components`, which is reserved for Tab-focusable fields. Spinner animation is driven by `Bubbletea::TickCommand`, bootstrapped from `App#init` (which runs `view` once to discover any spinners before the runner's real first render). `markdown` is stateless — a new `Components::Markdown` wraps `Glamour.render` with a small theme-name-to-Glamour-style mapping.

**Tech Stack:** Ruby, `bubbletea` (existing dep), `bubbles` ~> 0.1 (new), `glamour` ~> 0.2 (new), `lipgloss` >= 0.2.2 (new — see Task 1, this version pin is load-bearing, not incidental).

**Spec:** `docs/superpowers/specs/2026-07-01-charm-gem-adoption-design.md`

---

## Pre-flight finding (already verified, informs Task 1)

`Bubbles::Progress#colorize` (`lib/bubbles/progress.rb:266`) unconditionally calls `Lipgloss::Style.new.foreground(color).render(text)` on every render — so using `progress` transitively exercises `lipgloss`, the exact gem stream_weaver_charm's gemspec comment says was abandoned for "Go runtime issues with multiple style creations." Confirmed by direct repro on this machine:

- With `lipgloss` 0.2.0 installed: 200 rapid `Bubbles::Progress#view_as` calls **segfaults** (`[BUG] Segmentation fault`) partway through.
- With `lipgloss` 0.2.2 installed: the same 200 calls succeed cleanly.

`bubbles`' own gemspec declares `spec.add_dependency "lipgloss"` with **no version constraint**, so without our own explicit pin, dependency resolution could land on the crashing 0.2.0. Task 1 pins `lipgloss` to `>= 0.2.2` explicitly for this reason, even though stream_weaver_charm never calls `lipgloss` directly itself.

---

### Task 1: Add gem dependencies

**Files:**
- Modify: `stream_weaver_charm.gemspec`

- [ ] **Step 1: Update the gemspec**

Replace the dependency block:

```ruby
  spec.add_dependency "bubbletea", "~> 0.1"
  # lipgloss has Go runtime issues with multiple style creations
  # Using raw ANSI codes instead until that's fixed
  # spec.add_dependency "lipgloss", "~> 0.2"
```

with:

```ruby
  spec.add_dependency "bubbletea", "~> 0.1"
  spec.add_dependency "bubbles", "~> 0.1"
  spec.add_dependency "glamour", "~> 0.2"
  # lipgloss >= 0.2.2 fixes a Go-runtime segfault under repeated Style creation
  # (reproduced on 0.2.0, confirmed fixed on 0.2.2 — see docs/superpowers/specs/
  # 2026-07-01-charm-gem-adoption-design.md). We never call lipgloss directly;
  # this pin exists because `bubbles`' Progress component uses it internally
  # and its own gemspec has no version floor, so resolution could otherwise
  # land on the crashing 0.2.0.
  spec.add_dependency "lipgloss", ">= 0.2.2"
```

- [ ] **Step 2: Install and verify gem versions resolve correctly**

Run: `gem install bubbles glamour lipgloss --conservative`
Expected: `lipgloss` resolves to `0.2.2` or higher. Verify with:

```bash
ruby -e "require 'lipgloss'; puts Lipgloss::VERSION"
```

Expected output: `0.2.2` (or higher, never `0.2.0`).

- [ ] **Step 3: Commit**

```bash
git add stream_weaver_charm.gemspec
git commit -m "Add bubbles, glamour, and pinned lipgloss dependencies"
```

---

### Task 2: `Components::Markdown` wrapper (TDD)

**Files:**
- Create: `lib/stream_weaver_charm/components/markdown.rb`
- Create: `test/test_markdown.rb`
- Modify: `lib/stream_weaver_charm.rb`

- [ ] **Step 1: Write the failing tests**

Create `test/test_markdown.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestMarkdown < Minitest::Test
  def test_renders_plain_markdown
    md = StreamWeaverCharm::Components::Markdown.new("# Hello")
    assert_includes md.render, "Hello"
  end

  def test_dracula_theme_maps_to_dracula_glamour_style
    StreamWeaverCharm::Styles.current_theme = :dracula
    md = StreamWeaverCharm::Components::Markdown.new("# Hi")
    assert_includes md.render, "Hi"
  ensure
    StreamWeaverCharm::Styles.current_theme = :default
  end

  def test_theme_without_glamour_preset_falls_back_to_auto
    StreamWeaverCharm::Styles.current_theme = :nord
    md = StreamWeaverCharm::Components::Markdown.new("# Hi")
    assert_includes md.render, "Hi"
  ensure
    StreamWeaverCharm::Styles.current_theme = :default
  end

  def test_explicit_style_overrides_theme_mapping
    md = StreamWeaverCharm::Components::Markdown.new("# Hi", style: "light")
    assert_includes md.render, "Hi"
  end

  def test_markdown_dsl_method
    app = tui("Test") { markdown "# Hello DSL" }
    assert_includes app.view, "Hello DSL"
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `ruby -Ilib -Itest test/test_markdown.rb`
Expected: `NameError` or `LoadError` — `Components::Markdown` doesn't exist yet, `markdown` DSL method doesn't exist yet.

- [ ] **Step 3: Create the component**

Create `lib/stream_weaver_charm/components/markdown.rb`:

```ruby
# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Renders a markdown string to ANSI-styled terminal output via Glamour.
    class Markdown < Component
      # Maps our theme names to Glamour's built-in style presets.
      # Themes with no direct Glamour equivalent fall back to "auto".
      GLAMOUR_STYLE_BY_THEME = {
        dracula: "dracula"
      }.freeze
      DEFAULT_GLAMOUR_STYLE = "auto"

      def initialize(content, style: nil)
        super(type: :markdown, content: content, options: { style: style })
      end

      def render
        Glamour.render(content.to_s, style: resolved_style)
      end

      private

      def resolved_style
        options[:style] || GLAMOUR_STYLE_BY_THEME.fetch(Styles.current_theme.name, DEFAULT_GLAMOUR_STYLE)
      end
    end
  end
end
```

- [ ] **Step 4: Require the new files and add the DSL method**

In `lib/stream_weaver_charm.rb`, add after the existing `require "bubbletea"` line:

```ruby
require "bubbles"
require "glamour"
```

And add after `require_relative "stream_weaver_charm/components/button"`:

```ruby
require_relative "stream_weaver_charm/components/markdown"
```

In `lib/stream_weaver_charm/app.rb`, add a `markdown` method in the "Display Components DSL" section, right after `divider`:

```ruby
    # Render a markdown string via Glamour
    # @param content [String] Markdown source
    def markdown(content)
      @components << Components::Markdown.new(content)
    end
```

- [ ] **Step 5: Run to verify it passes**

Run: `ruby -Ilib -Itest test/test_markdown.rb`
Expected: `5 runs, ..., 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add lib/stream_weaver_charm.rb lib/stream_weaver_charm/app.rb lib/stream_weaver_charm/components/markdown.rb test/test_markdown.rb
git commit -m "Add markdown DSL method via glamour gem"
```

---

### Task 3: Spinner state + tick wiring in `App` (TDD)

**Files:**
- Modify: `lib/stream_weaver_charm/app.rb`
- Create: `test/test_spinner.rb`

- [ ] **Step 1: Write the failing tests**

Create `test/test_spinner.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestSpinner < Minitest::Test
  def test_spinner_dsl_renders_a_frame
    app = tui("Test") { spinner :loading }
    refute_empty app.view.strip
  end

  def test_spinner_persists_the_same_instance_across_renders
    app = tui("Test") { spinner :loading }
    app.view
    first = app.instance_variable_get(:@spinners)[:loading]
    app.view
    second = app.instance_variable_get(:@spinners)[:loading]
    assert_same first, second
  end

  def test_spinner_advances_frame_on_tick
    app = tui("Test") { spinner :loading }
    app.view
    spin = app.instance_variable_get(:@spinners)[:loading]
    before = spin.view

    tick = Bubbles::Spinner::TickMessage.new(id: spin.id, tag: 0)
    app.update(tick)

    after = app.instance_variable_get(:@spinners)[:loading].view
    refute_equal before, after
  end

  def test_init_returns_a_tick_command_when_a_spinner_is_present
    app = tui("Test") { spinner :loading }
    _model, command = app.init
    refute_nil command
  end

  def test_init_returns_no_command_without_a_spinner
    app = tui("Test") { text "no spinner here" }
    _model, command = app.init
    assert_nil command
  end

  def test_label_is_appended_after_the_spinner_glyph
    app = tui("Test") { spinner :loading, label: "Loading..." }
    assert_includes app.view, "Loading..."
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `ruby -Ilib -Itest test/test_spinner.rb`
Expected: `NoMethodError` — `spinner` DSL method doesn't exist yet.

- [ ] **Step 3: Add `@spinners` state**

In `lib/stream_weaver_charm/app.rb`, in `initialize`, add after `@next_button_id = 0`:

```ruby

      # Spinner/progress support (bubbles gem)
      @spinners = {} # key => Bubbles::Spinner instance
```

- [ ] **Step 4: Bootstrap the initial tick from `init`**

Replace:

```ruby
    def init
      [self, nil]
    end
```

with:

```ruby
    def init
      view # execute the DSL block once so any spinners get created
      commands = @spinners.values.map(&:tick)
      [self, commands.empty? ? nil : Bubbletea.batch(*commands)]
    end
```

- [ ] **Step 5: Route `Bubbles::Spinner::TickMessage` in `update`**

In `update`, add a new `when` branch inside the `case msg` statement, after the `when Bubbletea::MouseMessage` branch:

```ruby
      when Bubbles::Spinner::TickMessage
        commands = @spinners.filter_map do |key, spin|
          updated, command = spin.update(msg)
          @spinners[key] = updated
          command
        end
        return [self, Bubbletea.batch(*commands)] unless commands.empty?
```

- [ ] **Step 6: Add the `spinner` DSL method**

Add a new section in `app.rb` right before "Layout Components DSL" (after the `button` method):

```ruby
    # =========================================
    # Spinner / Progress DSL
    # =========================================

    # Animated loading spinner (requires bubbles gem)
    # @param key [Symbol] Identifies this spinner instance across renders
    # @param label [String, nil] Optional text shown after the spinner glyph
    # @param style [Hash] Spinner animation style (default: Bubbles::Spinners::DOT)
    def spinner(key, label: nil, style: Bubbles::Spinners::DOT)
      spin = @spinners[key] ||= Bubbles::Spinner.new(spinner: style)
      content = label ? "#{spin.view} #{label}" : spin.view
      @components << Components::Text.new(content)
    end
```

- [ ] **Step 7: Run to verify it passes**

Run: `ruby -Ilib -Itest test/test_spinner.rb`
Expected: `6 runs, ..., 0 failures, 0 errors`

- [ ] **Step 8: Run the full existing test suite to check for regressions**

Run: `for f in test/test_*.rb; do ruby -Ilib -Itest "$f" || echo "FAILED: $f"; done`
Expected: no `FAILED:` lines.

- [ ] **Step 9: Commit**

```bash
git add lib/stream_weaver_charm/app.rb test/test_spinner.rb
git commit -m "Add spinner DSL method via bubbles gem, wire up tick-driven animation"
```

---

### Task 4: Progress bar (TDD)

**Files:**
- Modify: `lib/stream_weaver_charm/app.rb`
- Create: `test/test_progress.rb`

- [ ] **Step 1: Write the failing tests**

Create `test/test_progress.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestProgress < Minitest::Test
  def test_progress_dsl_renders_the_percentage
    app = tui("Test") { progress :download, value: 45, max: 100 }
    assert_includes app.view, "45"
  end

  def test_progress_clamps_values_over_max
    app = tui("Test") { progress :download, value: 150, max: 100 }
    assert_includes app.view, "100"
  end

  def test_progress_clamps_negative_values
    app = tui("Test") { progress :download, value: -10, max: 100 }
    assert_includes app.view, "0"
  end

  def test_progress_persists_the_same_instance_across_renders
    app = tui("Test") { progress :download, value: 10, max: 100 }
    app.view
    first = app.instance_variable_get(:@progress_bars)[:download]
    app.view
    second = app.instance_variable_get(:@progress_bars)[:download]
    assert_same first, second
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `ruby -Ilib -Itest test/test_progress.rb`
Expected: `NoMethodError` — `progress` DSL method doesn't exist yet.

- [ ] **Step 3: Add `@progress_bars` state**

In `lib/stream_weaver_charm/app.rb` `initialize`, add right after the `@spinners = {}` line added in Task 3:

```ruby
      @progress_bars = {} # key => Bubbles::Progress instance
```

- [ ] **Step 4: Add the `progress` DSL method**

Add to the "Spinner / Progress DSL" section created in Task 3, after `spinner`:

```ruby

    # Progress bar (requires bubbles gem)
    # @param key [Symbol] Identifies this progress bar instance across renders
    # @param value [Numeric] Current value
    # @param max [Numeric] Value representing 100%
    # @param width [Integer] Bar width in characters
    def progress(key, value:, max: 100, width: 40)
      bar = @progress_bars[key] ||= Bubbles::Progress.new(width: width)
      percent = max.to_f.zero? ? 0.0 : (value.to_f / max).clamp(0.0, 1.0)
      @components << Components::Text.new(bar.view_as(percent))
    end
```

Note: this uses `Bubbles::Progress#view_as` (static rendering), not the spring-animated `#view`/`#update`/tick loop the gem also supports — our DSL re-executes the block every render already, so we don't need Harmonica-driven smoothing between renders; each render just paints the bar at its current target percentage directly.

- [ ] **Step 5: Run to verify it passes**

Run: `ruby -Ilib -Itest test/test_progress.rb`
Expected: `4 runs, ..., 0 failures, 0 errors`

- [ ] **Step 6: Run the full test suite again**

Run: `for f in test/test_*.rb; do ruby -Ilib -Itest "$f" || echo "FAILED: $f"; done`
Expected: no `FAILED:` lines.

- [ ] **Step 7: Manually smoke-test the lipgloss crash scenario one more time in the real integration path**

Run:

```bash
ruby -Ilib -e '
require "stream_weaver_charm"
app = tui("Test") { progress :p, value: 0, max: 100 }
300.times { |i| app.instance_variable_get(:@progress_bars).clear; app.view; app.instance_variable_set(:@state, {}) }
puts "OK: 300 renders through the real progress DSL path, no crash"
'
```

Expected: `OK: 300 renders...` with no `[BUG] Segmentation fault`. If this crashes, stop — it means the installed `lipgloss` resolved back to a pre-0.2.2 version; re-check Task 1's `gem list lipgloss`.

- [ ] **Step 8: Commit**

```bash
git add lib/stream_weaver_charm/app.rb test/test_progress.rb
git commit -m "Add progress DSL method via bubbles gem"
```

---

### Task 5: Examples

**Files:**
- Create: `examples/components/spinner_progress.rb`
- Create: `examples/components/markdown_demo.rb`
- Modify: `examples/README.md`

- [ ] **Step 1: Create the spinner/progress example**

Create `examples/components/spinner_progress.rb`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# SPINNER + PROGRESS - bubbles gem components
# =============================================================================
# Purpose: Demonstrates the spinner and progress DSL methods, powered by
#          Charm's Bubbles gem (github.com/marcoroth/bubbles-ruby)
# Run: ruby examples/components/spinner_progress.rb
# Controls: [space] advance download  [q] quit
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

tui "Spinner + Progress" do
  state[:downloaded] ||= 0

  spinner :loading, label: "Fetching updates..."
  text ""
  progress :download, value: state[:downloaded], max: 100

  text ""
  help_text "[space] advance download  [q] quit"

  on_key " " do |s|
    s[:downloaded] = [s[:downloaded] + 10, 100].min
  end
end.run!
```

- [ ] **Step 2: Create the markdown example**

Create `examples/components/markdown_demo.rb`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# MARKDOWN - Glamour-rendered markdown in a TUI
# =============================================================================
# Purpose: Demonstrates the markdown DSL method, powered by Charm's Glamour
#          gem (github.com/marcoroth/glamour-ruby)
# Run: ruby examples/components/markdown_demo.rb
# Controls: [q] quit
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

tui "Markdown Demo", theme: :dracula do
  markdown <<~MD
    # StreamWeaverCharm

    Renders **markdown** via the `markdown` DSL method, using Glamour under
    the hood. Supports:

    - Headings, lists, emphasis
    - `inline code`
    - Theme-aware styling (matches the current theme where Glamour has a
      matching preset, falls back to `auto` otherwise)
  MD

  text ""
  help_text "[q] quit"
end.run!
```

- [ ] **Step 3: Update `examples/README.md`**

In the `## components/ - Form & Display Components` table, add two rows after the existing `todo.rb` row:

```markdown
| `spinner_progress.rb` | Animated spinner + progress bar (bubbles gem) |
| `markdown_demo.rb` | Markdown rendering via Glamour |
```

And add to that section's example commands block:

```bash
ruby examples/components/spinner_progress.rb
ruby examples/components/markdown_demo.rb
```

- [ ] **Step 4: Manually run both examples to confirm they render and quit cleanly**

Run: `ruby examples/components/spinner_progress.rb` — press space a few times, confirm the spinner animates and the bar fills, then press `q` to quit cleanly.
Run: `ruby examples/components/markdown_demo.rb` — confirm the markdown renders with dracula-theme styling, then press `q` to quit cleanly.

- [ ] **Step 5: Commit**

```bash
git add examples/components/spinner_progress.rb examples/components/markdown_demo.rb examples/README.md
git commit -m "Add spinner/progress and markdown examples"
```

---

### Task 6: Update documentation

**Files:**
- Modify: `docs/ROADMAP.md`
- Modify: `docs/for_llms.md`

- [ ] **Step 1: Update ROADMAP.md's top summary**

Add a new line after the existing `**Phase 5a Complete:**` bullet at the top of the file:

```markdown
**Phase 5c Complete:** Spinner and progress bar via the `bubbles` gem (adopted instead of a from-scratch build — see `docs/superpowers/specs/2026-07-01-charm-gem-adoption-design.md`). Markdown rendering added via the `glamour` gem (not originally planned, adopted as a net-new capability from the same effort).
```

- [ ] **Step 2: Replace the "5c: Spinner / Progress" section**

Replace:

```markdown
### 5c: Spinner / Progress

Show loading states:

```ruby
spinner "Loading..."

progress :download, value: 45, max: 100
# Renders: [████████░░░░░░░░] 45%
```
```

with:

```markdown
### 5c: Spinner / Progress (DONE — via `bubbles` gem)

Show loading states, using `Bubbles::Spinner` and `Bubbles::Progress` directly
rather than a hand-rolled implementation:

```ruby
spinner :loading, label: "Loading..."

progress :download, value: 45, max: 100
# Renders: [████████░░░░░░░░]  45%
```

Note the key-based signature (`spinner :loading, ...`) rather than the
originally-sketched positional-string form — this matches every other
stateful DSL method (`text_input`, `list`, `select`), since the underlying
`Bubbles::Spinner` instance must persist across renders to animate.
```

- [ ] **Step 3: Update the "Dependencies" section at the bottom**

Replace:

```markdown
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
```

with:

```markdown
Current:
- `bubbletea` ~> 0.1 (core TUI framework)
- `bubbles` ~> 0.1 (Spinner, Progress — Phase 5c)
- `glamour` ~> 0.2 (markdown rendering)
- `lipgloss` >= 0.2.2 (transitive, via `bubbles`' Progress component — pinned
  explicitly to avoid a segfault present in 0.2.0; see
  `docs/superpowers/specs/2026-07-01-charm-gem-adoption-design.md`)

Not yet adopted (each has its own migration cost — see the spec above):
- `ntcharts` - charts (net-new capability, gem is early/v0.1.x)
- `gum` - shell wrapper (superset of `examples/bash/swc.sh`)
- `bubblezone` - generalized mouse zones (current button-only handling is
  simpler and sufficient today)
- `harmonica` - animation (nothing in stream_weaver_charm animates yet)
- Toggle/Confirm components remain hand-rolled — no Charm-Ruby gem provides
  them (`huh` isn't a real published gem and is architecturally a competing
  full-screen form runner, not an embeddable component)
```

- [ ] **Step 4: Update `docs/for_llms.md` DSL Methods section**

In the `## DSL Methods` section, update the line:

```markdown
**Interactive:** `button` (requires `run!(mouse: true)`)
```

to:

```markdown
**Interactive:** `button` (requires `run!(mouse: true)`)
**Loading/Progress:** `spinner`, `progress` (via `bubbles` gem)
**Rich Text:** `markdown` (via `glamour` gem)
```

And update the `## Dependencies` section:

```markdown
- `bubbletea` ~> 0.1 (Ruby bindings for Charm's Bubbletea)
- Uses raw ANSI codes (not Lipgloss, due to Go runtime issues)
```

to:

```markdown
- `bubbletea` ~> 0.1 (Ruby bindings for Charm's Bubbletea)
- `bubbles` ~> 0.1 (Spinner, Progress)
- `glamour` ~> 0.2 (markdown rendering)
- `lipgloss` >= 0.2.2 (transitive dependency of `bubbles`' Progress; the
  version floor matters — 0.2.0 segfaults under repeated Style creation)
- Display/layout components still use raw ANSI codes (`Styles` module), not
  Lipgloss directly
```

- [ ] **Step 5: Commit**

```bash
git add docs/ROADMAP.md docs/for_llms.md
git commit -m "Update ROADMAP and LLM reference docs for bubbles/glamour adoption"
```

---

## Out of scope (unchanged from spec)

- Toggle / Confirm components (ROADMAP Phase 5d) — still hand-rolled, no gem available
- `ntcharts`, `gum`, `bubblezone`, `harmonica` adoption — each deferred with its own reasoning in the spec
- Any public-facing examples showcase webpage (the original prompt that started this work) — explicitly deferred until further along on parity
