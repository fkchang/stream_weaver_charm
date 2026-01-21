# frozen_string_literal: true

module StreamWeaverCharm
  module Components
    # Table component for displaying tabular data
    #
    # Supports two input formats:
    # 1. headers: [...], rows: [[...], [...]]
    # 2. Array of hashes (headers inferred from keys)
    class Table
      def initialize(data = nil, headers: nil, rows: nil, border: true, striped: false)
        @border = border
        @striped = striped

        if data.is_a?(Array) && data.first.is_a?(Hash)
          # Array of hashes format
          @headers = data.first.keys.map(&:to_s)
          @rows = data.map { |row| @headers.map { |h| row[h.to_sym]&.to_s || row[h]&.to_s || "" } }
        else
          # Explicit headers/rows format
          @headers = headers&.map(&:to_s) || []
          @rows = rows&.map { |r| r.map(&:to_s) } || []
        end

        calculate_widths
      end

      def render
        return "" if @headers.empty? && @rows.empty?

        lines = []

        if @border
          lines << top_border
          lines << header_row if @headers.any?
          lines << header_separator if @headers.any?
          @rows.each_with_index do |row, i|
            lines << data_row(row, i)
          end
          lines << bottom_border
        else
          lines << simple_header_row if @headers.any?
          lines << simple_separator if @headers.any?
          @rows.each_with_index do |row, i|
            lines << simple_data_row(row, i)
          end
        end

        lines.join("\n")
      end

      private

      def calculate_widths
        all_rows = [@headers] + @rows
        return @widths = [] if all_rows.flatten.empty?

        num_cols = all_rows.map(&:length).max || 0
        @widths = (0...num_cols).map do |i|
          all_rows.map { |row| (row[i] || "").to_s.length }.max || 0
        end
      end

      # Bordered rendering
      def top_border
        "#{Styles.fg(:gray)}┌#{@widths.map { |w| '─' * (w + 2) }.join('┬')}┐#{Styles::RESET}"
      end

      def header_separator
        "#{Styles.fg(:gray)}├#{@widths.map { |w| '─' * (w + 2) }.join('┼')}┤#{Styles::RESET}"
      end

      def bottom_border
        "#{Styles.fg(:gray)}└#{@widths.map { |w| '─' * (w + 2) }.join('┴')}┘#{Styles::RESET}"
      end

      def header_row
        cells = @headers.each_with_index.map do |h, i|
          " #{Styles::BOLD}#{h.ljust(@widths[i])}#{Styles::RESET} "
        end
        "#{Styles.fg(:gray)}│#{Styles::RESET}#{cells.join("#{Styles.fg(:gray)}│#{Styles::RESET}")}#{Styles.fg(:gray)}│#{Styles::RESET}"
      end

      def data_row(row, row_index)
        cells = row.each_with_index.map do |cell, i|
          content = (cell || "").ljust(@widths[i] || 0)
          if @striped && row_index.odd?
            " #{Styles::DIM}#{content}#{Styles::RESET} "
          else
            " #{content} "
          end
        end
        "#{Styles.fg(:gray)}│#{Styles::RESET}#{cells.join("#{Styles.fg(:gray)}│#{Styles::RESET}")}#{Styles.fg(:gray)}│#{Styles::RESET}"
      end

      # Borderless rendering
      def simple_header_row
        @headers.each_with_index.map do |h, i|
          "#{Styles::BOLD}#{h.ljust(@widths[i])}#{Styles::RESET}"
        end.join("  ")
      end

      def simple_separator
        @widths.map { |w| "-" * w }.join("  ")
      end

      def simple_data_row(row, row_index)
        cells = row.each_with_index.map do |cell, i|
          (cell || "").ljust(@widths[i] || 0)
        end
        if @striped && row_index.odd?
          "#{Styles::DIM}#{cells.join('  ')}#{Styles::RESET}"
        else
          cells.join("  ")
        end
      end
    end
  end
end
