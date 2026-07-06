# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Renders a markdown string to ANSI-styled terminal output via Glamour.
    class Markdown < Component
      # Maps our theme names to Glamour's built-in style presets.
      # Themes with no direct Glamour equivalent fall back to "auto".
      GLAMOUR_STYLE_BY_THEME = {
        dracula: "dracula",
        light: "light"
      }.freeze
      DEFAULT_GLAMOUR_STYLE = "auto"

      def initialize(content, style: nil)
        super(type: :markdown, content: content, options: { style: style })
      end

      def render
        Glamour.render(content.to_s, style: resolved_style)
      end

      private

      def resolved_style
        options[:style] || GLAMOUR_STYLE_BY_THEME.fetch(Styles.current_theme.name, DEFAULT_GLAMOUR_STYLE)
      end
    end
  end
end
