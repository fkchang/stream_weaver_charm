# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestTextArea < Minitest::Test
  def setup
    @area = StreamWeaverCharm::Components::TextArea.new(:bio, placeholder: "Tell us about yourself")
    @area.focused = true
  end

  def test_initial_state
    assert_equal "", @area.value
    assert_equal 0, @area.cursor_row
    assert_equal 0, @area.cursor_col
  end

  def test_insert_characters
    @area.handle_key(make_key_msg("h"))
    @area.handle_key(make_key_msg("i"))

    assert_equal "hi", @area.value
    assert_equal 2, @area.cursor_col
  end

  def test_newline
    @area.handle_key(make_key_msg("a"))
    @area.handle_key(make_enter_msg)
    @area.handle_key(make_key_msg("b"))

    assert_equal "a\nb", @area.value
    assert_equal 1, @area.cursor_row
    assert_equal 1, @area.cursor_col
  end

  def test_vertical_navigation
    @area.value = "line1\nline2\nline3"
    @area.handle_key(make_up_msg)
    assert_equal 1, @area.cursor_row

    @area.handle_key(make_up_msg)
    assert_equal 0, @area.cursor_row

    @area.handle_key(make_down_msg)
    assert_equal 1, @area.cursor_row
  end

  def test_backspace_joins_lines
    @area.value = "abc\ndef"
    # Cursor at end of "def" (line 1, col 3)
    # Move to beginning of line 2
    @area.handle_key(make_home_msg)
    # Now backspace should join lines
    @area.handle_key(make_backspace_msg)

    assert_equal "abcdef", @area.value
    assert_equal 0, @area.cursor_row
  end

  private

  def make_key_msg(char)
    Bubbletea::KeyMessage.new(
      key_type: Bubbletea::KeyMessage::KEY_RUNES,
      runes: char.codepoints
    )
  end

  def make_enter_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_ENTER)
  end

  def make_backspace_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_BACKSPACE)
  end

  def make_up_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP)
  end

  def make_down_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN)
  end

  def make_home_msg
    Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_HOME)
  end
end
