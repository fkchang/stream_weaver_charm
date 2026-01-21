# frozen_string_literal: true

module StreamWeaverCharm
  # ANSI escape codes for terminal styling
  # Using raw ANSI instead of Lipgloss due to Go runtime issues with multiple style creations
  module Styles
    module_function

    # ANSI codes
    RESET = "\e[0m"
    BOLD = "\e[1m"
    DIM = "\e[2m"
    ITALIC = "\e[3m"

    # Colors (256-color mode)
    def fg(color)
      case color
      when :red then "\e[38;5;203m"
      when :yellow then "\e[38;5;221m"
      when :blue then "\e[38;5;111m"
      when :purple then "\e[38;5;141m"
      when :gray then "\e[38;5;245m"
      when :green then "\e[38;5;84m"
      when :orange then "\e[38;5;214m"
      else ""
      end
    end

    # Apply style and render
    def render(text, *styles)
      prefix = styles.join
      "#{prefix}#{text}#{RESET}"
    end

    # Pre-defined style helpers
    def title(text)
      render(text, BOLD, fg(:red))
    end

    def header1(text)
      render(text, BOLD, fg(:yellow))
    end

    def header2(text)
      render(text, BOLD, fg(:blue))
    end

    def header3(text)
      render(text, BOLD, fg(:purple))
    end

    def dim(text)
      render(text, DIM, fg(:gray))
    end

    def help(text)
      render(text, ITALIC, fg(:gray))
    end

    def success(text)
      render(text, fg(:green))
    end

    def warning(text)
      render(text, fg(:orange))
    end

    def error(text)
      render(text, fg(:red))
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
      lines = content.to_s.split("\n")
      width = lines.map { |l| visible_length(l) }.max || 0
      width = [width, (title&.length || 0) + 4].max
      width += 4  # padding

      result = []
      # Top border
      if title
        # ╭─ title ───╮ needs to equal width + 4 total (matching content lines)
        # ╭─ = 2, space = 1, title, space = 1, ╮ = 1 => dashes = width + 4 - 5 - title.length
        dashes_needed = width - title.length - 1
        result << "#{fg(:blue)}╭─#{RESET} #{title} #{fg(:blue)}#{'─' * dashes_needed}╮#{RESET}"
      else
        result << "#{fg(:blue)}╭#{'─' * (width + 2)}╮#{RESET}"
      end

      # Content
      lines.each do |line|
        padded = visible_ljust(line, width)
        result << "#{fg(:blue)}│#{RESET} #{padded} #{fg(:blue)}│#{RESET}"
      end

      # Bottom border
      result << "#{fg(:blue)}╰#{'─' * (width + 2)}╯#{RESET}"

      result.join("\n")
    end

    # Alert box with variant
    def alert(content, variant: :info)
      color = case variant
      when :success then :green
      when :warning then :orange
      when :error then :red
      else :blue
      end

      lines = content.to_s.split("\n")
      width = lines.map { |l| visible_length(l) }.max || 0
      width += 4

      result = []
      result << "#{fg(color)}┌#{'─' * (width + 2)}┐#{RESET}"
      lines.each do |line|
        result << "#{fg(color)}│#{RESET} #{visible_ljust(line, width)} #{fg(color)}│#{RESET}"
      end
      result << "#{fg(color)}└#{'─' * (width + 2)}┘#{RESET}"

      result.join("\n")
    end

    # Divider line
    def divider(width = 40)
      dim("-" * width)
    end
  end
end
