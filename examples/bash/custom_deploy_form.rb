#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# CUSTOM DEPLOY FORM - Complex Form Template
# =============================================================================
# Purpose: Shows how to create rich custom forms for bash integration
# Audience: Users needing complex forms beyond choice/confirm/input
#
# Run: ruby examples/bash_form.rb form examples/custom_deploy_form.rb
# =============================================================================

require_relative "../../lib/stream_weaver_charm"

tui "Deploy Configuration", theme: :dracula do
  header1 "Deployment Settings"
  text ""

  box title: "Target" do
    select :environment, %w[development staging production], label: "Environment"
    select :region, ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"], label: "Region"
  end

  text ""

  box title: "Options" do
    select :strategy, ["rolling", "blue-green", "canary"], label: "Deploy Strategy"
    text_input :version, placeholder: "latest", label: "Version Tag"
    select :notify, %w[slack email none], label: "Notification"
  end

  text ""
  divider
  help_text "Tab: next | Ctrl+S: deploy | Ctrl+C: cancel"
  submit_on "ctrl+s"
end.run_once!(alt_screen: true)
