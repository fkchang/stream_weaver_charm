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

      # Agentic mode (run_once!) support
      @run_once_mode = false
      @submit_keys = []
      @submitted = false

      # Theme support
      @theme = options[:theme]
      @custom_styles = {} # name => style hash

      # Set theme if provided
      Styles.current_theme = @theme if @theme

      # Mouse/button support
      @buttons = {} # id => { row:, col:, width:, callback: }
      @pending_button_callbacks = {} # component.object_id => { id:, width:, callback: }
      @next_button_id = 0
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

        # Handle submit keys (for run_once! mode)
        if @run_once_mode && @submit_keys.include?(key)
          @submitted = true
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

      when Bubbletea::MouseMessage
        # Handle mouse clicks on buttons (trigger on release for better UX)
        # Note: SGR protocol uses button=0 for left click (bubbletea's BUTTON_LEFT constant is wrong)
        if msg.release? && msg.button == 0
          handle_mouse_click(msg.x, msg.y)
        end
      end

      [self, nil]
    end

    # Handle mouse click at coordinates
    def handle_mouse_click(x, y)
      @buttons.each do |_id, btn|
        if y == btn[:row] && x >= btn[:col] && x < btn[:col] + btn[:width]
          btn[:callback]&.call(@state)
          return
        end
      end
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
      @buttons = {}
      @pending_button_callbacks = {}
      @next_button_id = 0

      # Re-execute the DSL block (StreamWeaver's core insight)
      instance_eval(&@block)

      # Validate focus after all inputs are registered
      @focus_manager.validate_focus

      # Update focus state on all input components
      @input_components.each do |key, input|
        input.focused = @focus_manager.focused?(key)
      end

      # Build the output string and track button positions
      render_output_with_buttons
    end

    # Run the TUI app
    # @param mouse [Boolean] Enable mouse support (default: false)
    # @param alt_screen [Boolean] Use alternate screen buffer (default: true when mouse enabled)
    def run!(mouse: false, alt_screen: nil)
      # Auto-enable alt_screen when mouse is used (mouse coords are absolute to terminal)
      alt_screen = mouse if alt_screen.nil?

      options = {}
      options[:mouse_cell_motion] = true if mouse
      options[:alt_screen] = true if alt_screen

      Bubbletea.run(self, **options)
    end

    # Run the TUI app in one-shot mode (agentic mode)
    # Returns the state hash when user submits, or nil if cancelled
    # @param mouse [Boolean] Enable mouse support (default: false)
    # @param alt_screen [Boolean] Use alternate screen buffer (default: true when mouse enabled)
    # @return [Hash, nil] The state hash on submit, nil on cancel
    def run_once!(mouse: false, alt_screen: nil)
      @run_once_mode = true

      # Auto-enable alt_screen when mouse is used (mouse coords are absolute to terminal)
      alt_screen = mouse if alt_screen.nil?

      options = {}
      options[:mouse_cell_motion] = true if mouse
      options[:alt_screen] = true if alt_screen

      Bubbletea.run(self, **options)
      @submitted ? @state.dup : nil
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

    # Set submit keys for run_once! mode
    # @param keys [Array<String>] Keys that trigger form submission (e.g., "ctrl+s", "enter")
    def submit_on(*keys)
      @submit_keys = keys.map { |k| k.to_s.downcase }
    end

    # =========================================
    # Style DSL
    # =========================================

    # Define a custom style for use in text components
    # @param name [Symbol] Style name to reference
    # @param fg [Symbol, String, Integer] Foreground color
    # @param bg [Symbol, String, Integer] Background color
    # @param bold [Boolean] Bold text
    # @param dim [Boolean] Dimmed text
    # @param italic [Boolean] Italic text
    def style(name, fg: nil, bg: nil, bold: false, dim: false, italic: false)
      @custom_styles[name] = { fg: fg, bg: bg, bold: bold, dim: dim, italic: italic }
    end

    # Get a custom style by name
    def get_style(name)
      @custom_styles[name]
    end

    # =========================================
    # Display Components DSL
    # =========================================

    # Plain text
    # @param content [String] Text content
    # @param style [Symbol, Hash, nil] Style name or style hash
    def text(content, style: nil)
      # Resolve custom style names to style hashes
      resolved_style = case style
                       when Symbol
                         @custom_styles[style] || style  # Try custom, fall back to built-in
                       when Hash
                         style
                       else
                         nil
                       end
      @components << Components::Text.new(content, style: resolved_style)
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
    # Interactive Components DSL
    # =========================================

    # Clickable button (requires mouse: true in run!)
    # @param label [String] Button label text
    # @param block [Proc] Callback when button is clicked
    def button(label, &block)
      btn_id = @next_button_id
      @next_button_id += 1

      btn = Components::Button.new(btn_id, label)
      text_component = Components::Text.new(btn.render)

      # Store callback to be registered during render
      @pending_button_callbacks[text_component.object_id] = {
        id: btn_id,
        width: btn.width,
        callback: block
      }

      @components << text_component
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
      render_output_with_buttons
    end

    # Render and track button positions for mouse support
    def render_output_with_buttons
      output_lines = []

      # Title
      if @title && !@title.empty?
        output_lines << Styles.title(@title)
        output_lines << ""
      end

      # Render components and track button positions
      current_row = output_lines.length
      @components.each do |component|
        rendered = component.render
        rendered_lines = rendered.split("\n")

        # Check if this component contains buttons
        if component.is_a?(Components::Text) && @pending_button_callbacks[component.object_id]
          btn_info = @pending_button_callbacks[component.object_id]
          @buttons[btn_info[:id]] = {
            row: current_row,
            col: 0,  # Buttons start at column 0 for simplicity
            width: btn_info[:width],
            callback: btn_info[:callback]
          }
        end

        output_lines.concat(rendered_lines)
        current_row += rendered_lines.length
      end

      output_lines.join("\n")
    end
  end
end
