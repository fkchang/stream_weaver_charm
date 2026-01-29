#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# QUICK INPUT - Agentic Mode (run_once!)
# =============================================================================
# Purpose: One-shot form that returns data to the calling script
# Audience: CLI tools needing structured input, script integrations
#
# Key concept: run_once! blocks until submit, then returns state hash
#
# Run: ruby examples/quick_input.rb
# Controls: Tab to switch fields, Ctrl+S to submit, Ctrl+C to cancel
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

# Create a one-shot form that returns data
result = tui "Quick Input" do
  header1 "User Registration"
  text ""

  box title: "Enter your details" do
    text_input :name, placeholder: "Your name", label: "Name"
    text_input :email, placeholder: "Email address", label: "Email"
    select :role, ["Developer", "Designer", "Manager"], label: "Role"
  end

  text ""
  divider

  # In run_once! mode, these keys will submit the form
  submit_on "ctrl+s", "ctrl+enter"

  help_text "Tab: next | Ctrl+S: submit | Ctrl+C: cancel"
end.run_once!(alt_screen: true)

# result is nil if user cancelled (Ctrl+C), otherwise it's the state hash
if result
  puts "\n✓ Registration complete!"
  puts "  Name:  #{result[:name]}"
  puts "  Email: #{result[:email]}"
  puts "  Role:  #{result[:role]}"
else
  puts "\n✗ Registration cancelled."
end
