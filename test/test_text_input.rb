# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestTextInput < Minitest::Test
  def setup
    @input = StreamWeaverCharm::Components::TextInput.new(:name, placeholder: "Enter name")
    @input.focused = true
  end

  def test_initial_state
    assert_equal "", @input.value
    assert_equal 0, @input.cursor
  end

  def test_insert_characters
    # Simulate typing "hi"
    @input.handle_key(make_key_msg("h"))
    @input.handle_key(make_key_msg("i"))

    assert_equal "hi", @input.value
    assert_equal 2, @input.cursor
  end

  def test_backspace
    @input.value = "hello"
    @input.handle_key(make_backspace_msg)

    assert_equal "hell", @input.value
    assert_equal 4, @input.cursor
  end

  def test_cursor_movement
    @input.value = "hello"

    # Move left
    @input.handle_key(make_left_msg)
    assert_equal 4, @input.cursor

    # Move right
    @input.handle_key(make_right_msg)
    assert_equal 5, @input.cursor
  end

  def test_unfocused_ignores_input
    @input.focused = false
    result = @input.handle_key(make_key_msg("x"))

    assert_equal false, result
    assert_equal "", @input.value
  end

  def test_placeholder_shown_when_empty
    @input.focused = false
    rendered = @input.render

    assert_includes rendered, "Enter name"
  end

  private

  def make_key_msg(char)
    Bubbletea::KeyMessage.new(
      key_type: Bubbletea::KeyMessage::KEY_RUNES,
      runes: char.codepoints
    )
  end

  def make_backspace_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_BACKSPACE)
  end

  def make_left_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_LEFT)
  end

  def make_right_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RIGHT)
  end
end
