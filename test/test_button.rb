# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestButton < Minitest::Test
  def test_button_component_render
    btn = StreamWeaverCharm::Components::Button.new(1, "Save")
    rendered = btn.render

    assert_includes rendered, "Save"
    assert_includes rendered, "["
    assert_includes rendered, "]"
  end

  def test_button_width
    btn = StreamWeaverCharm::Components::Button.new(1, "Click")
    # [Click] = 7 characters
    assert_equal 7, btn.width
  end

  def test_button_dsl
    clicked = false

    app = tui "Test" do
      button "Test" do |_s|
        clicked = true
      end
    end

    output = app.view
    assert_includes output, "Test"
    assert_includes output, "["
  end

  def test_button_callback_registered
    callback_ran = false

    app = tui "Test" do
      button "Click Me" do |_s|
        callback_ran = true
      end
    end

    app.view  # This registers the button

    # Verify button was registered
    buttons = app.instance_variable_get(:@buttons)
    assert_equal 1, buttons.size

    # Simulate click on the button
    btn = buttons.values.first
    btn[:callback].call({})
    assert callback_ran
  end

  def test_mouse_click_handling
    click_count = 0

    app = tui "Test" do
      state[:clicks] ||= 0
      button "Click" do |s|
        s[:clicks] += 1
      end
    end

    app.view  # Register buttons

    # Get button position
    buttons = app.instance_variable_get(:@buttons)
    btn = buttons.values.first

    # Simulate mouse click at button position
    mouse_msg = Bubbletea::MouseMessage.new(
      x: btn[:col],
      y: btn[:row],
      button: Bubbletea::MouseMessage::BUTTON_LEFT,
      action: Bubbletea::MouseMessage::ACTION_PRESS
    )

    app.update(mouse_msg)

    assert_equal 1, app.state[:clicks]
  end
end
