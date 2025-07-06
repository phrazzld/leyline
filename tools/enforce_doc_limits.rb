#!/usr/bin/env ruby

require 'yaml'

class DocLimitEnforcer
  LIMITS = {
    'tenets' => { warn: 100, fail: 150 },
    'bindings' => { warn: 200, fail: 300 }
  }.freeze

  def initialize(verbose: false)
    @verbose = verbose
    @violations = []
    @warnings = []
  end

  def check_all
    tenet_files = Dir.glob('docs/tenets/*.md')
    binding_files = Dir.glob('docs/bindings/**/*.md')

    check_files(tenet_files, 'tenets')
    check_files(binding_files, 'bindings')

    report_results
  end

  def check_file(file_path)
    type = file_path.include?('tenets') ? 'tenets' : 'bindings'
    lines = count_content_lines(file_path)
    limits = LIMITS[type]

    if lines > limits[:fail]
      @violations << { file: file_path, lines: lines, limit: limits[:fail], type: type }
    elsif lines > limits[:warn]
      @warnings << { file: file_path, lines: lines, limit: limits[:warn], type: type }
    elsif @verbose
      puts "✓ #{file_path}: #{lines} lines (OK)"
    end
  end

  private

  def check_files(files, type)
    puts "\nChecking #{type}..." if @verbose
    files.each { |file| check_file(file) }
  end

  def count_content_lines(file_path)
    content = File.read(file_path)

    # Skip YAML front matter
    content = content.split('---', 3)[2] || '' if content.start_with?('---')

    # Count non-empty lines
    content.lines.reject { |line| line.strip.empty? }.count
  end

  def report_results
    if @violations.empty? && @warnings.empty?
      puts '✅ All documents within limits!' unless @verbose
      exit 0
    end

    if @warnings.any?
      puts "\n⚠️  Warnings (approaching limits):"
      @warnings.each do |w|
        puts "  #{w[:file]}: #{w[:lines]} lines (warn at #{w[:limit]})"
      end
    end

    return unless @violations.any?

    puts "\n❌ Violations (exceeding limits):"
    @violations.each do |v|
      puts "  #{v[:file]}: #{v[:lines]} lines (limit: #{v[:limit]})"
    end

    puts "\nSummary:"
    puts "  #{@violations.count} files exceed limits"
    puts "  #{@warnings.count} files approaching limits"

    exit 1
  end
end

# CLI handling
if __FILE__ == $0
  require 'optparse'

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] [file]"

    opts.on('-v', '--verbose', 'Show all files checked') do
      options[:verbose] = true
    end

    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit
    end
  end.parse!

  enforcer = DocLimitEnforcer.new(verbose: options[:verbose])

  if ARGV.empty?
    enforcer.check_all
  else
    ARGV.each { |file| enforcer.check_file(file) }
  end
end
