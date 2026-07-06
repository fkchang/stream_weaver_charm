# frozen_string_literal: true

module StreamWeaverCharm
  module Themes
    # Light theme - for light-background terminals
    # Palette based on GitHub's light mode (well-tested contrast on light bg)
    class Light < Base
      def initialize
        super(:light, {
          title: { fg: "#CF222E", bold: true },      # Red
          header1: { fg: "#0969DA", bold: true },    # Blue
          header2: { fg: "#8250DF", bold: true },    # Purple
          header3: { fg: "#1A7F37", bold: true },    # Green
          text: { fg: "#24292F" },                   # Near-black
          dim: { fg: "#57606A" },                    # Gray
          help: { fg: "#57606A", italic: true },     # Gray
          success: { fg: "#1A7F37" },                # Green
          warning: { fg: "#9A6700" },                # Amber
          error: { fg: "#CF222E" },                  # Red
          box_border: { fg: "#8250DF" },             # Purple
          alert_info: { fg: "#0969DA" },             # Blue
          alert_success: { fg: "#1A7F37" },          # Green
          alert_warning: { fg: "#9A6700" },          # Amber
          alert_error: { fg: "#CF222E" },            # Red
          focus: { fg: "#1A7F37" },                  # Green
          cursor: { reverse: true },
          selected: { fg: "#24292F", bold: true },
          placeholder: { fg: "#57606A" }             # Gray
        })
      end
    end
  end
end
