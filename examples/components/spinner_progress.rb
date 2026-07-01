#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# SPINNER + PROGRESS - bubbles gem components
# =============================================================================
# Purpose: Demonstrates the spinner and progress DSL methods, powered by
#          Charm's Bubbles gem (github.com/marcoroth/bubbles-ruby)
# Run: ruby examples/components/spinner_progress.rb
# Controls: [space] advance download  [q] quit
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

tui "Spinner + Progress" do
  state[:downloaded] ||= 0

  spinner :loading, label: "Fetching updates..."
  text ""
  progress :download, value: state[:downloaded], max: 100

  text ""
  help_text "[space] advance download  [q] quit"

  on_key "space" do |s|
    s[:downloaded] = [s[:downloaded] + 10, 100].min
  end
end.run!
