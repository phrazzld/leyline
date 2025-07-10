# frozen_string_literal: true

module Leyline
  module Formatting
    # Formats data as ASCII tables for console output
    class TableFormatter
      DEFAULT_MAX_WIDTH = 80
      DEFAULT_PADDING = 2

      def initialize(options = {})
        @max_width = options[:max_width] || DEFAULT_MAX_WIDTH
        @padding = options[:padding] || DEFAULT_PADDING
      end

      # Format data as a simple table
      # data: Array of hashes with consistent keys
      def format_table(data, columns = nil)
        return '' if data.empty?

        columns ||= data.first.keys
        column_widths = calculate_column_widths(data, columns)

        lines = []
        lines << format_header(columns, column_widths)
        lines << format_separator(column_widths)

        data.each do |row|
          lines << format_row(row, columns, column_widths)
        end

        lines.join("\n")
      end

      # Format key-value pairs
      def format_pairs(pairs, options = {})
        return '' if pairs.empty?

        key_width = pairs.keys.map(&:to_s).map(&:length).max
        key_width = [key_width, options[:max_key_width] || 30].min

        lines = []
        pairs.each do |key, value|
          formatted_key = "#{key}:".ljust(key_width + 1)
          lines << "  #{formatted_key} #{format_value(value)}"
        end

        lines.join("\n")
      end

      # Format a list with bullets
      def format_list(items, options = {})
        return '' if items.empty?

        bullet = options[:bullet] || '•'
        indent = options[:indent] || 2

        items.map do |item|
          "#{' ' * indent}#{bullet} #{item}"
        end.join("\n")
      end

      # Format a section with title
      def format_section(title, content = nil, &block)
        lines = []
        lines << title
        lines << '=' * title.length

        if block_given?
          lines << yield
        elsif content
          lines << content
        end

        lines.join("\n")
      end

      private

      def calculate_column_widths(data, columns)
        widths = {}

        columns.each do |col|
          # Start with header width
          widths[col] = col.to_s.length

          # Check all data rows
          data.each do |row|
            value_length = format_value(row[col]).length
            widths[col] = value_length if value_length > widths[col]
          end
        end

        # Adjust widths to fit max width
        adjust_widths_to_fit(widths)
      end

      def adjust_widths_to_fit(widths)
        total_width = widths.values.sum + (widths.size - 1) * @padding

        if total_width > @max_width
          # Proportionally reduce widths
          scale = @max_width.to_f / total_width
          widths.transform_values! { |w| [(w * scale).to_i, 10].max }
        end

        widths
      end

      def format_header(columns, widths)
        columns.map { |col| col.to_s.ljust(widths[col]) }.join(' ' * @padding)
      end

      def format_separator(widths)
        widths.values.map { |w| '-' * w }.join(' ' * @padding)
      end

      def format_row(row, columns, widths)
        columns.map do |col|
          value = format_value(row[col])
          truncate(value, widths[col]).ljust(widths[col])
        end.join(' ' * @padding)
      end

      def format_value(value)
        case value
        when nil
          ''
        when true
          '✓'
        when false
          '✗'
        when Time, DateTime
          value.strftime('%Y-%m-%d %H:%M')
        when Date
          value.strftime('%Y-%m-%d')
        when Float
          format('%.2f', value)
        else
          value.to_s
        end
      end

      def truncate(string, max_length)
        return string if string.length <= max_length
        return string if max_length < 4

        "#{string[0...(max_length - 3)]}..."
      end
    end
  end
end
