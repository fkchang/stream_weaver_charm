# frozen_string_literal: true

module StreamWeaverCharm
  # Manages focus cycling between input components
  #
  # TUIs can only have one active input at a time, so this tracks
  # which input should receive keyboard events.
  class FocusManager
    attr_reader :focused_key

    def initialize
      @input_keys = []
      @focused_key = nil
    end

    # Register an input key in focus order
    def register(key)
      @input_keys << key unless @input_keys.include?(key)
      @focused_key ||= key # Auto-focus first registered input
    end

    # Clear all registered inputs (called on each render)
    def clear
      @input_keys = []
      # Keep @focused_key so focus persists across renders
    end

    # Focus a specific input by key
    def focus(key)
      @focused_key = key if @input_keys.include?(key)
    end

    # Move focus to next input (Tab behavior)
    def focus_next
      return if @input_keys.empty?

      current_index = @input_keys.index(@focused_key) || -1
      next_index = (current_index + 1) % @input_keys.length
      @focused_key = @input_keys[next_index]
    end

    # Move focus to previous input (Shift+Tab behavior)
    def focus_previous
      return if @input_keys.empty?

      current_index = @input_keys.index(@focused_key) || 0
      prev_index = (current_index - 1) % @input_keys.length
      @focused_key = @input_keys[prev_index]
    end

    # Check if a key is currently focused
    def focused?(key)
      @focused_key == key
    end

    # Validate focus - ensure focused_key is still valid
    def validate_focus
      return if @input_keys.empty?

      unless @input_keys.include?(@focused_key)
        @focused_key = @input_keys.first
      end
    end
  end
end
