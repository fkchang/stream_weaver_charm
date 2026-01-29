#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# BUTTONS SIMPLE - Basic Mouse Support
# =============================================================================
# Purpose: Demonstrates clickable buttons with mouse support
# Audience: Users wanting to add mouse interaction to their TUIs
#
# Run: ruby examples/buttons_simple.rb
# Controls: Click buttons with mouse, Ctrl+C to quit
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

tui "Simple Buttons" do
  state[:count] ||= 0

  text "Count: #{state[:count]}"
  text ""

  button "Increment (+1)" do |s|
    s[:count] += 1
  end

  text ""

  button "Decrement (-1)" do |s|
    s[:count] -= 1
  end

  text ""

  button "Reset" do |s|
    s[:count] = 0
  end

  text ""
  divider
  help_text "Click buttons with mouse | Ctrl+C: quit"
end.run!(mouse: true)
