# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Single-line text input component
    #
    # Handles keyboard input directly rather than wrapping Bubbles
    # (which isn't available as a separate Ruby gem).
    class TextInput
      attr_reader :key, :value, :cursor
      attr_accessor :focused

      def initialize(key, placeholder: "", focused: false, width: 30)
        @key = key
        @value = ""
        @cursor = 0
        @placeholder = placeholder
        @focused = focused
        @width = width
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
        elsif msg.backspace?
          delete_backward
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_DELETE
          delete_forward
          true
        elsif msg.left?
          move_cursor(-1)
          true
        elsif msg.right?
          move_cursor(1)
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_HOME ||
              msg.key_type == Bubbletea::KeyMessage::KEY_CTRL_A
          @cursor = 0
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_END ||
              msg.key_type == Bubbletea::KeyMessage::KEY_CTRL_E
          @cursor = @value.length
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_CTRL_U
          # Clear line before cursor
          @value = @value[@cursor..]
          @cursor = 0
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_CTRL_K
          # Clear line after cursor
          @value = @value[0...@cursor]
          true
        else
          false
        end
      end

      def render
        if @value.empty? && !@placeholder.empty? && !@focused
          # Show placeholder when empty and not focused
          Styles.dim(@placeholder)
        elsif @focused
          render_with_cursor
        else
          display_value
        end
      end

      # Set value programmatically
      def value=(new_value)
        @value = new_value.to_s
        @cursor = @value.length
      end

      private

      def insert_char(char)
        @value = @value[0...@cursor].to_s + char + @value[@cursor..].to_s
        @cursor += char.length
      end

      def delete_backward
        return if @cursor.zero?

        @value = @value[0...(@cursor - 1)].to_s + @value[@cursor..].to_s
        @cursor -= 1
      end

      def delete_forward
        return if @cursor >= @value.length

        @value = @value[0...@cursor].to_s + @value[(@cursor + 1)..].to_s
      end

      def move_cursor(delta)
        @cursor = [0, [@cursor + delta, @value.length].min].max
      end

      def display_value
        @value.empty? ? Styles.dim(@placeholder) : @value
      end

      def render_with_cursor
        if @value.empty?
          # Show cursor at start with placeholder
          "#{cursor_char}#{Styles.dim(@placeholder)}"
        elsif @cursor >= @value.length
          # Cursor at end
          "#{@value}#{cursor_char}"
        else
          # Cursor in middle
          before = @value[0...@cursor]
          at_cursor = @value[@cursor]
          after = @value[(@cursor + 1)..]
          "#{before}#{highlight_char(at_cursor)}#{after}"
        end
      end

      def cursor_char
        # Use a visible cursor indicator
        "\e[7m \e[0m" # Reverse video space
      end

      def highlight_char(char)
        # Highlight the character under cursor with reverse video
        "\e[7m#{char}\e[0m"
      end
    end
  end
end
