# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestFocusManager < Minitest::Test
  def setup
    @fm = StreamWeaverCharm::FocusManager.new
  end

  def test_first_registered_input_gets_focus
    @fm.register(:name)
    @fm.register(:email)

    assert_equal :name, @fm.focused_key
  end

  def test_focus_next_cycles
    @fm.register(:name)
    @fm.register(:email)
    @fm.register(:phone)

    assert_equal :name, @fm.focused_key

    @fm.focus_next
    assert_equal :email, @fm.focused_key

    @fm.focus_next
    assert_equal :phone, @fm.focused_key

    @fm.focus_next
    assert_equal :name, @fm.focused_key # Wraps around
  end

  def test_focus_previous_cycles
    @fm.register(:name)
    @fm.register(:email)
    @fm.register(:phone)

    @fm.focus_previous
    assert_equal :phone, @fm.focused_key # Wraps to end

    @fm.focus_previous
    assert_equal :email, @fm.focused_key
  end

  def test_explicit_focus
    @fm.register(:name)
    @fm.register(:email)

    @fm.focus(:email)
    assert_equal :email, @fm.focused_key
  end

  def test_focused_predicate
    @fm.register(:name)
    @fm.register(:email)

    assert @fm.focused?(:name)
    refute @fm.focused?(:email)
  end

  def test_clear_preserves_focused_key
    @fm.register(:name)
    @fm.register(:email)
    @fm.focus(:email)

    @fm.clear
    @fm.register(:name)
    @fm.register(:email)
    @fm.validate_focus

    assert_equal :email, @fm.focused_key
  end
end
