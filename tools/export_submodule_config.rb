#!/usr/bin/env ruby
# export_submodule_config.rb - Export git submodule configuration to direct copy format
#
# This tool converts a git submodule Leyline configuration into a direct copy
# selection configuration, facilitating migration between integration methods.

require 'yaml'
require 'optparse'

# Configuration and options
$options = {
  output_file: '.leyline-selection.yml',
  verbose: false
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: export_submodule_config.rb [options]"

  opts.on("-o", "--output FILE", "Output selection config file path") do |file|
    $options[:output_file] = file
  end

  opts.on("--verbose", "Verbose output") do
    $options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit 0
  end
end.parse!

def log_info(message)
  puts "[INFO] #{message}"
end

def log_verbose(message)
  puts "[VERBOSE] #{message}" if $options[:verbose]
end

def log_error(message)
  puts "[ERROR] #{message}"
end

def main
  config_file = 'leyline-config.yml'

  unless File.exist?(config_file)
    log_error("Submodule config file not found: #{config_file}")
    exit 1
  end

  log_info("Exporting submodule configuration to direct copy format")

  # Load submodule configuration
  submodule_config = YAML.load_file(config_file)
  log_verbose("Loaded submodule configuration")

  # Convert to direct copy selection format
  selection_config = {
    'leyline_version' => "v#{submodule_config['leyline_version'] || '0.1.5'}",
    'output_directory' => 'docs/standards',
    'tenets' => submodule_config['tenets'] || [],
    'binding_categories' => submodule_config['binding_categories'] || ['core'],
    'excluded_bindings' => submodule_config['excluded_bindings'] || [],
    'customization' => {
      'add_project_context' => true,
      'content_transforms' => {
        'add_implementation_notes' => true
      }
    },
    'tracking' => {
      'track_versions' => true,
      'track_checksums' => true,
      'track_sources' => true
    },
    'output' => {
      'create_index' => true
    }
  }

  # Add migration metadata
  selection_config['migration_info'] = {
    'migrated_from' => 'git_submodule',
    'migrated_at' => Time.now.utc.iso8601,
    'original_config' => config_file
  }

  # Write selection configuration
  File.write($options[:output_file], YAML.dump(selection_config))
  log_info("Direct copy selection config written to #{$options[:output_file]}")

  # Provide next steps
  puts ""
  puts "Next steps to complete migration from git submodule to direct copy:"
  puts "1. Run: ruby examples/consumer-direct-copy/scripts/copy-leyline-standards.rb --config #{$options[:output_file]}"
  puts "2. Verify copied standards in docs/standards/"
  puts "3. Remove submodule: git submodule deinit leyline && git rm leyline"
  puts "4. Update workflows to use direct copy validation"
end

if __FILE__ == $0
  main
end
