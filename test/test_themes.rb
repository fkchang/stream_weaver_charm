# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/stream_weaver_charm"

class TestThemes < Minitest::Test
  def teardown
    # Reset to default theme after each test
    StreamWeaverCharm::Styles.current_theme = :default
  end

  def test_registry_available_themes
    themes = StreamWeaverCharm::Themes::Registry.available
    assert_includes themes, :default
    assert_includes themes, :dracula
    assert_includes themes, :nord
    assert_includes themes, :monokai
  end

  def test_registry_get_by_symbol
    theme = StreamWeaverCharm::Themes::Registry.get(:dracula)
    assert_equal :dracula, theme.name
  end

  def test_registry_get_custom_hash
    theme = StreamWeaverCharm::Themes::Registry.get(title: { fg: :red })
    assert_equal :custom, theme.name
    assert_equal :red, theme[:title][:fg]
  end

  def test_registry_unknown_theme_raises
    assert_raises(ArgumentError) do
      StreamWeaverCharm::Themes::Registry.get(:nonexistent)
    end
  end

  def test_hex_to_256_conversion
    # Pure red should map to color cube
    code = StreamWeaverCharm::Themes::Base.hex_to_256("#FF0000")
    assert_kind_of Integer, code

    # Gray should map to grayscale
    gray_code = StreamWeaverCharm::Themes::Base.hex_to_256("#808080")
    assert gray_code >= 232  # Grayscale range
  end

  def test_styles_current_theme_default
    theme = StreamWeaverCharm::Styles.current_theme
    assert_equal :default, theme.name
  end

  def test_styles_set_theme
    StreamWeaverCharm::Styles.current_theme = :nord
    assert_equal :nord, StreamWeaverCharm::Styles.current_theme.name
  end

  def test_app_theme_option
    app = tui "Test", theme: :dracula do
      text "Hello"
    end

    # Theme should be set
    assert_equal :dracula, StreamWeaverCharm::Styles.current_theme.name
  end

  def test_custom_style_dsl
    app = tui "Test" do
      style :highlight, fg: :cyan, bold: true
    end

    app.view  # Execute block

    custom = app.get_style(:highlight)
    assert_equal :cyan, custom[:fg]
    assert_equal true, custom[:bold]
  end

  def test_text_with_custom_style
    app = tui "Test" do
      style :custom, fg: :green, bold: true
      text "Hello", style: :custom
    end

    output = app.view
    # Should contain ANSI codes for green and bold
    assert_includes output, "\e[38;5;84m"  # Green
    assert_includes output, "\e[1m"        # Bold
  end

  def test_text_with_hash_style
    app = tui "Test" do
      text "Hello", style: { fg: :red, italic: true }
    end

    output = app.view
    assert_includes output, "\e[38;5;203m"  # Red
    assert_includes output, "\e[3m"         # Italic
  end
end
