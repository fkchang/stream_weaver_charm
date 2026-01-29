#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# THEMED - Theme System Demo
# =============================================================================
# Purpose: Shows built-in themes (default, dracula, nord, monokai)
# Audience: Users wanting to customize TUI appearance
#
# Run: ruby examples/themed.rb [theme_name]
# Examples:
#   ruby examples/themed.rb
#   ruby examples/themed.rb dracula
#   ruby examples/themed.rb nord
#   ruby examples/themed.rb monokai
# =============================================================================
#   ruby examples/themed.rb monokai

require_relative "../../lib/stream_weaver_charm"

# Get theme from command line arg, default to dracula
theme_name = (ARGV[0] || "dracula").to_sym

puts "Using theme: #{theme_name}"
puts "Available themes: #{StreamWeaverCharm::Themes::Registry.available.join(', ')}"
puts ""

tui "Theme Demo", theme: theme_name do
  header1 "Theme: #{theme_name.to_s.capitalize}"
  text ""

  # Custom styles
  style :highlight, fg: :cyan, bold: true
  style :muted, fg: :gray, dim: true

  box title: "Headers" do
    header1 "Header 1 - Bold accent"
    header2 "Header 2 - Secondary"
    header3 "Header 3 - Tertiary"
  end

  text ""

  box title: "Text Styles" do
    text "Normal text"
    text "Dimmed text", style: :dim
    text "Help text (italic)", style: :help
    text "Success message", style: :success
    text "Warning message", style: :warning
    text "Error message", style: :error
    text ""
    text "Custom highlight style", style: :highlight
    text "Custom muted style", style: :muted
  end

  text ""

  hstack spacing: 2 do
    alert variant: :info do
      text "Info alert"
    end

    alert variant: :success do
      text "Success!"
    end

    alert variant: :warning do
      text "Warning!"
    end

    alert variant: :error do
      text "Error!"
    end
  end

  text ""

  # Interactive elements
  select :favorite, ["Purple", "Blue", "Green", "Pink"], label: "Favorite color"

  text ""
  divider
  help_text "j/k: navigate | Enter/Space: select | Ctrl+C: quit"
end.run!
