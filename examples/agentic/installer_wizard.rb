#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# INSTALLER WIZARD - Multi-Step Wizard Pattern
# =============================================================================
# Purpose: Single TUI session with multiple steps (no screen flashing)
# Audience: Users building wizard-style flows, multi-step forms
#
# Key concepts:
#   - state[:step] tracks current step
#   - state[:_submit] = true triggers programmatic exit
#   - on_key "enter" advances through steps
#
# Run: ruby examples/installer_wizard.rb
# Bash: ./examples/installer_wizard.sh
# =============================================================================

require_relative "../../lib/stream_weaver_charm"
require "json"

STEPS = [:confirm, :environment, :database, :details, :summary, :final_confirm]

result = tui "MyApp Installer", theme: :default do
  state[:step] ||= 0
  step = STEPS[state[:step]]

  header1 "MyApp Installer"
  text ""

  # Progress indicator
  progress_text = STEPS.each_with_index.map do |s, i|
    if i < state[:step]
      "[done]"
    elsif i == state[:step]
      "[*#{s}*]"
    else
      "[#{s}]"
    end
  end.join(" > ")
  text progress_text, style: :dim
  text ""
  divider
  text ""

  case step
  when :confirm
    box title: "Step 1: Welcome" do
      text "This wizard will guide you through the installation."
      text ""
      select :confirm, ["Continue", "Cancel"], label: "Ready to begin?"
    end

  when :environment
    box title: "Step 2: Environment" do
      select :environment, %w[development staging production], label: "Select environment"
    end

  when :database
    box title: "Step 3: Database" do
      select :database, ["PostgreSQL", "MySQL", "SQLite"], label: "Select database"
    end

  when :details
    box title: "Step 4: Project Details" do
      text_input :name, placeholder: "my-app", label: "Project Name"
      text_input :port, placeholder: "3000", label: "Port"
      text_input :author, placeholder: "Your Name", label: "Author"
    end

  when :summary
    box title: "Step 5: Review" do
      text "Environment: #{state[:environment]}"
      text "Database:    #{state[:database]}"
      text "Project:     #{state[:name]}"
      text "Port:        #{state[:port]}"
      text "Author:      #{state[:author]}"
    end
    text ""
    text "Press Enter to continue to final confirmation.", style: :dim

  when :final_confirm
    box title: "Step 6: Confirm Installation" do
      text "Environment: #{state[:environment]}", style: :dim
      text "Database:    #{state[:database]}", style: :dim
      text "Project:     #{state[:name]}", style: :dim
      text ""
      select :final_confirm, ["Install Now", "Cancel"], label: "Proceed?"
    end
  end

  text ""
  divider

  # Navigation hint based on step
  if step == :details
    help_text "Tab: next field | Enter: continue | Ctrl+C: cancel"
  else
    help_text "↑/↓: navigate | Enter: continue | Ctrl+C: cancel"
  end

  # Handle Enter to advance steps
  on_key "enter" do |s|
    current_step = STEPS[s[:step]]

    case current_step
    when :confirm
      if s[:confirm] == "Cancel"
        s[:_cancelled] = true
      else
        s[:step] += 1
      end

    when :environment, :database
      s[:step] += 1

    when :details
      # Only advance if we have at least a name
      s[:step] += 1 if s[:name] && !s[:name].empty?

    when :summary
      s[:step] += 1

    when :final_confirm
      if s[:final_confirm] == "Cancel"
        s[:_cancelled] = true
        s[:_submit] = true  # Trigger programmatic exit
      else
        s[:_done] = true
        s[:_submit] = true  # Trigger programmatic exit
      end
    end
  end
end.run_once!(alt_screen: true)

# Output result
if result && !result[:_cancelled]
  output = {
    environment: result[:environment],
    database: result[:database],
    name: result[:name],
    port: result[:port],
    author: result[:author]
  }

  # Write to file for bash integration
  result_file = ENV["BASH_FORM_RESULT"] || "/tmp/installer_wizard_result.json"
  File.write(result_file, output.to_json)

  puts ""
  puts "Installation configuration saved!"
  puts "  Environment: #{output[:environment]}"
  puts "  Database:    #{output[:database]}"
  puts "  Project:     #{output[:name]}"
  puts "  Port:        #{output[:port]}"
  puts "  Author:      #{output[:author]}"
  exit 0
else
  puts ""
  puts "Installation cancelled."
  exit 1
end
