#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# TODO - Full Application Example
# =============================================================================
# Purpose: Complete todo app showing state management, lists, and keyboard UX
# Audience: Users wanting to see a full TUI application pattern
#
# Run: ruby examples/todo.rb
# Controls: j/k to navigate, space to toggle, a to add, d to delete, q to quit
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

tui "Todo List" do
  state[:todos] ||= [
    { text: "Learn StreamWeaverCharm", done: false },
    { text: "Build something cool", done: false },
    { text: "Share with friends", done: false }
  ]
  state[:selected] ||= 0

  header1 "My Tasks"
  divider

  if state[:todos].empty?
    text "(no tasks)", style: :dim
  else
    state[:todos].each_with_index do |todo, i|
      selected = state[:selected] == i
      checkbox = todo[:done] ? "[x]" : "[ ]"
      prefix = selected ? ">" : " "

      style = if todo[:done]
        :dim
      elsif selected
        nil
      else
        nil
      end

      text "#{prefix} #{checkbox} #{todo[:text]}", style: style
    end
  end

  divider
  text ""

  completed = state[:todos].count { |t| t[:done] }
  total = state[:todos].size
  text "#{completed}/#{total} completed", style: :dim

  text ""
  help_text "j/k: move | space: toggle | d: delete | q: quit"

  # Navigation
  on_key "j" do |s|
    max = s[:todos].size - 1
    s[:selected] = [s[:selected] + 1, max].min if max >= 0
  end

  on_key "k" do |s|
    s[:selected] = [s[:selected] - 1, 0].max
  end

  # Toggle done
  on_key "space" do |s|
    if s[:todos][s[:selected]]
      s[:todos][s[:selected]][:done] ^= true
    end
  end

  # Delete
  on_key "d" do |s|
    if s[:todos][s[:selected]]
      s[:todos].delete_at(s[:selected])
      s[:selected] = [s[:selected], s[:todos].size - 1].min
      s[:selected] = 0 if s[:selected] < 0
    end
  end
end.run!
