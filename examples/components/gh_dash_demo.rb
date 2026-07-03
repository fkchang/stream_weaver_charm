#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# GH-DASH STYLE DASHBOARD - Stubbed prototype, no real GitHub calls
# =============================================================================
# Purpose: Recreates the look/feel of gh-dash (a real Bubble Tea app - also
#          built on bubbletea/lipgloss/glamour) using this DSL's full feature
#          set: tabs, table, box, markdown, spinner, progress, theming.
# Audience: Anyone wanting to see most of the DSL's components working
#           together in one screen, styled like a real showcased Charm app.
# Run: ruby examples/components/gh_dash_demo.rb
# Controls: [ ] switch section  j/k select row  q quit
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

SECTIONS = [
  {
    name: "My PRs",
    headers: ["#", "Title", "CI", "Review", "Updated"],
    rows: [
      { number: 482, title: "Add dark mode toggle to settings panel", author: "forrestc",
        ci: "pass", review: "approved", updated: "2h ago",
        body: "Adds a `theme` toggle to the settings panel.\n\n- Persists choice to `~/.config/app/theme`\n- Falls back to **system preference** on first run" },
      { number: 479, title: "Fix memory leak in worker pool", author: "forrestc",
        ci: "fail", review: "changes requested", updated: "5h ago",
        body: "Workers weren't releasing job contexts after completion.\n\n```ruby\npool.release(job)\n```\n\nStill need a regression test." },
      { number: 465, title: "Refactor auth middleware for token rotation", author: "forrestc",
        ci: "pass", review: "pending", updated: "1d ago",
        body: "Splits token refresh into its own middleware.\n\n**Breaking change:** old `RefreshToken` class is removed." }
    ]
  },
  {
    name: "Assigned",
    headers: ["#", "Title", "CI", "Review", "Updated"],
    rows: [
      { number: 501, title: "Investigate flaky spec in billing_engine", author: "kdiaz",
        ci: "pass", review: "pending", updated: "30m ago",
        body: "`spec/models/invoice_spec.rb:142` fails ~1 in 20 runs.\n\nLikely a timing issue around `Timecop.freeze`." },
      { number: 498, title: "Update Ruby to 3.4 across services", author: "jwu",
        ci: "running", review: "pending", updated: "3h ago",
        body: "Bumping the base image and re-running the full suite per service.\n\n- [ ] billing_engine\n- [ ] hedgeye-admin\n- [ ] hedgeye-reader" }
    ]
  },
  {
    name: "Team Issues",
    headers: ["#", "Title", "Labels", "Updated"],
    rows: [
      { number: 77, title: "Improve onboarding docs for new hires", author: "mreyes",
        labels: "docs, good-first-issue", updated: "1d ago",
        body: "New hires keep asking the same three questions in Slack.\n\nDraft a **Getting Started** doc covering local setup and test conventions." },
      { number: 64, title: "Slow query on dashboard load", author: "kdiaz",
        labels: "bug, performance", updated: "4h ago",
        body: "Dashboard query takes ~4s under load.\n\n`EXPLAIN ANALYZE` shows a missing index on `orders.customer_id`." },
      { number: 52, title: "Support SSO login via Okta", author: "twright",
        labels: "feature, security", updated: "6d ago",
        body: "Customers keep asking for SSO.\n\nOkta SAML integration is the most requested option." }
    ]
  }
].freeze

tui "gh-dash (stubbed demo)", theme: :dracula do
  state[:tab] ||= 0
  state[:selected] ||= 0

  section = SECTIONS[state[:tab]]
  row = section[:rows][state[:selected]]

  header1 "gh-dash"

  tabs = SECTIONS.each_with_index.map do |s, i|
    i == state[:tab] ? "[#{s[:name]}]" : " #{s[:name]} "
  end.join("  ")
  text tabs
  divider

  table_rows = section[:rows].each_with_index.map do |r, i|
    marker = i == state[:selected] ? ">" : " "
    if section.key?(:labels) || r.key?(:labels)
      [marker, r[:number].to_s, r[:title], r[:labels], r[:updated]]
    else
      [marker, r[:number].to_s, r[:title], r[:ci], r[:review], r[:updated]]
    end
  end
  table headers: ["", *section[:headers]], rows: table_rows

  text ""
  box title: "Details ##{row[:number]}" do
    text row[:title]
    text "by @#{row[:author]}", style: :dim
    text ""
    markdown row[:body]
  end

  text ""
  hstack(spacing: 4) do
    spinner :sync, label: "Syncing with GitHub..."
    progress :sync_progress, value: 42, max: 100, width: 20
  end

  text ""
  help_text "[/] switch section  j/k select  q quit"

  on_key "[" do |s|
    s[:tab] = (s[:tab] - 1) % SECTIONS.size
    s[:selected] = 0
  end

  on_key "]" do |s|
    s[:tab] = (s[:tab] + 1) % SECTIONS.size
    s[:selected] = 0
  end

  on_key "j" do |s|
    max = SECTIONS[s[:tab]][:rows].size - 1
    s[:selected] = [s[:selected] + 1, max].min
  end

  on_key "k" do |s|
    s[:selected] = [s[:selected] - 1, 0].max
  end
end.run!
