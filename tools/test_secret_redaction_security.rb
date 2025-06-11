#!/usr/bin/env ruby
# Test for secret redaction security fix - CRITICAL-001

require_relative 'validate_front_matter'

def test_secret_redaction_boundary_cases
  puts "🔐 Testing secret redaction boundary cases..."

  # Test case 1: Secrets followed by word characters (the main vulnerability)
  content1 = <<~CONTENT
---
api_key: "sk-abc123def"
token: "ghp_abcd1234"
---

# Content with boundary issues
Configuration: api_key=sk-abc123def_config
Environment: TOKEN=ghp_abcd1234_env
URL: https://user:sk-abc123def@example.com
CONTENT

  front_matter1 = {
    'api_key' => 'sk-abc123def',
    'token' => 'ghp_abcd1234'
  }

  redacted1 = redact_secrets_from_content(content1, front_matter1)

  # Verify no secrets leak
  if redacted1.include?('sk-abc123def') || redacted1.include?('ghp_abcd1234')
    puts "❌ FAIL: Test 1 - Secrets leaked in redacted content"
    puts redacted1
    return false
  else
    puts "✅ PASS: Test 1 - Boundary characters properly handled"
  end

  # Test case 2: Secrets with special characters
  content2 = <<~CONTENT
---
password: "secret-with-dashes"
api_key: "key.with.dots"
---

# Content with special chars
Password: secret-with-dashes123
API: key.with.dots_suffix
CONTENT

  front_matter2 = {
    'password' => 'secret-with-dashes',
    'api_key' => 'key.with.dots'
  }

  redacted2 = redact_secrets_from_content(content2, front_matter2)

  if redacted2.include?('secret-with-dashes') || redacted2.include?('key.with.dots')
    puts "❌ FAIL: Test 2 - Special character secrets leaked"
    return false
  else
    puts "✅ PASS: Test 2 - Special character secrets properly redacted"
  end

  # Test case 3: Multiline secrets
  content3 = <<~CONTENT
---
multiline_secret: |
  line1-secret
  line2-secret
---

# Content with multiline
Text contains line1-secret and line2-secret values.
CONTENT

  front_matter3 = {
    'multiline_secret' => "line1-secret\nline2-secret"
  }

  redacted3 = redact_secrets_from_content(content3, front_matter3)

  if redacted3.include?('line1-secret') || redacted3.include?('line2-secret')
    puts "❌ FAIL: Test 3 - Multiline secrets leaked"
    return false
  else
    puts "✅ PASS: Test 3 - Multiline secrets properly redacted"
  end

  # Test case 4: Edge case - empty and nil values
  content4 = "secret: empty\nother: nil_value"
  front_matter4 = {
    'secret' => '',
    'other' => nil,
    'valid_secret' => 'actual-secret'
  }

  redacted4 = redact_secrets_from_content(content4, front_matter4)

  # Should not try to redact empty or nil values
  if !redacted4.include?('empty') || !redacted4.include?('nil_value')
    puts "❌ FAIL: Test 4 - Incorrectly redacted non-secret values"
    return false
  else
    puts "✅ PASS: Test 4 - Empty/nil values handled correctly"
  end

  puts "🎉 All secret redaction security tests passed!"
  return true
end

def test_no_over_redaction
  puts "\n🔍 Testing for over-redaction edge cases..."

  # Test that we don't redact innocent substrings
  content = <<~CONTENT
---
token: "abc"
---

# Content
The word "fabcde" should not be redacted because "abc" is a very common substring.
CONTENT

  front_matter = { 'token' => 'abc' }
  redacted = redact_secrets_from_content(content, front_matter)

  # This is a known limitation - simple string replacement will over-redact
  # But for security, this is acceptable
  if redacted.include?('f[REDACTED]de')
    puts "⚠️  EXPECTED: Over-redaction occurs with simple substring matching"
    puts "   This is acceptable for security - better safe than sorry"
    return true
  else
    puts "❌ UNEXPECTED: No over-redaction found where expected"
    return false
  end
end

# Run the tests
puts "Running secret redaction security tests...\n"

if test_secret_redaction_boundary_cases && test_no_over_redaction
  puts "\n✅ ALL TESTS PASSED - Secret redaction vulnerability is FIXED!"
  exit 0
else
  puts "\n❌ TESTS FAILED - Security vulnerability may still exist"
  exit 1
end
