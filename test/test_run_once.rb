# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestRunOnce < Minitest::Test
  def test_submit_on_registers_keys
    app = tui "Test" do
      submit_on "ctrl+s", "ctrl+enter"
    end

    # Trigger view to execute the block
    app.view

    # Access internal state via instance_variable_get
    submit_keys = app.instance_variable_get(:@submit_keys)
    assert_includes submit_keys, "ctrl+s"
    assert_includes submit_keys, "ctrl+enter"
  end

  def test_run_once_mode_flag
    app = tui "Test" do
      text "Hello"
    end

    # Before run_once!, flag should be false
    assert_equal false, app.instance_variable_get(:@run_once_mode)
  end

  def test_submit_key_sets_submitted_flag
    app = tui "Test" do
      submit_on "ctrl+s"
    end

    # Set run_once mode manually (since we can't actually run the TUI)
    app.instance_variable_set(:@run_once_mode, true)
    app.view  # Execute block to register submit keys

    # Simulate pressing ctrl+s
    msg = Bubbletea::KeyMessage.new(
      key_type: Bubbletea::KeyMessage::KEY_CTRL_S
    )
    result = app.update(msg)

    # Should have set submitted flag and returned quit command
    assert_equal true, app.instance_variable_get(:@submitted)
    assert_instance_of Bubbletea::QuitCommand, result[1]
  end

  def test_submit_key_ignored_when_not_run_once_mode
    app = tui "Test" do
      submit_on "ctrl+s"
    end

    # Don't set run_once mode
    app.view

    # Simulate pressing ctrl+s
    msg = Bubbletea::KeyMessage.new(
      key_type: Bubbletea::KeyMessage::KEY_CTRL_S
    )
    result = app.update(msg)

    # Should NOT have set submitted flag
    assert_equal false, app.instance_variable_get(:@submitted)
    assert_nil result[1]  # No quit command
  end

  def test_state_captured_on_submit
    app = tui "Test" do
      state[:name] = "Alice"
      state[:email] = "alice@example.com"
      submit_on "ctrl+s"
    end

    app.instance_variable_set(:@run_once_mode, true)
    app.view  # Populate state

    # Verify state is populated
    assert_equal "Alice", app.state[:name]
    assert_equal "alice@example.com", app.state[:email]
  end
end
