---
derived_from: empathize-with-your-user
enforced_by: user testing & review
id: ruby-cli-tools
last_modified: '2025-07-01'
version: '0.1.0'
---
# Binding: Ruby CLI Tools

Build user-friendly command-line tools using Thor framework and Ruby conventions.

## Rules

- **Thor framework** for command structure and help generation
- **Progressive disclosure** - simple commands with optional complexity
- **Rich help text** with examples and usage patterns
- **Input validation** with clear error messages
- **Exit codes** following Unix conventions (0=success, 1=error)

## Examples

```ruby
# ✅ GOOD: Thor-based CLI
class MyCLI < Thor
  desc "deploy ENV", "Deploy application to specified environment"
  long_desc <<~DESC
    Deploy the application to the specified environment.

    Examples:
      mycli deploy staging
      mycli deploy production --dry-run
  DESC

  option :dry_run, type: :boolean, default: false, desc: "Show what would be deployed"
  option :verbose, type: :boolean, aliases: '-v', desc: "Show detailed output"

  def deploy(environment)
    unless %w[staging production].include?(environment)
      say "Error: Environment must be 'staging' or 'production'", :red
      exit 1
    end

    if options[:dry_run]
      say "Would deploy to #{environment}", :yellow
    else
      say "Deploying to #{environment}...", :green
      # Deployment logic
    end
  end

  desc "version", "Show version information"
  def version
    say "MyApp v#{MyApp::VERSION}"
  end
end

# Entry point
#!/usr/bin/env ruby
require_relative '../lib/myapp'

begin
  MyCLI.start(ARGV)
rescue StandardError => e
  puts "Error: #{e.message}"
  exit 1
end
```

```ruby
# ✅ GOOD: Input validation and user feedback
class FileProcessor < Thor
  desc "process FILE", "Process the specified file"

  def process(file_path)
    unless File.exist?(file_path)
      say "Error: File '#{file_path}' not found", :red
      exit 1
    end

    unless File.readable?(file_path)
      say "Error: Cannot read file '#{file_path}'", :red
      exit 1
    end

    say "Processing #{file_path}...", :blue

    begin
      result = ProcessingService.new(file_path).call
      say "✓ Processing completed successfully", :green
      say "  Processed #{result.count} items"
    rescue ProcessingError => e
      say "✗ Processing failed: #{e.message}", :red
      exit 1
    end
  end
end
```

```ruby
# ❌ BAD: Poor CLI design
class BadCLI
  def self.run(args)
    # No help text, unclear commands
    case args[0]
    when 'd'  # Cryptic command
      deploy(args[1], args[2] == 'true')  # Unclear boolean
    when 'v'
      puts VERSION  # No context
    else
      puts "Unknown command"  # No help
    end
  end

  def self.deploy(env, dry)
    # No validation
    puts "Deploying to #{env}"
    # No error handling
  end
end

# No structured argument parsing
ARGV.each { |arg| puts arg }  # Raw argument dumping
```

```bash
# ✅ GOOD: Rich help output
$ mycli help deploy
Usage:
  mycli deploy ENV

Options:
  [--dry-run], [--no-dry-run]  # Show what would be deployed
  -v, [--verbose], [--no-verbose]  # Show detailed output

Deploy application to specified environment

Examples:
  mycli deploy staging
  mycli deploy production --dry-run
```
