# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Single-select component (TUI dropdown alternative)
    #
    # Like List but optimized for small option sets.
    # Shows all options at once with radio-button style indicators.
    class Select
      attr_reader :key, :options, :cursor, :selected_index
      attr_accessor :focused

      def initialize(key, options: [], focused: false, selected: nil)
        @key = key
        @options = options || []
        @cursor = 0
        @focused = focused

        # Find initial selection
        @selected_index = if selected
                            @options.index(selected) || 0
                          else
                            nil
                          end
      end

      # Update options (called on each render)
      def options=(new_options)
        @options = new_options || []
        @cursor = [[@cursor, 0].max, [@options.length - 1, 0].max].min
      end

      # Get selected value
      def selected
        @selected_index ? @options[@selected_index] : nil
      end

      # Alias for consistency with other input components
      alias value selected

      # Handle a KeyMessage, returns true if consumed
      def handle_key(msg)
        return false unless @focused
        return false if @options.empty?

        if msg.down? || msg.to_s == "j"
          @cursor = (@cursor + 1) % @options.length
          true
        elsif msg.up? || msg.to_s == "k"
          @cursor = (@cursor - 1) % @options.length
          true
        elsif msg.enter? || msg.space?
          @selected_index = @cursor
          true
        else
          false
        end
      end

      def render
        return Styles.dim("(no options)") if @options.empty?

        @options.each_with_index.map do |option, i|
          render_option(option, i)
        end.join("\n")
      end

      private

      def render_option(option, index)
        # Radio button style: (o) selected, ( ) unselected
        radio = if index == @selected_index
                  "#{Styles.fg(:green)}(●)#{Styles::RESET}"
                else
                  "#{Styles.fg(:gray)}( )#{Styles::RESET}"
                end

        # Cursor indicator when focused
        cursor_prefix = if @focused && index == @cursor
                          "\e[7m>\e[0m"
                        else
                          " "
                        end

        text = option.to_s
        if @focused && index == @cursor
          "#{cursor_prefix} #{radio} #{Styles::BOLD}#{text}#{Styles::RESET}"
        else
          "#{cursor_prefix} #{radio} #{text}"
        end
      end
    end
  end
end
