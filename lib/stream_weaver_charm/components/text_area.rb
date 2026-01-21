# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Multi-line text area component
    #
    # Handles keyboard input for multi-line text editing.
    class TextArea
      attr_reader :key, :lines, :cursor_row, :cursor_col
      attr_accessor :focused

      def initialize(key, placeholder: "", focused: false, rows: 4, width: 40)
        @key = key
        @lines = [""]
        @cursor_row = 0
        @cursor_col = 0
        @placeholder = placeholder
        @focused = focused
        @rows = rows
        @width = width
      end

      def value
        @lines.join("\n")
      end

      def value=(new_value)
        @lines = new_value.to_s.split("\n", -1)
        @lines = [""] if @lines.empty?
        @cursor_row = @lines.length - 1
        @cursor_col = @lines[@cursor_row].length
      end

      # Handle a KeyMessage, returns true if the message was consumed
      def handle_key(msg)
        return false unless @focused

        if msg.runes? && msg.char
          insert_char(msg.char)
          true
        elsif msg.space?
          insert_char(" ")
          true
        elsif msg.enter?
          insert_newline
          true
        elsif msg.backspace?
          delete_backward
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_DELETE
          delete_forward
          true
        elsif msg.left?
          move_cursor_left
          true
        elsif msg.right?
          move_cursor_right
          true
        elsif msg.up?
          move_cursor_up
          true
        elsif msg.down?
          move_cursor_down
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_HOME
          @cursor_col = 0
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_END
          @cursor_col = current_line.length
          true
        else
          false
        end
      end

      def render
        if @lines == [""] && !@placeholder.empty? && !@focused
          Styles.dim(@placeholder)
        else
          render_lines
        end
      end

      private

      def current_line
        @lines[@cursor_row] || ""
      end

      def insert_char(char)
        line = current_line
        @lines[@cursor_row] = line[0...@cursor_col].to_s + char + line[@cursor_col..].to_s
        @cursor_col += char.length
      end

      def insert_newline
        line = current_line
        before = line[0...@cursor_col].to_s
        after = line[@cursor_col..].to_s

        @lines[@cursor_row] = before
        @lines.insert(@cursor_row + 1, after)
        @cursor_row += 1
        @cursor_col = 0
      end

      def delete_backward
        if @cursor_col.positive?
          line = current_line
          @lines[@cursor_row] = line[0...(@cursor_col - 1)].to_s + line[@cursor_col..].to_s
          @cursor_col -= 1
        elsif @cursor_row.positive?
          # Join with previous line
          prev_line = @lines[@cursor_row - 1]
          @cursor_col = prev_line.length
          @lines[@cursor_row - 1] = prev_line + current_line
          @lines.delete_at(@cursor_row)
          @cursor_row -= 1
        end
      end

      def delete_forward
        line = current_line
        if @cursor_col < line.length
          @lines[@cursor_row] = line[0...@cursor_col].to_s + line[(@cursor_col + 1)..].to_s
        elsif @cursor_row < @lines.length - 1
          # Join with next line
          @lines[@cursor_row] = line + @lines[@cursor_row + 1]
          @lines.delete_at(@cursor_row + 1)
        end
      end

      def move_cursor_left
        if @cursor_col.positive?
          @cursor_col -= 1
        elsif @cursor_row.positive?
          @cursor_row -= 1
          @cursor_col = current_line.length
        end
      end

      def move_cursor_right
        if @cursor_col < current_line.length
          @cursor_col += 1
        elsif @cursor_row < @lines.length - 1
          @cursor_row += 1
          @cursor_col = 0
        end
      end

      def move_cursor_up
        return unless @cursor_row.positive?

        @cursor_row -= 1
        @cursor_col = [@cursor_col, current_line.length].min
      end

      def move_cursor_down
        return unless @cursor_row < @lines.length - 1

        @cursor_row += 1
        @cursor_col = [@cursor_col, current_line.length].min
      end

      def render_lines
        rendered = @lines.each_with_index.map do |line, row|
          if @focused && row == @cursor_row
            render_line_with_cursor(line)
          else
            line.empty? ? " " : line
          end
        end

        # Pad to minimum rows
        while rendered.length < @rows
          rendered << " "
        end

        rendered.join("\n")
      end

      def render_line_with_cursor(line)
        if line.empty?
          cursor_char
        elsif @cursor_col >= line.length
          "#{line}#{cursor_char}"
        else
          before = line[0...@cursor_col]
          at_cursor = line[@cursor_col]
          after = line[(@cursor_col + 1)..]
          "#{before}#{highlight_char(at_cursor)}#{after}"
        end
      end

      def cursor_char
        "\e[7m \e[0m"
      end

      def highlight_char(char)
        "\e[7m#{char}\e[0m"
      end
    end
  end
end
