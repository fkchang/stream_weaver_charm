#!/usr/bin/env ruby
# frozen_string_literal: true

# Form Example - Demonstrates text input components
#
# Run with: ruby examples/form.rb

require_relative "../lib/stream_weaver_charm"

tui "Contact Form" do
  header1 "Contact Form"
  text ""

  box title: "Your Details" do
    text_input :name, placeholder: "Your name", label: "Name"
    text_input :email, placeholder: "Email address", label: "Email"
    text_input :company, placeholder: "Company (optional)", label: "Company"
    text ""
    text_area :message, placeholder: "Your message...", label: "Message", rows: 3
  end

  text ""

  # Show current values
  if state[:name] && !state[:name].empty?
    box title: "Preview" do
      text "Hello, #{state[:name]}!"
      text "Email: #{state[:email]}" if state[:email] && !state[:email].empty?
      text "Company: #{state[:company]}" if state[:company] && !state[:company].empty?
      if state[:message] && !state[:message].empty?
        text ""
        text "Message:"
        text state[:message], style: :dim
      end
    end
    text ""
  end

  divider
  help_text "Tab: next field | Shift+Tab: previous | Ctrl+C: quit"
end.run!
