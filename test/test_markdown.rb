# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestMarkdown < Minitest::Test
  def test_renders_plain_markdown
    md = StreamWeaverCharm::Components::Markdown.new("# Hello")
    assert_includes md.render, "Hello"
  end

  def test_dracula_theme_maps_to_dracula_glamour_style
    StreamWeaverCharm::Styles.current_theme = :dracula
    md = StreamWeaverCharm::Components::Markdown.new("# Hi")
    assert_equal "dracula", md.send(:resolved_style)
  ensure
    StreamWeaverCharm::Styles.current_theme = :default
  end

  def test_light_theme_maps_to_light_glamour_style
    StreamWeaverCharm::Styles.current_theme = :light
    md = StreamWeaverCharm::Components::Markdown.new("# Hi")
    assert_equal "light", md.send(:resolved_style)
  ensure
    StreamWeaverCharm::Styles.current_theme = :default
  end

  def test_theme_without_glamour_preset_falls_back_to_auto
    StreamWeaverCharm::Styles.current_theme = :nord
    md = StreamWeaverCharm::Components::Markdown.new("# Hi")
    assert_equal "auto", md.send(:resolved_style)
  ensure
    StreamWeaverCharm::Styles.current_theme = :default
  end

  def test_explicit_style_overrides_theme_mapping
    StreamWeaverCharm::Styles.current_theme = :nord
    md = StreamWeaverCharm::Components::Markdown.new("# Hi", style: "light")
    assert_equal "light", md.send(:resolved_style)
  ensure
    StreamWeaverCharm::Styles.current_theme = :default
  end

  def test_markdown_dsl_method
    app = tui("Test") { markdown "# Hello DSL" }
    assert_includes app.view, "Hello DSL"
  end
end
