# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestSpinner < Minitest::Test
  def test_spinner_dsl_renders_a_frame
    app = tui("Test") { spinner :loading }
    refute_empty app.view.strip
  end

  def test_spinner_persists_the_same_instance_across_renders
    app = tui("Test") { spinner :loading }
    app.view
    first = app.instance_variable_get(:@spinners)[:loading]
    app.view
    second = app.instance_variable_get(:@spinners)[:loading]
    assert_same first, second
  end

  def test_spinner_advances_frame_on_tick
    app = tui("Test") { spinner :loading }
    app.view
    spin = app.instance_variable_get(:@spinners)[:loading]
    before = spin.view

    tick = Bubbles::Spinner::TickMessage.new(id: spin.id, tag: 0)
    app.update(tick)

    after = app.instance_variable_get(:@spinners)[:loading].view
    refute_equal before, after
  end

  def test_init_returns_a_tick_command_when_a_spinner_is_present
    app = tui("Test") { spinner :loading }
    _model, command = app.init
    refute_nil command
  end

  def test_init_returns_no_command_without_a_spinner
    app = tui("Test") { text "no spinner here" }
    _model, command = app.init
    assert_nil command
  end

  def test_label_is_appended_after_the_spinner_glyph
    app = tui("Test") { spinner :loading, label: "Loading..." }
    assert_includes app.view, "Loading..."
  end
end
