# frozen_string_literal: true

require 'json'

module Leyline
  module Formatting
    # Formats data as JSON for machine-readable output
    class JsonFormatter
      def initialize(options = {})
        @pretty = options[:pretty] != false
        @include_metadata = options[:include_metadata] || false
      end

      # Format data as JSON
      def format(data)
        output = if @include_metadata
                   wrap_with_metadata(data)
                 else
                   data
                 end

        if @pretty
          JSON.pretty_generate(output)
        else
          JSON.generate(output)
        end
      end

      # Format and output to stdout
      def output(data)
        puts format(data)
      end

      # Format streaming output (for progress updates)
      def format_stream(data)
        # Use compact format for streaming
        JSON.generate(data)
      end

      private

      def wrap_with_metadata(data)
        {
          leyline_version: Leyline::VERSION,
          timestamp: Time.now.iso8601,
          data: data
        }
      end
    end
  end
end
