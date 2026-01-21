# frozen_string_literal: true

module StreamWeaverCharm
  module Themes
    # Base theme class defining the theme structure
    #
    # Themes define colors for various UI elements using either:
    # - Named ANSI colors: :red, :green, :blue, :yellow, :purple, :gray, :orange
    # - Hex colors: "#FF6B6B" (converted to nearest 256-color)
    # - 256-color codes: 203, 111, etc.
    class Base
      # Element colors with optional modifiers
      # Each element can have: fg, bg, bold, dim, italic
      ELEMENTS = %i[
        title
        header1
        header2
        header3
        text
        dim
        help
        success
        warning
        error
        box_border
        alert_info
        alert_success
        alert_warning
        alert_error
        focus
        cursor
        selected
        placeholder
      ].freeze

      attr_reader :name, :colors

      def initialize(name, colors = {})
        @name = name
        @colors = default_colors.merge(colors)
      end

      # Get style for an element
      def [](element)
        @colors[element] || {}
      end

      # Convert hex color to 256-color code
      def self.hex_to_256(hex)
        hex = hex.delete("#")
        r = hex[0..1].to_i(16)
        g = hex[2..3].to_i(16)
        b = hex[4..5].to_i(16)

        # Convert to 6x6x6 color cube (codes 16-231)
        # or grayscale (codes 232-255)
        if r == g && g == b
          # Grayscale
          gray = ((r - 8) / 10.0).round
          gray = [[gray, 0].max, 23].min
          232 + gray
        else
          # Color cube
          r_idx = (r / 51.0).round
          g_idx = (g / 51.0).round
          b_idx = (b / 51.0).round
          16 + (36 * r_idx) + (6 * g_idx) + b_idx
        end
      end

      private

      def default_colors
        {
          title: { fg: :red, bold: true },
          header1: { fg: :yellow, bold: true },
          header2: { fg: :blue, bold: true },
          header3: { fg: :purple, bold: true },
          text: {},
          dim: { fg: :gray, dim: true },
          help: { fg: :gray, italic: true },
          success: { fg: :green },
          warning: { fg: :orange },
          error: { fg: :red },
          box_border: { fg: :blue },
          alert_info: { fg: :blue },
          alert_success: { fg: :green },
          alert_warning: { fg: :orange },
          alert_error: { fg: :red },
          focus: { fg: :green },
          cursor: { reverse: true },
          selected: { bold: true },
          placeholder: { fg: :gray, dim: true }
        }
      end
    end
  end
end
