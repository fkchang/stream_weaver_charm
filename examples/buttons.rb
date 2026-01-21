#!/usr/bin/env ruby
# frozen_string_literal: true

# Buttons Example - Demonstrates mouse support
#
# Run with: ruby examples/buttons.rb
#
# Click buttons with your mouse!

require_relative "../lib/stream_weaver_charm"

tui "Button Demo" do
  header1 "Button Demo"
  text ""

  state[:count] ||= 0
  state[:message] ||= "Click a button!"

  box title: "Counter" do
    text "Count: #{state[:count]}"
    text ""

    hstack spacing: 2 do
      button "Increment" do |s|
        s[:count] += 1
        s[:message] = "Incremented to #{s[:count]}"
      end

      button "Decrement" do |s|
        s[:count] -= 1
        s[:message] = "Decremented to #{s[:count]}"
      end

      button "Reset" do |s|
        s[:count] = 0
        s[:message] = "Reset to 0"
      end
    end
  end

  text ""

  box title: "Status" do
    text state[:message], style: :success
  end

  text ""

  # Buttons also work without mouse (keyboard shortcuts could be added)
  button "Quit" do |_s|
    # This will be clickable with mouse
  end

  text ""
  divider
  help_text "Click buttons with mouse | Ctrl+C: quit"
end.run!(mouse: true)
