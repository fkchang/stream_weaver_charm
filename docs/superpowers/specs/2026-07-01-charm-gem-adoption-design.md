# Charm-Ruby Gem Adoption: First Slice (bubbles + glamour)

## Context

stream_weaver_charm currently hand-rolls all TUI components on top of the bare
`bubbletea` gem. Charm's own Ruby ports of its Go ecosystem (showcased at
charm-ruby.dev, published by marcoroth) turn out to be real, installable gems
rather than something we'd need to reimplement from the original Go source.
Research findings, per gem:

| Gem | Status | Decision |
|---|---|---|
| `bubbles` (v0.1.1) | Published, has Spinner + Progress with idiomatic Bubbletea `update`/`view` API | **Adopt** |
| `glamour` (v0.2.2) | Published, static `render(markdown, style:, width:)` → ANSI string, real theming | **Adopt** |
| `huh` (form validation) | Not actually published (2 commits, no releases), and architecturally a standalone form runner that competes with our `tui` block | Skip — keep hand-rolling validation |
| `ntcharts`, `gum`, `bubblezone`, `harmonica`, `lipgloss` | Viable but each has its own migration cost or re-trial spike needed | Deferred to later slices |

This spec covers only the first slice: adopting `bubbles` (Spinner, Progress)
and `glamour` (markdown rendering). Toggle/Confirm (ROADMAP Phase 5d) stay
custom since no gem provides them. Everything else in the table above is out
of scope here.

## Goal

Replace the planned from-scratch Phase 5c build (Spinner, Progress) with
thin wrappers around `bubbles`, and add markdown rendering (a capability we
have zero of today) via `glamour`. Ship both as one PR since they're
independent, low-risk, additive gems.

## Scope

**In scope:**
- Add `bubbles` and `glamour` as gem dependencies (gemspec)
- New DSL methods: `spinner`, `progress`, `markdown` (or `md`)
- New component wrappers in `lib/stream_weaver_charm/components/`:
  `spinner.rb`, `progress.rb`, `markdown.rb`, following the existing
  `Components::*` pattern (see `button.rb`, `text_input.rb`)
- Spinner animation requires periodic re-render — use Bubbletea's
  `TickCommand` (already available in the installed `bubbletea` gem) the same
  way input components already integrate with `App#update`
- Update `docs/ROADMAP.md`: mark Phase 5c as done via gem adoption instead of
  custom build
- Update `docs/for_llms.md` DSL Methods section
- New examples: `examples/components/spinner_progress.rb`,
  `examples/components/markdown_demo.rb`; update `examples/README.md`
- Tests: `test/test_spinner.rb`, `test/test_progress.rb`,
  `test/test_markdown.rb` following existing `test/test_*.rb` conventions

**Out of scope (explicitly deferred):**
- Toggle / Confirm components (still hand-rolled, ROADMAP Phase 5d, unchanged)
- `ntcharts`, `gum`, `bubblezone`, `harmonica` adoption
- `lipgloss` re-trial spike (separate spike — needs its own crash-repro test
  before touching the styling layer)
- Any changes to the public-facing examples showcase webpage — per earlier
  discussion, that only makes sense once we're further along on parity

## Component Design

`markdown` is stateless — `Components::Markdown#render` calls
`Glamour.render(content, style: theme_style, width: ...)` and returns the
ANSI string, same shape as `Components::Text`. No new state-management
needed.

`spinner` and `progress` are stateful like `TextInput`: an instance persists
in a per-key component hash (mirroring `@input_components`) so the spinner's
current frame / progress's current percent survives across re-renders.
Spinner additionally needs the app's `update()` loop to schedule and handle a
`TickCommand` to advance frames — this is new territory (no existing
component ticks), so it needs its own small integration in `app.rb` rather
than reusing the input-forwarding path input components use today.

## Risks

- `bubbles` is young (v0.1.1, 2 releases) — smoke-test Spinner/Progress
  directly before wiring into the DSL, since a broken upstream gem would be a
  bad foundation
- Tick-driven re-render is new to this codebase — confirm it doesn't conflict
  with the existing focus/input update path in `app.rb`
