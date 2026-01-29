#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# BASH FORM - CLI Backend for Bash Integration
# =============================================================================
# Purpose: Provides CLI interface for swc.sh helper functions
# Audience: Internal use by swc.sh (users don't call this directly)
#
# Commands:
#   ruby bash_form.rb choice "Title" opt1 opt2 opt3
#   ruby bash_form.rb confirm "Question?"
#   ruby bash_form.rb input "Prompt" "placeholder"
#   ruby bash_form.rb multi "Title" "key:Label:placeholder" ...
#   ruby bash_form.rb form custom_form.rb
#
# Output: Writes JSON to $BASH_FORM_RESULT file
# =============================================================================

require_relative "../../lib/stream_weaver_charm"
require "json"

def form_choice(title, *options)
  tui title do
    text ""
    select :choice, options
    text ""
    help_text "↑/↓: navigate | Enter: select | Ctrl+C: cancel"
    submit_on "enter"
  end.run_once!(alt_screen: true)
end

def form_confirm(question)
  tui "Confirm" do
    text ""
    text question
    text ""
    select :answer, ["Yes", "No"]
    text ""
    help_text "↑/↓: navigate | Enter: select | Ctrl+C: cancel"
    submit_on "enter"
  end.run_once!(alt_screen: true)
end

def form_input(prompt, placeholder: "")
  tui "Input" do
    text ""
    text_input :value, placeholder: placeholder, label: prompt
    text ""
    help_text "Enter: submit | Ctrl+C: cancel"
    submit_on "enter", "ctrl+s"
  end.run_once!(alt_screen: true)
end

def form_multi_input(title, *fields)
  # fields are "key:label:placeholder" format
  parsed = fields.map do |f|
    parts = f.split(":", 3)
    { key: parts[0].to_sym, label: parts[1] || parts[0], placeholder: parts[2] || "" }
  end

  tui title do
    text ""
    parsed.each do |f|
      text_input f[:key], label: f[:label], placeholder: f[:placeholder]
    end
    text ""
    divider
    help_text "Tab: next field | Ctrl+S: submit | Ctrl+C: cancel"
    submit_on "ctrl+s", "ctrl+enter"
  end.run_once!(alt_screen: true)
end

def form_custom(file)
  load file
end

# --- Main ---

command = ARGV.shift

case command
when "choice"
  title = ARGV.shift || "Select"
  result = form_choice(title, *ARGV)
when "confirm"
  question = ARGV.shift || "Are you sure?"
  result = form_confirm(question)
when "input"
  prompt = ARGV.shift || "Enter value"
  placeholder = ARGV.shift || ""
  result = form_input(prompt, placeholder: placeholder)
when "multi"
  title = ARGV.shift || "Form"
  result = form_multi_input(title, *ARGV)
when "form"
  file = ARGV.shift
  if file && File.exist?(file)
    result = form_custom(file)
  else
    warn "Usage: bash_form.rb form <file.rb>"
    exit 2
  end
else
  warn "Usage: bash_form.rb <choice|confirm|input|multi|form> [args...]"
  warn ""
  warn "Commands:"
  warn "  choice <title> <opt1> <opt2> ...   Select from options"
  warn "  confirm <question>                  Yes/No confirmation"
  warn "  input <prompt> [placeholder]        Single text input"
  warn "  multi <title> key:label:ph ...      Multiple text inputs"
  warn "  form <file.rb>                      Load custom form file"
  exit 2
end

if result
  # Write JSON to result file (use env var or default location)
  result_file = ENV["BASH_FORM_RESULT"] || "/tmp/bash_form_result.json"
  File.write(result_file, result.to_json)
  exit 0
else
  # Clean up result file on cancel
  result_file = ENV["BASH_FORM_RESULT"] || "/tmp/bash_form_result.json"
  File.delete(result_file) if File.exist?(result_file)
  exit 1
end
