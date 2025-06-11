#!/usr/bin/env ruby
# tools/verify_error_formatter.rb - Verification script for ErrorFormatter TTY and color support

require_relative '../lib/error_formatter'
require_relative '../lib/error_collector'

puts "==== VERIFYING ErrorFormatter ===="

# Create test errors to demonstrate formatting
collector = ErrorCollector.new

collector.add_error(
  file: '/path/to/docs/tenets/simplicity.md',
  line: 5,
  field: 'id',
  type: 'invalid_id_format',
  message: "Invalid ID format 'Simplicity-Tenet' in YAML front-matter",
  suggestion: "ID contains uppercase letters. Use lowercase: id: simplicity-tenet"
)

collector.add_error(
  file: '/path/to/docs/tenets/simplicity.md',
  line: 7,
  field: 'last_modified',
  type: 'invalid_date_format',
  message: "Invalid date format in 'last_modified' field",
  suggestion: "Date must be in ISO format (YYYY-MM-DD) and enclosed in quotes. Example: last_modified: '2025-05-09'"
)

collector.add_error(
  file: '/path/to/docs/bindings/core/api-design.md',
  line: 12,
  field: 'derived_from',
  type: 'nonexistent_tenet_reference',
  message: "References non-existent tenet 'unknown-tenet'",
  suggestion: "Tenet 'unknown-tenet' does not exist. Available tenets:\n  simplicity\n  testability\n  maintainability"
)

collector.add_error(
  file: '/path/to/docs/bindings/core/api-design.md',
  line: nil,
  field: nil,
  type: 'missing_required_fields',
  message: "Missing required keys in YAML front-matter: enforced_by",
  suggestion: "Add missing field(s) to your front-matter:\n  enforced_by: 'Linter, Code Review'"
)

# Create formatter and render output (test both with and without file content)
formatter = ErrorFormatter.new
output = formatter.render(collector.errors)

# Also test with file content for context snippets
test_file_content = <<~CONTENT
  ---
  id: test-binding
  last_modified: '2025-05-10'

  derived_from: test-tenet
  enforced_by: 'manual review'
  ---

  # Test Content
  This is line 9
  More content on line 10
CONTENT

file_contents = {
  '/path/to/docs/tenets/simplicity.md' => test_file_content,
  '/path/to/docs/bindings/core/api-design.md' => test_file_content
}

output_with_context = formatter.render(collector.errors, file_contents)

puts "TTY Status: #{STDOUT.tty? ? 'Yes (colors enabled)' : 'No (plain text)'}"
puts "NO_COLOR env: #{ENV['NO_COLOR'] ? "'#{ENV['NO_COLOR']}'" : 'not set'}"
puts

# Display the formatted output
puts output

puts "\n==== VERIFICATION TESTS ===="

# Basic functionality tests
tests_passed = 0
total_tests = 0

def test(description)
  total_tests = $total_tests ||= 0
  tests_passed = $tests_passed ||= 0

  $total_tests += 1
  print "Testing #{description}... "

  begin
    yield
    puts "✓ PASS"
    $tests_passed += 1
  rescue => e
    puts "✗ FAIL: #{e.message}"
  end
end

# Test 1: Basic render functionality
test "basic render functionality" do
  raise "Output should not be empty" if output.empty?
  raise "Output should contain file paths" unless output.include?('/path/to/docs/')
  raise "Output should contain error messages" unless output.include?('Invalid ID format')
end

# Test 2: File grouping
test "file grouping" do
  lines = output.split("\n")
  simplicity_line = lines.find { |line| line.include?('simplicity.md:') }
  api_design_line = lines.find { |line| line.include?('api-design.md:') }

  raise "Should group errors by file - missing simplicity.md section" unless simplicity_line
  raise "Should group errors by file - missing api-design.md section" unless api_design_line
end

# Test 3: TTY detection behavior
test "TTY detection behavior" do
  # Create formatters to test different conditions

  # Test with forced TTY
  original_stdout = STDOUT
  tty_formatter = ErrorFormatter.new

  # The behavior should match current TTY status
  has_colors = STDOUT.tty? && (ENV['NO_COLOR'].nil? || ENV['NO_COLOR'].empty?)

  if has_colors
    raise "Should use colors in TTY" unless output.include?("\e[")
  else
    raise "Should not use colors in non-TTY or NO_COLOR" if output.include?("\e[")
  end
end

# Test 4: Error structure preservation
test "error structure preservation" do
  raise "Should preserve line numbers" unless output.include?('line 5') || output.include?('line 7')
  raise "Should preserve field names" unless output.include?("field 'id'") || output.include?("field 'last_modified'")
  raise "Should preserve suggestions" unless output.include?('suggestion:')
end

# Test 5: Multi-line suggestion handling
test "multi-line suggestion handling" do
  # Check that multi-line suggestions are properly indented
  suggestion_section = output[output.index('Available tenets:')..output.index('enforced_by') || -1]
  raise "Multi-line suggestions should be properly indented" unless suggestion_section.include?('  simplicity')
end

# Test 6: Context snippets functionality
test "context snippets functionality" do
  # Verify context snippets appear when file content is provided
  raise "Should include context when file content provided" unless output_with_context.include?('context:')
  raise "Should show line numbers in context" unless output_with_context.match(/\s+\d+\s+[│>→]/)

  # Verify backward compatibility - no context when file content not provided
  raise "Should not include context when no file content" if output.include?('context:')
end

# Display results
puts "\nVerification Results: #{$tests_passed || 0} of #{$total_tests || 0} tests passed"

if ($tests_passed || 0) == ($total_tests || 0)
  puts "\n✅ ErrorFormatter verification successful!"
  puts "- ✓ Renders errors with proper formatting"
  puts "- ✓ Groups errors by filename correctly"
  puts "- ✓ Handles TTY detection properly"
  puts "- ✓ Preserves all error context (line, field, suggestion)"
  puts "- ✓ Formats multi-line suggestions correctly"
  puts "- ✓ Shows context snippets when file content provided"
  puts "- ✓ Maintains backward compatibility without file content"
  puts "\nTo test color behavior:"
  puts "  # TTY with colors (if supported):"
  puts "  ruby tools/verify_error_formatter.rb"
  puts "  # Non-TTY plain text:"
  puts "  ruby tools/verify_error_formatter.rb | cat"
  puts "  # Disabled colors:"
  puts "  NO_COLOR=1 ruby tools/verify_error_formatter.rb"
else
  puts "\n❌ Some verification tests failed."
  exit 1
end
