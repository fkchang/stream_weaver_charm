# frozen_string_literal: true

require "bubbletea"
# Note: lipgloss has Go runtime issues with multiple style creations
# Using raw ANSI codes via Styles module instead

require_relative "stream_weaver_charm/version"
require_relative "stream_weaver_charm/themes/base"
require_relative "stream_weaver_charm/themes/default"
require_relative "stream_weaver_charm/themes/dracula"
require_relative "stream_weaver_charm/themes/nord"
require_relative "stream_weaver_charm/themes/monokai"
require_relative "stream_weaver_charm/themes/registry"
require_relative "stream_weaver_charm/styles"
require_relative "stream_weaver_charm/components"
require_relative "stream_weaver_charm/focus_manager"
require_relative "stream_weaver_charm/components/text_input"
require_relative "stream_weaver_charm/components/text_area"
require_relative "stream_weaver_charm/components/list"
require_relative "stream_weaver_charm/components/table"
require_relative "stream_weaver_charm/components/select"
require_relative "stream_weaver_charm/app"

# StreamWeaverCharm - Declarative Ruby DSL for building TUI applications
#
# Uses the same reactive model as StreamWeaver (web), but targets terminal UIs
# via Charm's Bubbletea (Elm Architecture) and Lipgloss (styling).
#
# @example Basic usage
#   require 'stream_weaver_charm'
#
#   tui "Counter" do
#     state[:count] ||= 0
#
#     text "Count: #{state[:count]}"
#
#     on_key "+" do |s|
#       s[:count] += 1
#     end
#
#     on_key "-" do |s|
#       s[:count] -= 1
#     end
#   end.run!
module StreamWeaverCharm
  class Error < StandardError; end
end

# Global helper method for DSL
#
# @param title [String] The title of the application
# @param options [Hash] App options (theme, border, etc.)
# @param block [Proc] The DSL block defining the TUI
# @return [StreamWeaverCharm::App] The app instance
def tui(title, **options, &block)
  StreamWeaverCharm::App.new(title, **options, &block)
end
