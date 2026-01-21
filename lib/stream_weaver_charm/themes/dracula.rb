# frozen_string_literal: true

module StreamWeaverCharm
  module Themes
    # Dracula theme - popular dark theme with purple/pink accents
    # https://draculatheme.com/
    class Dracula < Base
      def initialize
        super(:dracula, {
          title: { fg: "#FF79C6", bold: true },      # Pink
          header1: { fg: "#BD93F9", bold: true },    # Purple
          header2: { fg: "#8BE9FD", bold: true },    # Cyan
          header3: { fg: "#50FA7B", bold: true },    # Green
          text: { fg: "#F8F8F2" },                   # Foreground
          dim: { fg: "#6272A4" },                    # Comment
          help: { fg: "#6272A4", italic: true },     # Comment
          success: { fg: "#50FA7B" },                # Green
          warning: { fg: "#FFB86C" },                # Orange
          error: { fg: "#FF5555" },                  # Red
          box_border: { fg: "#BD93F9" },             # Purple
          alert_info: { fg: "#8BE9FD" },             # Cyan
          alert_success: { fg: "#50FA7B" },          # Green
          alert_warning: { fg: "#FFB86C" },          # Orange
          alert_error: { fg: "#FF5555" },            # Red
          focus: { fg: "#50FA7B" },                  # Green
          cursor: { reverse: true },
          selected: { fg: "#F8F8F2", bold: true },
          placeholder: { fg: "#6272A4" }             # Comment
        })
      end
    end
  end
end
