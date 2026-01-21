# frozen_string_literal: true

module StreamWeaverCharm
  module Themes
    # Registry for looking up themes by name
    module Registry
      THEMES = {
        default: -> { Default.new },
        dracula: -> { Dracula.new },
        nord: -> { Nord.new },
        monokai: -> { Monokai.new }
      }.freeze

      module_function

      # Get a theme by name or return a custom theme hash wrapped in Base
      def get(theme)
        case theme
        when Symbol
          builder = THEMES[theme]
          raise ArgumentError, "Unknown theme: #{theme}. Available: #{THEMES.keys.join(', ')}" unless builder

          builder.call
        when Hash
          Base.new(:custom, theme)
        when Base
          theme
        when nil
          Default.new
        else
          raise ArgumentError, "Theme must be a Symbol, Hash, or Theme instance"
        end
      end

      # List available theme names
      def available
        THEMES.keys
      end
    end
  end
end
