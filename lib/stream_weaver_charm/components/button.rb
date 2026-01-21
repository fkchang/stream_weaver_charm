# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Clickable button component
    #
    # Renders as [Label] and can be clicked with mouse.
    # Also responds to Enter key when focused.
    class Button
      attr_reader :id, :label
      attr_accessor :focused

      def initialize(id, label, focused: false)
        @id = id
        @label = label
        @focused = focused
      end

      # Visual width of the button (for hit testing)
      def width
        # [ + label + ] = label.length + 2
        label.length + 2
      end

      def render
        if @focused
          # Highlighted when focused
          "#{Styles::REVERSE}[#{@label}]#{Styles::RESET}"
        else
          # Normal button style
          "#{Styles.fg(:cyan)}[#{Styles::RESET}#{@label}#{Styles.fg(:cyan)}]#{Styles::RESET}"
        end
      end

      # Handle key press (Enter activates button)
      def handle_key(msg)
        return false unless @focused
        return false unless msg.enter?

        true  # Signal that button was activated
      end
    end
  end
end
