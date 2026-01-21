# frozen_string_literal: true

module StreamWeaverCharm
  module Themes
    # Nord theme - cool blue-gray arctic palette
    # https://www.nordtheme.com/
    class Nord < Base
      def initialize
        super(:nord, {
          title: { fg: "#BF616A", bold: true },      # Aurora Red
          header1: { fg: "#EBCB8B", bold: true },    # Aurora Yellow
          header2: { fg: "#81A1C1", bold: true },    # Frost Blue
          header3: { fg: "#B48EAD", bold: true },    # Aurora Purple
          text: { fg: "#ECEFF4" },                   # Snow Storm
          dim: { fg: "#4C566A" },                    # Polar Night
          help: { fg: "#4C566A", italic: true },     # Polar Night
          success: { fg: "#A3BE8C" },                # Aurora Green
          warning: { fg: "#EBCB8B" },                # Aurora Yellow
          error: { fg: "#BF616A" },                  # Aurora Red
          box_border: { fg: "#5E81AC" },             # Frost Blue
          alert_info: { fg: "#81A1C1" },             # Frost Blue
          alert_success: { fg: "#A3BE8C" },          # Aurora Green
          alert_warning: { fg: "#EBCB8B" },          # Aurora Yellow
          alert_error: { fg: "#BF616A" },            # Aurora Red
          focus: { fg: "#88C0D0" },                  # Frost Cyan
          cursor: { reverse: true },
          selected: { fg: "#ECEFF4", bold: true },
          placeholder: { fg: "#4C566A" }             # Polar Night
        })
      end
    end
  end
end
