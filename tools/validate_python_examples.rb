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

# Configuration
PYTHON_DIR = 'docs/bindings/categories/python'
FLAKE8_CONFIG = [
  '--max-line-length=88',
  '--extend-ignore=E203,W503',  # Compatible with black formatter
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
    @errors = []
    @temp_files = []
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
    unless File.exist?(file_path)
      add_error(file_path, 0, "File not found")
      return false
    end

    puts "Validating #{file_path}..." if @verbose

    content = File.read(file_path)
    code_blocks = extract_python_code_blocks(content, file_path)

    if code_blocks.empty?
      puts "  No Python code blocks found" if @verbose
      return true
    end

    puts "  Found #{code_blocks.length} Python code block(s)" if @verbose

    success = true
    code_blocks.each_with_index do |block, index|
      success = validate_code_block(block, file_path, index + 1) && success
    end

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
        if !current_block.empty?
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
    if in_python_block && !current_block.empty?
      add_error(file_path, block_start_line, "Unclosed Python code block")
    end

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
      puts "    ✓ flake8 passed" if @verbose
      return true
    else
      parse_flake8_errors(result[:output], original_file, start_line, block_number)
      return false
    end
  end

  def run_mypy(temp_file_path, original_file, start_line, block_number)
    cmd = ['mypy'] + MYPY_CONFIG + [temp_file_path]
    result = run_command(cmd)

    if result[:success]
      puts "    ✓ mypy passed" if @verbose
      return true
    else
      parse_mypy_errors(result[:output], original_file, start_line, block_number)
      return false
    end
  end

  def run_command(cmd)
    output = `#{cmd.join(' ')} 2>&1`
    success = $?.success?
    { success: success, output: output }
  end

  def parse_flake8_errors(output, original_file, start_line, block_number)
    output.lines.each do |line|
      if line.match(/^.+:(\d+):(\d+):\s*(.+)$/)
        error_line = $1.to_i
        column = $2.to_i
        message = $3.strip
        actual_line = start_line + error_line - 1
        add_error(original_file, actual_line, "flake8 (block #{block_number}): #{message}", column)
      end
    end
  end

  def parse_mypy_errors(output, original_file, start_line, block_number)
    output.lines.each do |line|
      if line.match(/^.+:(\d+):(\d+):\s*(.+):\s*(.+)$/)
        error_line = $1.to_i
        column = $2.to_i
        severity = $3.strip
        message = $4.strip
        actual_line = start_line + error_line - 1
        add_error(original_file, actual_line, "mypy (block #{block_number}) #{severity}: #{message}", column)
      elsif line.match(/^.+:(\d+):\s*(.+):\s*(.+)$/)
        error_line = $1.to_i
        severity = $2.strip
        message = $3.strip
        actual_line = start_line + error_line - 1
        add_error(original_file, actual_line, "mypy (block #{block_number}) #{severity}: #{message}")
      end
    end
  end

  def add_error(file, line, message, column = nil)
    error = { file: file, line: line, message: message }
    error[:column] = column if column
    @errors << error
  end

  def report_errors
    return if @errors.empty?

    puts "\n❌ Python code validation errors found:"
    @errors.each do |error|
      location = "#{error[:file]}:#{error[:line]}"
      location += ":#{error[:column]}" if error[:column]
      puts "  #{location}: #{error[:message]}"
    end
    puts "\nTotal errors: #{@errors.length}"
  end

  def cleanup
    @temp_files.each(&:unlink)
  end

  def has_errors?
    !@errors.empty?
  end
end

# Check if required tools are available
def check_dependencies
  tools = %w[flake8 mypy python3]
  missing = []

  tools.each do |tool|
    unless system("which #{tool} > /dev/null 2>&1")
      missing << tool
    end
  end

  unless missing.empty?
    puts "❌ Missing required tools: #{missing.join(', ')}"
    puts "Please install them using:"
    puts "  pip install flake8 mypy"
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
      puts "✅ All Python code examples are valid" unless options[:file] && !options[:verbose]
      exit 0
    else
      exit 1
    end
  ensure
    validator.cleanup
  end
end
