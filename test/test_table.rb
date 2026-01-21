# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestTable < Minitest::Test
  def test_headers_and_rows
    table = StreamWeaverCharm::Components::Table.new(
      headers: ["Name", "Size"],
      rows: [["app.rb", "4kb"], ["Gemfile", "1kb"]]
    )

    rendered = table.render
    assert_includes rendered, "Name"
    assert_includes rendered, "Size"
    assert_includes rendered, "app.rb"
    assert_includes rendered, "4kb"
  end

  def test_array_of_hashes
    data = [
      { name: "Alice", role: "Admin" },
      { name: "Bob", role: "User" }
    ]
    table = StreamWeaverCharm::Components::Table.new(data)

    rendered = table.render
    assert_includes rendered, "name"
    assert_includes rendered, "role"
    assert_includes rendered, "Alice"
    assert_includes rendered, "Admin"
  end

  def test_bordered_rendering
    table = StreamWeaverCharm::Components::Table.new(
      headers: ["A"],
      rows: [["1"]],
      border: true
    )

    rendered = table.render
    assert_includes rendered, "┌"
    assert_includes rendered, "┐"
    assert_includes rendered, "└"
    assert_includes rendered, "┘"
    assert_includes rendered, "│"
  end

  def test_borderless_rendering
    table = StreamWeaverCharm::Components::Table.new(
      headers: ["Name"],
      rows: [["Test"]],
      border: false
    )

    rendered = table.render
    refute_includes rendered, "┌"
    refute_includes rendered, "│"
    assert_includes rendered, "Name"
    assert_includes rendered, "Test"
  end

  def test_column_width_calculation
    table = StreamWeaverCharm::Components::Table.new(
      headers: ["Short", "Much Longer Header"],
      rows: [["a", "b"]]
    )

    rendered = table.render
    # Headers should be padded to align
    assert_includes rendered, "Much Longer Header"
  end

  def test_empty_table
    table = StreamWeaverCharm::Components::Table.new(headers: [], rows: [])
    assert_equal "", table.render
  end
end
