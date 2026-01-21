# frozen_string_literal: true

module StreamWeaverCharm
  # ANSI escape codes for terminal styling
  # Supports theming with named colors, hex colors, and 256-color codes
  module Styles
    module_function

    # ANSI codes
    RESET = "\e[0m"
    BOLD = "\e[1m"
    DIM = "\e[2m"
    ITALIC = "\e[3m"
    REVERSE = "\e[7m"

    # Named color to 256-color mapping
    NAMED_COLORS = {
      red: 203,
      yellow: 221,
      blue: 111,
      purple: 141,
      gray: 245,
      green: 84,
      orange: 214,
      cyan: 81,
      pink: 205,
      white: 255
    }.freeze

    # Current theme (thread-local for safety)
    def current_theme
      Thread.current[:stream_weaver_theme] ||= Themes::Default.new
    end

    def current_theme=(theme)
      Thread.current[:stream_weaver_theme] = Themes::Registry.get(theme)
    end

    # Foreground color - accepts :name, "#hex", or 256-code
    def fg(color)
      code = color_to_code(color)
      code ? "\e[38;5;#{code}m" : ""
    end

    # Background color
    def bg(color)
      code = color_to_code(color)
      code ? "\e[48;5;#{code}m" : ""
    end

    # Convert color to 256-color code
    def color_to_code(color)
      case color
      when Symbol
        NAMED_COLORS[color]
      when String
        color.start_with?("#") ? Themes::Base.hex_to_256(color) : nil
      when Integer
        color
      else
        nil
      end
    end

    # Apply style hash to text
    # @param text [String] Text to style
    # @param style [Hash] Style options: fg, bg, bold, dim, italic, reverse
    def apply_style(text, style)
      return text.to_s if style.nil? || style.empty?

      codes = []
      codes << fg(style[:fg]) if style[:fg]
      codes << bg(style[:bg]) if style[:bg]
      codes << BOLD if style[:bold]
      codes << DIM if style[:dim]
      codes << ITALIC if style[:italic]
      codes << REVERSE if style[:reverse]

      if codes.empty?
        text.to_s
      else
        "#{codes.join}#{text}#{RESET}"
      end
    end

    # Apply style and render (backward compatible)
    def render(text, *styles)
      prefix = styles.join
      "#{prefix}#{text}#{RESET}"
    end

    # Theme-aware style helpers
    def title(text)
      apply_style(text, current_theme[:title])
    end

    def header1(text)
      apply_style(text, current_theme[:header1])
    end

    def header2(text)
      apply_style(text, current_theme[:header2])
    end

    def header3(text)
      apply_style(text, current_theme[:header3])
    end

    def dim(text)
      apply_style(text, current_theme[:dim])
    end

    def help(text)
      apply_style(text, current_theme[:help])
    end

    def success(text)
      apply_style(text, current_theme[:success])
    end

    def warning(text)
      apply_style(text, current_theme[:warning])
    end

    def error(text)
      apply_style(text, current_theme[:error])
    end

    # Strip ANSI escape codes to get visible length
    def visible_length(str)
      str.to_s.gsub(/\e\[[0-9;]*m/, "").length
    end

    # Pad string to width, accounting for ANSI codes
    def visible_ljust(str, width)
      visible_len = visible_length(str)
      padding_needed = [width - visible_len, 0].max
      str.to_s + (" " * padding_needed)
    end

    # Simple box drawing
    def box(content, title: nil)
      border_style = current_theme[:box_border]
      border_fg = border_style[:fg] ? fg(border_style[:fg]) : fg(:blue)

      lines = content.to_s.split("\n")
      width = lines.map { |l| visible_length(l) }.max || 0
      width = [width, (title&.length || 0) + 4].max
      width += 4

      result = []
      if title
        dashes_needed = width - title.length - 1
        result << "#{border_fg}╭─#{RESET} #{title} #{border_fg}#{'─' * dashes_needed}╮#{RESET}"
      else
        result << "#{border_fg}╭#{'─' * (width + 2)}╮#{RESET}"
      end

      lines.each do |line|
        padded = visible_ljust(line, width)
        result << "#{border_fg}│#{RESET} #{padded} #{border_fg}│#{RESET}"
      end

      result << "#{border_fg}╰#{'─' * (width + 2)}╯#{RESET}"
      result.join("\n")
    end

    # Alert box with variant
    def alert(content, variant: :info)
      alert_key = :"alert_#{variant}"
      style = current_theme[alert_key] || current_theme[:alert_info]
      color_fg = style[:fg] ? fg(style[:fg]) : fg(:blue)

      lines = content.to_s.split("\n")
      width = lines.map { |l| visible_length(l) }.max || 0
      width += 4

      result = []
      result << "#{color_fg}┌#{'─' * (width + 2)}┐#{RESET}"
      lines.each do |line|
        result << "#{color_fg}│#{RESET} #{visible_ljust(line, width)} #{color_fg}│#{RESET}"
      end
      result << "#{color_fg}└#{'─' * (width + 2)}┘#{RESET}"
      result.join("\n")
    end

    # Divider line
    def divider(width = 40)
      dim("-" * width)
    end
  end
end
