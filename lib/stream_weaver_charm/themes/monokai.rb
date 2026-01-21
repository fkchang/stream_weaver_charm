# frozen_string_literal: true

module StreamWeaverCharm
  module Themes
    # Monokai theme - warm syntax-highlighting colors
    class Monokai < Base
      def initialize
        super(:monokai, {
          title: { fg: "#F92672", bold: true },      # Pink/Magenta
          header1: { fg: "#E6DB74", bold: true },    # Yellow
          header2: { fg: "#66D9EF", bold: true },    # Cyan
          header3: { fg: "#AE81FF", bold: true },    # Purple
          text: { fg: "#F8F8F2" },                   # Foreground
          dim: { fg: "#75715E" },                    # Comment
          help: { fg: "#75715E", italic: true },     # Comment
          success: { fg: "#A6E22E" },                # Green
          warning: { fg: "#FD971F" },                # Orange
          error: { fg: "#F92672" },                  # Pink/Red
          box_border: { fg: "#66D9EF" },             # Cyan
          alert_info: { fg: "#66D9EF" },             # Cyan
          alert_success: { fg: "#A6E22E" },          # Green
          alert_warning: { fg: "#FD971F" },          # Orange
          alert_error: { fg: "#F92672" },            # Pink/Red
          focus: { fg: "#A6E22E" },                  # Green
          cursor: { reverse: true },
          selected: { fg: "#F8F8F2", bold: true },
          placeholder: { fg: "#75715E" }             # Comment
        })
      end
    end
  end
end
