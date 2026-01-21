# frozen_string_literal: true

module StreamWeaverCharm
  # Component structs for TUI rendering
  # These are simple data containers that get rendered to strings in view()
  module Components
    # Base component that all others inherit from
    Component = Struct.new(:type, :content, :options, keyword_init: true) do
      def render
        raise NotImplementedError, "Subclasses must implement #render"
      end
    end

    # Plain text
    class Text < Component
      def initialize(content, style: nil)
        super(type: :text, content: content, options: { style: style })
      end

      def render
        style = options[:style]
        return content.to_s unless style

        case style
        when Hash
          # Custom style hash
          Styles.apply_style(content.to_s, style)
        when :dim then Styles.dim(content.to_s)
        when :help then Styles.help(content.to_s)
        when :success then Styles.success(content.to_s)
        when :warning then Styles.warning(content.to_s)
        when :error then Styles.error(content.to_s)
        else content.to_s
        end
      end
    end

    # Headers (h1-h3)
    class Header < Component
      def initialize(content, level: 1)
        super(type: :header, content: content, options: { level: level })
      end

      def render
        case options[:level]
        when 1 then Styles.header1(content.to_s)
        when 2 then Styles.header2(content.to_s)
        when 3 then Styles.header3(content.to_s)
        else Styles.header1(content.to_s)
        end
      end
    end

    # Horizontal divider
    class Divider < Component
      def initialize(width: 40, char: "-")
        super(type: :divider, content: nil, options: { width: width, char: char })
      end

      def render
        Styles.divider(options[:width])
      end
    end

    # Vertical stack - joins children with newlines
    class VStack < Component
      attr_accessor :children

      def initialize(spacing: 1)
        super(type: :vstack, content: nil, options: { spacing: spacing })
        @children = []
      end

      def render
        separator = "\n" * options[:spacing]
        children.map(&:render).join(separator)
      end
    end

    # Horizontal stack - joins children horizontally
    # Handles multi-line content by rendering columns side-by-side
    class HStack < Component
      attr_accessor :children

      def initialize(spacing: 2)
        super(type: :hstack, content: nil, options: { spacing: spacing })
        @children = []
      end

      def render
        return "" if children.empty?

        spacing = options[:spacing]

        # Split each child's render into lines
        columns = children.map { |c| c.render.split("\n") }

        # Find max height
        max_height = columns.map(&:length).max || 0
        return "" if max_height.zero?

        # Calculate visible width of each column (stripping ANSI codes)
        col_widths = columns.map do |lines|
          lines.map { |l| Styles.visible_length(l) }.max || 0
        end

        # Build output line by line
        (0...max_height).map do |row|
          columns.each_with_index.map do |lines, col_idx|
            line = lines[row] || ""
            # Pad to column width for alignment (except last column)
            if col_idx < columns.length - 1
              Styles.visible_ljust(line, col_widths[col_idx])
            else
              line
            end
          end.join(" " * spacing)
        end.join("\n")
      end
    end

    # Box with border
    class Box < Component
      attr_accessor :children

      def initialize(title: nil, border: :rounded)
        super(type: :box, content: nil, options: { title: title, border: border })
        @children = []
      end

      def render
        inner = children.map(&:render).join("\n")
        Styles.box(inner, title: options[:title])
      end
    end

    # Alert box with variant styling
    class Alert < Component
      attr_accessor :children

      def initialize(variant: :info)
        super(type: :alert, content: nil, options: { variant: variant })
        @children = []
      end

      def render
        inner = children.map(&:render).join("\n")
        Styles.alert(inner, variant: options[:variant])
      end
    end
  end
end
