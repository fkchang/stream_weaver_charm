# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestProgress < Minitest::Test
  def test_progress_dsl_renders_the_percentage
    app = tui("Test") { progress :download, value: 45, max: 100 }
    assert_includes app.view, "45"
  end

  def test_progress_clamps_values_over_max
    app = tui("Test") { progress :download, value: 150, max: 100 }
    assert_includes app.view, "100"
  end

  def test_progress_clamps_negative_values
    app = tui("Test") { progress :download, value: -10, max: 100 }
    assert_includes app.view, "0"
  end

  def test_progress_persists_the_same_instance_across_renders
    app = tui("Test") { progress :download, value: 10, max: 100 }
    app.view
    first = app.instance_variable_get(:@progress_bars)[:download]
    app.view
    second = app.instance_variable_get(:@progress_bars)[:download]
    assert_same first, second
  end

  def test_progress_handles_zero_max_without_raising
    app = tui("Test") { progress :download, value: 5, max: 0 }
    assert_includes app.view, "0"
  end
end
