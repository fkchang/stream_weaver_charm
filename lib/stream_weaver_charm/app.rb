# frozen_string_literal: true

module StreamWeaverCharm
  # Main App class that wraps Bubbletea::Model
  #
  # Implements the Elm Architecture while providing StreamWeaver's
  # declarative DSL. The key insight: the block re-executes on every
  # view() call, just like StreamWeaver re-executes on every HTTP request.
  class App
    include Bubbletea::Model

    attr_reader :title

    def initialize(title, **options, &block)
      @title = title
      @options = options
      @block = block
      @state = {}
      @components = []
      @key_handlers = {}
      @quit_keys = ["q", "ctrl+c"]

      # Input component support
      @focus_manager = FocusManager.new
      @input_components = {} # key => TextInput instance
    end

    # Bubbletea lifecycle: initialization
    def init
      [self, nil]
    end

    # Bubbletea lifecycle: handle messages (key presses, etc.)
    def update(msg)
      case msg
      when Bubbletea::KeyMessage
        key = msg.to_s.downcase

        # Ctrl+C always quits, other quit keys only when not typing
        if key == "ctrl+c"
          return [self, Bubbletea.quit]
        elsif @quit_keys.include?(key) && !input_focused?
          return [self, Bubbletea.quit]
        end

        # Handle Tab for focus cycling
        if msg.tab?
          @focus_manager.focus_next
          return [self, nil]
        end

        # Handle Shift+Tab for reverse focus cycling
        if msg.key_type == Bubbletea::KeyMessage::KEY_SHIFT_TAB
          @focus_manager.focus_previous
          return [self, nil]
        end

        # Forward message to focused input component
        if @focus_manager.focused_key
          input = @input_components[@focus_manager.focused_key]
          if input&.handle_key(msg)
            # Sync input value to state
            @state[@focus_manager.focused_key] = input.value
            return [self, nil]
          end
        end

        # Execute registered handler if present
        if (handler = @key_handlers[key])
          handler.call(@state)
        end
      end

      [self, nil]
    end

    # Check if any input is currently focused
    def input_focused?
      @focus_manager.focused_key && @input_components[@focus_manager.focused_key]
    end

    # Bubbletea lifecycle: render the view
    # This is where the magic happens - we re-execute the block every time
    def view
      # Clear previous render state
      @components = []
      @key_handlers = {}
      @focus_manager.clear

      # Re-execute the DSL block (StreamWeaver's core insight)
      instance_eval(&@block)

      # Validate focus after all inputs are registered
      @focus_manager.validate_focus

      # Update focus state on all input components
      @input_components.each do |key, input|
        input.focused = @focus_manager.focused?(key)
      end

      # Build the output string
      render_output
    end

    # Run the TUI app
    def run!
      Bubbletea.run(self)
    end

    # =========================================
    # State Access
    # =========================================

    def state
      @state
    end

    # =========================================
    # Key Binding DSL
    # =========================================

    # Register a key handler
    # @param key [String] The key to listen for (e.g., "+", "-", "enter", "ctrl+s")
    # @param block [Proc] Handler that receives state hash
    def on_key(key, &block)
      @key_handlers[key.to_s.downcase] = block
    end

    # Set custom quit keys (default: q, ctrl+c)
    def quit_on(*keys)
      @quit_keys = keys.map { |k| k.to_s.downcase }
    end

    # =========================================
    # Display Components DSL
    # =========================================

    # Plain text
    def text(content, style: nil)
      @components << Components::Text.new(content, style: style)
    end

    # Headers
    def header(content)
      @components << Components::Header.new(content, level: 2)
    end

    def header1(content)
      @components << Components::Header.new(content, level: 1)
    end

    def header2(content)
      @components << Components::Header.new(content, level: 2)
    end

    def header3(content)
      @components << Components::Header.new(content, level: 3)
    end

    # Horizontal divider
    def divider(width: 40, char: "-")
      @components << Components::Divider.new(width: width, char: char)
    end

    # =========================================
    # Input Components DSL
    # =========================================

    # Single-line text input
    # @param key [Symbol] State key to store the value
    # @param placeholder [String] Placeholder text shown when empty
    # @param label [String, nil] Optional label to show before input
    # @param width [Integer] Width of the input field
    def text_input(key, placeholder: "", label: nil, width: 30)
      # Get or create the input component (persists across renders)
      input = @input_components[key] ||= Components::TextInput.new(
        key,
        placeholder: placeholder,
        width: width
      )

      # Register with focus manager
      @focus_manager.register(key)

      # Build the display
      if label
        @components << Components::Text.new("#{label}: #{input.render}")
      else
        @components << Components::Text.new(input.render)
      end
    end

    # Multi-line text area
    # @param key [Symbol] State key to store the value
    # @param placeholder [String] Placeholder text shown when empty
    # @param label [String, nil] Optional label to show above the textarea
    # @param rows [Integer] Number of visible rows
    # @param width [Integer] Width of the textarea
    def text_area(key, placeholder: "", label: nil, rows: 4, width: 40)
      # Get or create the textarea component (persists across renders)
      input = @input_components[key] ||= Components::TextArea.new(
        key,
        placeholder: placeholder,
        rows: rows,
        width: width
      )

      # Register with focus manager
      @focus_manager.register(key)

      # Build the display
      if label
        @components << Components::Text.new("#{label}:")
        @components << Components::Text.new(input.render)
      else
        @components << Components::Text.new(input.render)
      end
    end

    # Focus a specific input programmatically
    def focus(key)
      @focus_manager.focus(key)
    end

    # =========================================
    # Selection Components DSL
    # =========================================

    # Scrollable, selectable list
    # @param key [Symbol] State key to store selected value
    # @param items [Array] List items to display
    # @param label [String, nil] Optional label above list
    # @param height [Integer] Visible rows (scrolls if more items)
    def list(key, items, label: nil, height: 5)
      list_component = @input_components[key] ||= Components::List.new(
        key,
        height: height
      )
      list_component.items = items

      # Register with focus manager
      @focus_manager.register(key)

      # Sync selected value to state
      @state[key] = list_component.selected if list_component.selected

      # Build display
      @components << Components::Text.new("#{label}:") if label
      @components << Components::Text.new(list_component.render)
    end

    # Table display (non-interactive)
    # @param data [Array<Hash>, nil] Array of hashes (keys become headers)
    # @param headers [Array, nil] Column headers
    # @param rows [Array<Array>, nil] Row data
    # @param border [Boolean] Show borders (default: true)
    # @param striped [Boolean] Alternate row shading (default: false)
    def table(data = nil, headers: nil, rows: nil, border: true, striped: false)
      table_component = Components::Table.new(
        data,
        headers: headers,
        rows: rows,
        border: border,
        striped: striped
      )
      @components << Components::Text.new(table_component.render)
    end

    # Single-select (radio-button style)
    # @param key [Symbol] State key to store selected value
    # @param options [Array] Options to choose from
    # @param label [String, nil] Optional label above select
    def select(key, options, label: nil)
      select_component = @input_components[key] ||= Components::Select.new(
        key,
        options: options
      )
      select_component.options = options

      # Register with focus manager
      @focus_manager.register(key)

      # Sync selected value to state
      @state[key] = select_component.selected if select_component.selected

      # Build display
      @components << Components::Text.new("#{label}:") if label
      @components << Components::Text.new(select_component.render)
    end

    # =========================================
    # Layout Components DSL
    # =========================================

    # Vertical stack
    def vstack(spacing: 1, &block)
      stack = Components::VStack.new(spacing: spacing)
      with_container(stack, &block)
    end

    # Horizontal stack
    def hstack(spacing: 2, &block)
      stack = Components::HStack.new(spacing: spacing)
      with_container(stack, &block)
    end

    # Box with border
    def box(title: nil, border: :rounded, &block)
      box_component = Components::Box.new(title: title, border: border)
      with_container(box_component, &block)
    end

    # Alert box
    def alert(variant: :info, &block)
      alert_component = Components::Alert.new(variant: variant)
      with_container(alert_component, &block)
    end

    # =========================================
    # Help Text
    # =========================================

    # Show help text for key bindings
    def help_text(text)
      @components << Components::Text.new(text, style: :help)
    end

    # Auto-generate help from registered keys
    def show_key_hints
      hints = @key_handlers.keys.map { |k| k }.join(" | ")
      hints += " | q: quit" unless @key_handlers.key?("q")
      help_text(hints)
    end

    private

    # Capture children into a container component
    def with_container(container, &block)
      return @components << container unless block

      parent_components = @components
      @components = []
      instance_eval(&block)
      container.children = @components
      @components = parent_components
      @components << container
    end

    # Render all components to a string
    def render_output
      lines = []

      # Title
      if @title && !@title.empty?
        lines << Styles.title(@title)
        lines << ""
      end

      # Components
      lines << @components.map(&:render).join("\n")

      lines.join("\n")
    end
  end
end
