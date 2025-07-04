#!/usr/bin/env ruby
# lib/error_formatter.rb - Enhanced error formatting with colorization and TTY support
# Provides rich, colorized error output for terminal environments and plain text for CI/pipes

class ErrorFormatter
  # ANSI color codes for different error elements
  COLORS = {
    red: "\e[31m",
    yellow: "\e[33m",
    blue: "\e[34m",
    cyan: "\e[36m",
    gray: "\e[90m",
    bold: "\e[1m",
    reset: "\e[0m"
  }.freeze

  def initialize
    @use_colors = should_use_colors?
  end

  # Render collected errors with formatting and grouping
  #
  # @param errors [Array<Hash>] Array of error hashes from ErrorCollector
  # @param file_contents [Hash, nil] Optional mapping of file paths to their content for context snippets
  # @return [String] Formatted error output ready for display
  def render(errors, file_contents = nil)
    return '' if errors.empty?

    output = []

    # Group errors by file
    errors_by_file = group_errors_by_file(errors)

    # Render header
    error_count = errors.length
    file_count = errors_by_file.keys.length

    output << format_header(error_count, file_count)
    output << ''

    # Render each file's errors
    errors_by_file.each do |file, file_errors|
      file_content = file_contents && file_contents[file]
      output << format_file_section(file, file_errors, file_content)
      output << ''
    end

    # Remove trailing empty line
    output.pop if output.last == ''

    output.join("\n")
  end

  private

  # Determine if colors should be used based on TTY and environment
  #
  # @return [Boolean] True if colors should be used
  def should_use_colors?
    # Respect NO_COLOR environment variable (https://no-color.org/)
    return false if ENV['NO_COLOR'] && !ENV['NO_COLOR'].empty?

    # Use colors only if output is to a TTY
    STDOUT.tty?
  end

  # Apply color formatting if colors are enabled
  #
  # @param text [String] Text to colorize
  # @param color [Symbol] Color key from COLORS hash
  # @return [String] Colorized text or plain text
  def colorize(text, color)
    return text unless @use_colors
    return text unless COLORS.key?(color)

    "#{COLORS[color]}#{text}#{COLORS[:reset]}"
  end

  # Group errors by filename for organized output
  #
  # @param errors [Array<Hash>] Array of error hashes
  # @return [Hash] Hash mapping filenames to arrays of their errors
  def group_errors_by_file(errors)
    grouped = {}

    errors.each do |error|
      file = error[:file]
      grouped[file] ||= []
      grouped[file] << error
    end

    # Sort files alphabetically for consistent output
    Hash[grouped.sort]
  end

  # Format the main header with error summary
  #
  # @param error_count [Integer] Total number of errors
  # @param file_count [Integer] Number of files with errors
  # @return [String] Formatted header
  def format_header(error_count, file_count)
    error_text = error_count == 1 ? 'error' : 'errors'
    file_text = file_count == 1 ? 'file' : 'files'

    header = "Validation failed with #{error_count} #{error_text} in #{file_count} #{file_text}:"
    colorize(header, :red)
  end

  # Format a section for one file and its errors
  #
  # @param file [String] File path
  # @param file_errors [Array<Hash>] Errors for this file
  # @param file_content [String, nil] Content of the file for context snippets
  # @return [String] Formatted file section
  def format_file_section(file, file_errors, file_content = nil)
    output = []

    # File header
    file_header = "#{file}:"
    output << colorize(file_header, :bold)

    # Format each error in this file
    file_errors.each do |error|
      output << format_single_error(error, file_content)
    end

    output.join("\n")
  end

  # Format a single error with all its context
  #
  # @param error [Hash] Error hash with context
  # @param file_content [String, nil] Content of the file for context snippets
  # @return [String] Formatted error
  def format_single_error(error, file_content = nil)
    output = []

    # Error indicator and message
    indicator = @use_colors ? '  ✗' : '  [ERROR]'
    output << "#{colorize(indicator, :red)} #{error[:message]}"

    # Location information (line and field if available)
    location_parts = []
    location_parts << "line #{error[:line]}" if error[:line]
    location_parts << "field '#{error[:field]}'" if error[:field]

    unless location_parts.empty?
      location = "    #{location_parts.join(', ')}"
      output << colorize(location, :gray)
    end

    # Error type (for debugging/categorization)
    if error[:type]
      type_info = "    type: #{error[:type]}"
      output << colorize(type_info, :gray)
    end

    # Context snippet (if line number and file content available)
    if error[:line] && file_content
      context_snippet = format_context_snippet(error[:line], file_content)
      unless context_snippet.empty?
        output << ''
        output += context_snippet
      end
    end

    # Suggestion (if available)
    if error[:suggestion] && !error[:suggestion].empty?
      suggestion_header = '    suggestion:'
      output << colorize(suggestion_header, :cyan)

      # Handle multi-line suggestions with proper indentation
      suggestion_lines = error[:suggestion].split("\n")
      suggestion_lines.each do |line|
        formatted_line = "      #{line}"
        output << colorize(formatted_line, :cyan)
      end
    end

    output.join("\n")
  end

  # Format context snippet showing lines around the error
  #
  # @param error_line [Integer] Line number where error occurred (1-based)
  # @param file_content [String] Full content of the file
  # @return [Array<String>] Array of formatted context lines
  def format_context_snippet(error_line, file_content)
    return [] if file_content.nil? || file_content.empty?

    lines = file_content.split("\n")
    return [] if lines.empty?

    # Convert to 0-based index for array access
    error_index = error_line - 1
    return [] if error_index < 0 || error_index >= lines.length

    # Determine context range (1-2 lines before and after)
    context_before = 2
    context_after = 2

    start_index = [0, error_index - context_before].max
    end_index = [lines.length - 1, error_index + context_after].min

    context_lines = []

    # Add context header
    context_lines << colorize('    context:', :blue)

    # Format each line in the context
    (start_index..end_index).each do |i|
      line_number = i + 1
      line_content = lines[i]

      # Truncate very long lines to keep output readable
      line_content = line_content[0..76] + '...' if line_content.length > 80

      # Format line number with padding
      line_num_str = format('%3d', line_number)

      if i == error_index
        # Highlight the error line
        indicator = @use_colors ? '→' : '>'
        line_prefix = "      #{colorize(line_num_str, :red)} #{colorize(indicator, :red)} "
        formatted_line = "#{line_prefix}#{colorize(line_content, :red)}"
      else
        # Regular context line
        line_prefix = "      #{colorize(line_num_str, :gray)} │ "
        formatted_line = "#{line_prefix}#{colorize(line_content, :gray)}"
      end

      context_lines << formatted_line
    end

    context_lines
  end
end
