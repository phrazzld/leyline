#!/usr/bin/env ruby
# frozen_string_literal: true

# Windows Platform Diagnostic Script
# Investigates bundler platform compatibility issues for Windows CI
puts "=== Windows Platform Diagnostic ==="
puts "Date: #{Time.now}"
puts

# 1. Ruby Platform Detection
puts "1. RUBY PLATFORM INFORMATION"
puts "RUBY_PLATFORM: #{RUBY_PLATFORM}"
puts "RUBY_VERSION: #{RUBY_VERSION}"
puts "RUBY_ENGINE: #{RUBY_ENGINE}"
puts "RUBY_ENGINE_VERSION: #{RUBY_ENGINE_VERSION}"
puts

# 2. Bundler Platform Information
require 'bundler'
puts "2. BUNDLER PLATFORM INFORMATION"
begin
  # Try different methods to get platform info
  puts "Gem.platforms: #{Gem.platforms.inspect}"
  puts "Gem::Platform.local: #{Gem::Platform.local.inspect}"
  puts "RbConfig::CONFIG['target']: #{RbConfig::CONFIG['target']}"
  puts "RbConfig::CONFIG['arch']: #{RbConfig::CONFIG['arch']}"
rescue => e
  puts "Error getting platform info: #{e.message}"
end
puts

# 3. Gemfile.lock Platform Analysis
puts "3. GEMFILE.LOCK PLATFORM ANALYSIS"
lockfile_path = File.join(__dir__, 'Gemfile.lock')
if File.exist?(lockfile_path)
  lockfile_content = File.read(lockfile_path)
  platforms_section = lockfile_content[/PLATFORMS\n(.*?)\n\n/m, 1]
  if platforms_section
    platforms = platforms_section.strip.split("\n").map(&:strip)
    puts "Declared platforms in Gemfile.lock:"
    platforms.each { |platform| puts "  - #{platform}" }

    # Check for Windows platform compatibility
    windows_platforms = platforms.select { |p| p.include?('mingw') || p.include?('mswin') }
    puts "Windows-specific platforms: #{windows_platforms.inspect}"

    # Platform matching analysis
    current_platform = RUBY_PLATFORM
    exact_match = platforms.include?(current_platform)
    puts "Current platform (#{current_platform}) exact match: #{exact_match}"

    # Check for universal platform fallbacks
    universal_match = platforms.any? { |p| p.include?('universal') }
    puts "Universal platform fallback available: #{universal_match}"
  else
    puts "No PLATFORMS section found in Gemfile.lock"
  end
else
  puts "Gemfile.lock not found at #{lockfile_path}"
end
puts

# 4. Gem Compatibility Analysis
puts "4. GEM COMPATIBILITY ANALYSIS"
gemfile_path = File.join(__dir__, 'Gemfile')
if File.exist?(gemfile_path)
  gemfile_content = File.read(gemfile_path)

  # Extract gem dependencies
  gems = gemfile_content.scan(/gem ['"]([^'"]+)['"]/).flatten
  puts "Gems in Gemfile: #{gems.inspect}"

  # Check problematic gems for Windows
  problematic_gems = ['lz4-ruby'] # Known to have Windows native extension issues
  windows_problematic = gems & problematic_gems
  if windows_problematic.any?
    puts "Potentially problematic gems for Windows: #{windows_problematic.inspect}"
    puts "These gems may require native compilation or specific Windows binaries"
  end
else
  puts "Gemfile not found at #{gemfile_path}"
end
puts

# 5. Bundler Configuration
puts "5. BUNDLER CONFIGURATION"
begin
  config = Bundler.settings.all
  relevant_settings = config.select { |k, v| k.to_s.match?(/platform|deployment|path|without/) }
  if relevant_settings.any?
    puts "Relevant bundler settings:"
    relevant_settings.each { |k, v| puts "  #{k}: #{v}" }
  else
    puts "No relevant bundler settings found"
  end
rescue => e
  puts "Error reading bundler settings: #{e.message}"
end
puts

# 6. Platform Compatibility Recommendations
puts "6. PLATFORM COMPATIBILITY RECOMMENDATIONS"
puts

current_platform = RUBY_PLATFORM
case current_platform
when /x64-mingw-ucrt/
  puts "⚠️  DETECTED: Ruby 3.1+ with x64-mingw-ucrt platform"
  puts "📋 RECOMMENDATION: Update Gemfile.lock to include x64-mingw-ucrt"
  puts "🔧 COMMAND: bundle lock --add-platform x64-mingw-ucrt"
  puts "💡 ALTERNATIVE: Use universal-mingw32 for broader compatibility"
when /x64-mingw/
  puts "✅ DETECTED: Standard x64-mingw platform"
  puts "📋 RECOMMENDATION: Current x64-mingw32 declaration should work"
  puts "🔧 VERIFY: Check if lz4-ruby has Windows binaries for this platform"
when /mingw/
  puts "ℹ️  DETECTED: MinGW platform variant"
  puts "📋 RECOMMENDATION: Verify exact platform string matches Gemfile.lock"
else
  puts "ℹ️  DETECTED: Non-Windows platform (#{current_platform})"
  puts "📋 RECOMMENDATION: This diagnostic is for Windows issues only"
end
puts

# 7. Next Steps
puts "7. NEXT STEPS FOR CI RESOLUTION"
puts "1. Run this script on Windows CI to get actual platform information"
puts "2. Compare Windows CI platform with Gemfile.lock declarations"
puts "3. Update platform declarations based on findings"
puts "4. Test bundler install with corrected platforms"
puts "5. Implement strategy matrix isolation to prevent cancellation"
puts

puts "=== End Diagnostic ==="
