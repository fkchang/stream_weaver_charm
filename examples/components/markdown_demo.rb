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
