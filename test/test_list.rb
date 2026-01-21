# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestList < Minitest::Test
  def setup
    @list = StreamWeaverCharm::Components::List.new(:files, height: 3)
    @list.items = ["app.rb", "Gemfile", "README.md", "config.yml", "lib/"]
    @list.focused = true
  end

  def test_initial_state
    assert_equal 0, @list.cursor
    assert_nil @list.selected
  end

  def test_navigate_down
    @list.handle_key(make_down_msg)
    assert_equal 1, @list.cursor

    @list.handle_key(make_key_msg("j"))
    assert_equal 2, @list.cursor
  end

  def test_navigate_up
    @list.handle_key(make_down_msg)
    @list.handle_key(make_down_msg)
    @list.handle_key(make_up_msg)
    assert_equal 1, @list.cursor

    @list.handle_key(make_key_msg("k"))
    assert_equal 0, @list.cursor
  end

  def test_cursor_bounds
    # Can't go above 0
    @list.handle_key(make_up_msg)
    assert_equal 0, @list.cursor

    # Can't go below last item
    5.times { @list.handle_key(make_down_msg) }
    assert_equal 4, @list.cursor
  end

  def test_select_on_enter
    @list.handle_key(make_down_msg)
    @list.handle_key(make_enter_msg)

    assert_equal "Gemfile", @list.selected
  end

  def test_scroll_viewport
    # With height 3, scrolling starts when cursor > 2
    3.times { @list.handle_key(make_down_msg) }

    rendered = @list.render
    # Should show scroll indicator
    assert_includes rendered, "↓"
  end

  def test_unfocused_ignores_input
    @list.focused = false
    result = @list.handle_key(make_down_msg)

    assert_equal false, result
    assert_equal 0, @list.cursor
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

  def make_key_msg(char)
    Bubbletea::KeyMessage.new(
      key_type: Bubbletea::KeyMessage::KEY_RUNES,
      runes: char.codepoints
    )
  end
end
