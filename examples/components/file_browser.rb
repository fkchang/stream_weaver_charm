#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# FILE BROWSER - List and Table Components
# =============================================================================
# Purpose: Demonstrates list selection and table display with scrolling
# Audience: Users building file browsers, data viewers, or selection UIs
#
# Run: ruby examples/file_browser.rb
# Controls: j/k or arrows to navigate, Enter to select, Ctrl+C to quit
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

# Sample file data
FILES = [
  { name: "app.rb", size: "4.2kb", modified: "2024-01-15" },
  { name: "Gemfile", size: "312b", modified: "2024-01-10" },
  { name: "README.md", size: "2.1kb", modified: "2024-01-14" },
  { name: "config.yml", size: "856b", modified: "2024-01-12" },
  { name: "lib/", size: "-", modified: "2024-01-15" },
  { name: "spec/", size: "-", modified: "2024-01-13" },
  { name: "Rakefile", size: "1.1kb", modified: "2024-01-08" },
  { name: ".gitignore", size: "245b", modified: "2024-01-01" }
].freeze

tui "File Browser" do
  header1 "File Browser"
  text ""

  # Sort files based on selection
  sort_key = case state[:sort_by]
             when "Size" then :size
             when "Modified" then :modified
             else :name
             end
  sorted_files = FILES.sort_by { |f| f[sort_key] }

  hstack spacing: 4 do
    vstack do
      list :selected_file, sorted_files.map { |f| f[:name] }, label: "Files", height: 5
    end

    vstack do
      if state[:selected_file]
        file = FILES.find { |f| f[:name] == state[:selected_file] }
        if file
          box title: "Details" do
            text "Name: #{file[:name]}"
            text "Size: #{file[:size]}"
            text "Modified: #{file[:modified]}"
          end
        end
      else
        text ""
        text "Select a file", style: :dim
        text "to see details", style: :dim
      end
    end
  end

  text ""
  select :sort_by, ["Name", "Size", "Modified"], label: "Sort by"

  text ""
  divider
  help_text "j/k: navigate | Enter: select | Tab: switch | Ctrl+C: quit"
end.run!
