# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Scrollable, selectable list component
    #
    # Supports keyboard navigation with j/k or arrow keys,
    # Enter to select, and scrolling for long lists.
    class List
      attr_reader :key, :items, :cursor, :selected
      attr_accessor :focused

      # Alias for consistency with other input components
      alias value selected

      def initialize(key, items: [], focused: false, height: 5)
        @key = key
        @items = items
        @cursor = 0
        @selected = nil
        @focused = focused
        @height = height
        @scroll_offset = 0
      end

      # Update items (called on each render)
      def items=(new_items)
        @items = new_items || []
        # Keep cursor in bounds
        @cursor = [[@cursor, 0].max, [@items.length - 1, 0].max].min
        update_scroll
      end

      # Handle a KeyMessage, returns true if consumed
      def handle_key(msg)
        return false unless @focused
        return false if @items.empty?

        if msg.down? || msg.to_s == "j"
          move_cursor(1)
          true
        elsif msg.up? || msg.to_s == "k"
          move_cursor(-1)
          true
        elsif msg.enter?
          @selected = @items[@cursor]
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_HOME
          @cursor = 0
          update_scroll
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_END
          @cursor = @items.length - 1
          update_scroll
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_PGUP
          move_cursor(-@height)
          true
        elsif msg.key_type == Bubbletea::KeyMessage::KEY_PGDOWN
          move_cursor(@height)
          true
        else
          false
        end
      end

      def render
        return Styles.dim("(empty)") if @items.empty?

        visible_items = @items[@scroll_offset, @height] || []
        lines = visible_items.each_with_index.map do |item, i|
          actual_index = @scroll_offset + i
          render_item(item, actual_index)
        end

        # Add scroll indicators if needed
        if @scroll_offset > 0
          lines[0] = "#{lines[0]}  ↑"
        end
        if @scroll_offset + @height < @items.length
          lines[-1] = "#{lines[-1]}  ↓"
        end

        lines.join("\n")
      end

      private

      def move_cursor(delta)
        @cursor = [[@cursor + delta, 0].max, @items.length - 1].min
        update_scroll
      end

      def update_scroll
        # Ensure cursor is visible in viewport
        if @cursor < @scroll_offset
          @scroll_offset = @cursor
        elsif @cursor >= @scroll_offset + @height
          @scroll_offset = @cursor - @height + 1
        end
        @scroll_offset = [[@scroll_offset, 0].max, [@items.length - @height, 0].max].min
      end

      def render_item(item, index)
        prefix = if @focused && index == @cursor
                   "\e[7m>\e[0m "  # Reverse video cursor
                 else
                   "  "
                 end

        text = item.to_s
        if index == @cursor && @focused
          "#{prefix}\e[1m#{text}\e[0m"  # Bold selected item
        else
          "#{prefix}#{text}"
        end
      end
    end
  end
end
