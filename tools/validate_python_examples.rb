#!/usr/bin/env ruby
# tools/validate_python_examples.rb - Validates Python code examples in markdown files
#
# This script extracts Python code blocks from markdown files in the
# docs/bindings/categories/python/ directory and validates them using
# flake8 and mypy.
#
# Usage:
# - Validate all Python binding files: ruby tools/validate_python_examples.rb
# - Validate specific file: ruby tools/validate_python_examples.rb -f path/to/file.md
# - Verbose output: ruby tools/validate_python_examples.rb -v

require 'optparse'
require 'fileutils'
require 'tempfile'
require 'time'
require 'json'

# Load enhanced validation and metrics components
require_relative '../lib/error_collector'
require_relative '../lib/metrics_collector'

# Configuration
PYTHON_DIR = 'docs/bindings/categories/python'
FLAKE8_CONFIG = [
  '--max-line-length=88',
  '--extend-ignore=E203,W503', # Compatible with black formatter
  '--exclude=.git,__pycache__,venv'
]
MYPY_CONFIG = [
  '--strict',
  '--no-error-summary',
  '--show-column-numbers'
]

class PythonCodeValidator
  def initialize(verbose: false)
    @verbose = verbose
    @temp_files = []
    @error_collector = ErrorCollector.new
    @metrics_collector = MetricsCollector.new(tool_name: 'validate_python_examples', tool_version: '1.0.0')

    # Log validation start
    log_structured_start
  end

  def validate_all_files
    markdown_files = Dir.glob("#{PYTHON_DIR}/**/*.md")

    if markdown_files.empty?
      puts "No Python binding files found in #{PYTHON_DIR}"
      return true
    end

    puts "Validating Python code examples in #{markdown_files.length} files..." if @verbose

    success = true
    markdown_files.each do |file|
      success = validate_file(file) && success
    end

    success
  end

  def validate_file(file_path)
    @metrics_collector.start_timer(operation: 'validate_file')

    unless File.exist?(file_path)
      add_error(file_path, 0, 'File not found')
      @metrics_collector.end_timer(operation: 'validate_file', success: false,
                                   metadata: { file: file_path, error: 'file_not_found' })
      return false
    end

    puts "Validating #{file_path}..." if @verbose

    content = File.read(file_path)
    code_blocks = extract_python_code_blocks(content, file_path)

    if code_blocks.empty?
      puts '  No Python code blocks found' if @verbose
      @metrics_collector.end_timer(operation: 'validate_file', success: true,
                                   metadata: { file: file_path, code_blocks: 0 })
      return true
    end

    puts "  Found #{code_blocks.length} Python code block(s)" if @verbose

    success = true
    code_blocks.each_with_index do |block, index|
      success = validate_code_block(block, file_path, index + 1) && success
    end

    @metrics_collector.end_timer(operation: 'validate_file', success: success, metadata: {
                                   file: file_path,
                                   code_blocks: code_blocks.length,
                                   errors: @error_collector.count
                                 })

    success
  end

  private

  def extract_python_code_blocks(content, file_path)
    blocks = []
    lines = content.lines
    in_python_block = false
    current_block = []
    block_start_line = 0

    lines.each_with_index do |line, line_number|
      if line.strip.start_with?('```python')
        in_python_block = true
        block_start_line = line_number + 1
        current_block = []
      elsif line.strip == '```' && in_python_block
        in_python_block = false
        unless current_block.empty?
          blocks << {
            code: current_block.join,
            start_line: block_start_line,
            file: file_path
          }
        end
        current_block = []
      elsif in_python_block
        current_block << line
      end
    end

    # Handle unclosed block
    add_error(file_path, block_start_line, 'Unclosed Python code block') if in_python_block && !current_block.empty?

    blocks
  end

  def validate_code_block(block, file_path, block_number)
    # Create temporary file for the code block
    temp_file = Tempfile.new(['python_example', '.py'])
    @temp_files << temp_file

    begin
      temp_file.write(block[:code])
      temp_file.flush

      puts "  Validating block #{block_number} (line #{block[:start_line]})" if @verbose

      # Run flake8
      flake8_success = run_flake8(temp_file.path, file_path, block[:start_line], block_number)

      # Run mypy
      mypy_success = run_mypy(temp_file.path, file_path, block[:start_line], block_number)

      flake8_success && mypy_success
    ensure
      temp_file.close
    end
  end

  def run_flake8(temp_file_path, original_file, start_line, block_number)
    cmd = ['flake8'] + FLAKE8_CONFIG + [temp_file_path]
    result = run_command(cmd)

    if result[:success]
      puts '    ✓ flake8 passed' if @verbose
      true
    else
      parse_flake8_errors(result[:output], original_file, start_line, block_number)
      false
    end
  end

  def run_mypy(temp_file_path, original_file, start_line, block_number)
    cmd = ['mypy'] + MYPY_CONFIG + [temp_file_path]
    result = run_command(cmd)

    if result[:success]
      puts '    ✓ mypy passed' if @verbose
      true
    else
      parse_mypy_errors(result[:output], original_file, start_line, block_number)
      false
    end
  end

  def run_command(cmd)
    output = `#{cmd.join(' ')} 2>&1`
    success = $?.success?
    { success: success, output: output }
  end

  def parse_flake8_errors(output, original_file, start_line, block_number)
    output.lines.each do |line|
      next unless line.match(/^.+:(\d+):(\d+):\s*(.+)$/)

      error_line = ::Regexp.last_match(1).to_i
      column = ::Regexp.last_match(2).to_i
      message = ::Regexp.last_match(3).strip
      actual_line = start_line + error_line - 1
      add_error(original_file, actual_line, "flake8 (block #{block_number}): #{message}", column)
    end
  end

  def parse_mypy_errors(output, original_file, start_line, block_number)
    output.lines.each do |line|
      if line.match(/^.+:(\d+):(\d+):\s*(.+):\s*(.+)$/)
        error_line = ::Regexp.last_match(1).to_i
        column = ::Regexp.last_match(2).to_i
        severity = ::Regexp.last_match(3).strip
        message = ::Regexp.last_match(4).strip
        actual_line = start_line + error_line - 1
        add_error(original_file, actual_line, "mypy (block #{block_number}) #{severity}: #{message}", column)
      elsif line.match(/^.+:(\d+):\s*(.+):\s*(.+)$/)
        error_line = ::Regexp.last_match(1).to_i
        severity = ::Regexp.last_match(2).strip
        message = ::Regexp.last_match(3).strip
        actual_line = start_line + error_line - 1
        add_error(original_file, actual_line, "mypy (block #{block_number}) #{severity}: #{message}")
      end
    end
  end

  def add_error(file, line, message, column = nil)
    # Determine error type from message
    error_type = case message
                 when /flake8/
                   'python_lint_error'
                 when /mypy/
                   'python_type_error'
                 else
                   'python_validation_error'
                 end

    # Structured error tracking
    @error_collector.add_error(
      file: file,
      line: line,
      field: column ? "column_#{column}" : nil,
      type: error_type,
      message: message,
      suggestion: generate_suggestion(message)
    )

    # Record error pattern for metrics
    @metrics_collector.record_error_pattern(
      error_type: error_type,
      component: 'python_code_validator',
      context: { file: file, line: line, column: column }
    )
  end

  def report_errors
    return unless @error_collector.any?

    puts "\n❌ Python code validation errors found:"
    @error_collector.errors.each do |error|
      location = "#{error[:file]}:#{error[:line]}"
      location += ":#{error[:field]}" if error[:field]
      puts "  #{location}: #{error[:message]}"
      puts "    💡 #{error[:suggestion]}" if error[:suggestion]
    end
    puts "\nTotal errors: #{@error_collector.count}"

    # Log structured completion summary
    @error_collector.log_validation_summary
    @metrics_collector.log_completion_summary

    # Save metrics
    begin
      metrics_file = @metrics_collector.save_metrics
      puts "📊 Metrics saved to #{metrics_file}" if @verbose
    rescue StandardError => e
      puts "⚠️ Failed to save metrics: #{e.message}" if @verbose
    end
  end

  def cleanup
    @temp_files.each(&:unlink)
  end

  def has_errors?
    @error_collector.any?
  end

  def log_structured_start
    return unless ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'

    begin
      start_log = {
        event: 'validation_start',
        correlation_id: @metrics_collector.correlation_id,
        timestamp: Time.now.iso8601,
        tool: 'validate_python_examples',
        python_dir: PYTHON_DIR
      }
      warn JSON.generate(start_log)
    rescue StandardError => e
      warn "Warning: Structured logging failed: #{e.message}"
    end
  end

  def generate_suggestion(message)
    case message
    when /line too long/
      'Consider breaking long lines or using a line formatter like Black'
    when /undefined name/
      'Check variable names and imports'
    when /imported but unused/
      "Remove unused import or add '# noqa: F401' if intentionally unused"
    when /missing whitespace/
      'Add proper whitespace around operators'
    when /type.*error/i
      'Review type annotations and ensure correct types are used'
    when /syntax error/i
      'Check Python syntax - missing colons, brackets, or indentation'
    else
      'Review Python code formatting and syntax'
    end
  end
end

# Check if required tools are available
def check_dependencies
  tools = %w[flake8 mypy python3]
  missing = []

  tools.each do |tool|
    missing << tool unless system("which #{tool} > /dev/null 2>&1")
  end

  unless missing.empty?
    puts "❌ Missing required tools: #{missing.join(', ')}"
    puts 'Please install them using:'
    puts '  pip install flake8 mypy'
    return false
  end

  true
end

# Main execution
if __FILE__ == $0
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on('-f', '--file FILE', 'Validate specific file') do |file|
      options[:file] = file
    end

    opts.on('-v', '--verbose', 'Verbose output') do
      options[:verbose] = true
    end

    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit 0
    end
  end.parse!

  # Check dependencies
  exit 1 unless check_dependencies

  validator = PythonCodeValidator.new(verbose: options[:verbose])

  begin
    success = if options[:file]
                validator.validate_file(options[:file])
              else
                validator.validate_all_files
              end

    validator.report_errors

    if success && !validator.has_errors?
      puts '✅ All Python code examples are valid' unless options[:file] && !options[:verbose]
      exit 0
    else
      exit 1
    end
  ensure
    validator.cleanup
  end
end
