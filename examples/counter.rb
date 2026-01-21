#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple counter example demonstrating StreamWeaverCharm basics
#
# Run: ruby examples/counter.rb
# Controls: + to increment, - to decrement, q to quit

require_relative "../lib/stream_weaver_charm"

tui "Counter" do
  state[:count] ||= 0

  box title: "Simple Counter" do
    text "Count: #{state[:count]}", style: state[:count] < 0 ? :dim : nil
  end

  text ""
  help_text "[+/-] change  [q] quit"

  on_key "+" do |s|
    s[:count] += 1
  end

  on_key "-" do |s|
    s[:count] -= 1
  end

  on_key "=" do |s|
    s[:count] += 1  # Also allow = (shift not needed on some keyboards)
  end
end.run!
