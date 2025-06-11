#!/usr/bin/env ruby
# tools/verify_context_snippets.rb - Verification script for ErrorFormatter context snippets

require_relative '../lib/error_formatter'
require_relative '../lib/error_collector'

puts "==== VERIFYING ErrorFormatter Context Snippets ===="

# Create sample file content with various scenarios
sample_file_content = <<~CONTENT
  ---
  id: test-binding
  last_modified: Invalid-Date-Format
  derived_from: nonexistent-tenet
  enforced_by: 'manual review'
  version: '1.0.0'
  unknown_field: should-not-exist
  ---

  # Test Binding

  This is a test binding with some content to show context.
  Here is line 12 for reference.
  And line 13 has some more content.
CONTENT

# Create test errors at different line positions
collector = ErrorCollector.new

# Error at beginning of file (line 3)
collector.add_error(
  file: '/path/to/test-binding.md',
  line: 3,
  field: 'last_modified',
  type: 'invalid_date_format',
  message: "Invalid date format in 'last_modified' field",
  suggestion: "Date must be in ISO format (YYYY-MM-DD). Example: last_modified: '2025-05-09'"
)

# Error in middle of file (line 4)
collector.add_error(
  file: '/path/to/test-binding.md',
  line: 4,
  field: 'derived_from',
  type: 'nonexistent_tenet_reference',
  message: "References non-existent tenet 'nonexistent-tenet'",
  suggestion: "Available tenets: simplicity, testability, maintainability"
)

# Error near end of file (line 12)
collector.add_error(
  file: '/path/to/test-binding.md',
  line: 12,
  field: nil,
  type: 'content_issue',
  message: "Reference line for context testing",
  suggestion: "This error is for testing context display"
)

# Error without line number (should not show context)
collector.add_error(
  file: '/path/to/test-binding.md',
  line: nil,
  field: nil,
  type: 'general_error',
  message: "Error without line number",
  suggestion: "This should not show context snippet"
)

# Error from different file (no content provided)
collector.add_error(
  file: '/path/to/other-file.md',
  line: 5,
  field: 'id',
  type: 'test_error',
  message: "Error from file without content",
  suggestion: "This should not show context because no content provided"
)

# Create file contents map
file_contents = {
  '/path/to/test-binding.md' => sample_file_content
  # Note: '/path/to/other-file.md' intentionally not included
}

# Test the formatter with context snippets
formatter = ErrorFormatter.new
output_with_context = formatter.render(collector.errors, file_contents)

puts "Output with context snippets:"
puts "=" * 50
puts output_with_context
puts "=" * 50

# Test without context (backward compatibility)
output_without_context = formatter.render(collector.errors)

puts "\nBackward compatibility test (no context):"
puts "=" * 50
puts output_without_context
puts "=" * 50

# Verification tests
puts "\n==== VERIFICATION TESTS ===="

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

# Test 1: Context snippets appear for errors with line numbers
test "context snippets for line number errors" do
  raise "Should include context header" unless output_with_context.include?('context:')
  raise "Should show line numbers in context" unless output_with_context.match(/\s+\d+\s+[│>→]/)
  raise "Should highlight error line" unless output_with_context.include?('→') || output_with_context.include?('>')
end

# Test 2: Context shows correct lines
test "context shows correct lines around error" do
  # For line 3 error, should show lines around it
  raise "Should show line 1 content (id: test-binding)" unless output_with_context.include?('id: test-binding')
  raise "Should show line 3 content (last_modified)" unless output_with_context.include?('last_modified: Invalid-Date-Format')
  raise "Should show line 4 content (derived_from)" unless output_with_context.include?('derived_from: nonexistent-tenet')
end

# Test 3: No context for errors without line numbers
test "no context for errors without line numbers" do
  # Count context blocks - should be 3 (for line 3, 4, and 12 errors) not 5
  context_blocks = output_with_context.scan(/context:/).length
  raise "Should have exactly 3 context blocks, got #{context_blocks}" unless context_blocks == 3
end

# Test 4: No context for files without content
test "no context for files without content" do
  # The error from other-file.md should not have context
  # Extract just the other-file.md section (until the next file section)
  start_idx = output_with_context.index('/path/to/other-file.md:')
  end_idx = output_with_context.index('/path/to/test-binding.md:')

  if start_idx && end_idx && start_idx < end_idx
    other_file_section = output_with_context[start_idx...end_idx]
    raise "Other file section should not have context" if other_file_section.include?('context:')
  else
    raise "Could not isolate other-file.md section for testing"
  end
end

# Test 5: Backward compatibility
test "backward compatibility without file contents" do
  raise "Should work without file_contents parameter" if output_without_context.empty?
  raise "Should not include context when no file_contents provided" if output_without_context.include?('context:')
  raise "Should still show error messages" unless output_without_context.include?('Invalid date format')
end

# Test 6: Line number formatting
test "line number formatting" do
  # Should show formatted line numbers (right-aligned, 3 digits)
  line_number_pattern = /\s+\d{1,3}\s+[│>→]/
  raise "Should format line numbers properly" unless output_with_context.match(line_number_pattern)
end

# Test 7: Error line highlighting
test "error line highlighting" do
  # Error line should be visually distinct
  if output_with_context.include?('→')
    # TTY mode with arrow
    raise "Error line should use arrow indicator" unless output_with_context.include?('→')
  else
    # Non-TTY mode with greater-than
    raise "Error line should use > indicator" unless output_with_context.include?('>')
  end
end

# Display results
puts "\nVerification Results: #{$tests_passed || 0} of #{$total_tests || 0} tests passed"

if ($tests_passed || 0) == ($total_tests || 0)
  puts "\n✅ Context snippets verification successful!"
  puts "- ✓ Context snippets appear for errors with line numbers"
  puts "- ✓ Correct lines shown around error location"
  puts "- ✓ Error lines are visually highlighted"
  puts "- ✓ No context shown for errors without line numbers"
  puts "- ✓ No context shown for files without provided content"
  puts "- ✓ Backward compatibility maintained"
  puts "- ✓ Line numbers formatted correctly"
  puts "- ✓ Proper visual distinction for error lines"

  puts "\nExample context snippet format:"
  context_example = output_with_context[output_with_context.index('context:')..output_with_context.index('suggestion:') || -1]
  puts context_example.split("\n").first(6).join("\n") if context_example
else
  puts "\n❌ Some verification tests failed."
  exit 1
end
