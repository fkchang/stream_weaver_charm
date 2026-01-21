#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick Input Example - Demonstrates run_once! (agentic mode)
#
# This shows how to use StreamWeaverCharm as a one-shot form
# that returns data to the calling script - perfect for CLI tools
# and agent integrations.
#
# Run with: ruby examples/quick_input.rb

require_relative "../lib/stream_weaver_charm"

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
end.run_once!

# result is nil if user cancelled (Ctrl+C), otherwise it's the state hash
if result
  puts "\n✓ Registration complete!"
  puts "  Name:  #{result[:name]}"
  puts "  Email: #{result[:email]}"
  puts "  Role:  #{result[:role]}"
else
  puts "\n✗ Registration cancelled."
end
