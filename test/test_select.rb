# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestSelect < Minitest::Test
  def setup
    @select = StreamWeaverCharm::Components::Select.new(
      :priority,
      options: ["Low", "Medium", "High"]
    )
    @select.focused = true
  end

  def test_initial_state
    assert_equal 0, @select.cursor
    assert_nil @select.selected
  end

  def test_navigate_wraps
    # Go down past end
    3.times { @select.handle_key(make_down_msg) }
    assert_equal 0, @select.cursor  # Wraps to start

    # Go up past start
    @select.handle_key(make_up_msg)
    assert_equal 2, @select.cursor  # Wraps to end
  end

  def test_select_on_enter
    @select.handle_key(make_down_msg)
    @select.handle_key(make_enter_msg)

    assert_equal "Medium", @select.selected
    assert_equal 1, @select.selected_index
  end

  def test_select_on_space
    @select.handle_key(make_down_msg)
    @select.handle_key(make_down_msg)
    @select.handle_key(make_space_msg)

    assert_equal "High", @select.selected
  end

  def test_render_shows_radio_buttons
    @select.handle_key(make_enter_msg)  # Select "Low"

    rendered = @select.render
    assert_includes rendered, "●"  # Selected indicator
    assert_includes rendered, "Low"
    assert_includes rendered, "Medium"
    assert_includes rendered, "High"
  end

  def test_unfocused_ignores_input
    @select.focused = false
    result = @select.handle_key(make_down_msg)

    assert_equal false, result
    assert_equal 0, @select.cursor
  end

  def test_initial_selection
    select = StreamWeaverCharm::Components::Select.new(
      :level,
      options: ["A", "B", "C"],
      selected: "B"
    )

    assert_equal "B", select.selected
    assert_equal 1, select.selected_index
  end

  private

  def make_down_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN)
  end

  def make_up_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP)
  end

  def make_enter_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_ENTER)
  end

  def make_space_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_SPACE)
  end
end
