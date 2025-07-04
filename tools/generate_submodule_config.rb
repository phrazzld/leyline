#!/usr/bin/env ruby
# generate_submodule_config.rb - Generate git submodule configuration from direct copy standards
#
# This tool analyzes copied Leyline standards and generates an appropriate
# git submodule configuration, facilitating migration between integration methods.

require 'yaml'
require 'optparse'

# Configuration and options
$options = {
  from_directory: 'docs/standards',
  output_file: 'leyline-config.yml',
  verbose: false
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: generate_submodule_config.rb [options]'

  opts.on('--from DIR', 'Directory containing copied standards') do |dir|
    $options[:from_directory] = dir
  end

  opts.on('-o', '--output FILE', 'Output submodule config file path') do |file|
    $options[:output_file] = file
  end

  opts.on('--verbose', 'Verbose output') do
    $options[:verbose] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
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

def analyze_standards_directory(standards_dir)
  analysis = {
    'tenets' => [],
    'binding_categories' => [],
    'version' => '0.1.5'
  }

  # Analyze tenets
  tenets_dir = File.join(standards_dir, 'tenets')
  if Dir.exist?(tenets_dir)
    tenets = Dir.glob("#{tenets_dir}/*.md").map do |file|
      File.basename(file, '.md')
    end.reject { |name| name.include?('index') }

    analysis['tenets'] = tenets
    log_verbose("Found tenets: #{tenets.join(', ')}")
  end

  # Analyze binding categories
  bindings_dir = File.join(standards_dir, 'bindings')
  if Dir.exist?(bindings_dir)
    # Check for hierarchical structure
    core_dir = File.join(bindings_dir, 'core')
    categories_dir = File.join(bindings_dir, 'categories')

    if Dir.exist?(core_dir)
      analysis['binding_categories'] << 'core'
      log_verbose('Found core bindings')
    end

    if Dir.exist?(categories_dir)
      categories = Dir.glob("#{categories_dir}/*/").map { |d| File.basename(d) }
      analysis['binding_categories'].concat(categories)
      log_verbose("Found binding categories: #{categories.join(', ')}")
    else
      # Check for flat structure
      binding_files = Dir.glob("#{bindings_dir}/*.md")
      if binding_files.any?
        analysis['binding_categories'] << 'core'
        log_verbose('Found flat binding structure, assuming core category')
      end
    end
  end

  # Try to detect version from tracking file
  tracking_file = '.leyline-tracking.yml'
  if File.exist?(tracking_file)
    tracking = YAML.load_file(tracking_file)
    if tracking['leyline_version']
      analysis['version'] = tracking['leyline_version'].gsub(/^v/, '')
      log_verbose("Detected version from tracking: #{analysis['version']}")
    end
  end

  analysis
end

def generate_submodule_config(analysis)
  config = {
    'leyline_version' => analysis['version'],
    'tenets' => analysis['tenets'],
    'binding_categories' => analysis['binding_categories'].uniq,
    'excluded_bindings' => [],
    'validation_rules' => {
      'enforce_conventional_commits' => true,
      'require_changelog' => true,
      'require_readme' => true,
      'require_contributing_guide' => false
    },
    'project' => {
      'primary_language' => '',
      'project_type' => '',
      'maturity' => 'developing'
    },
    'validation_scope' => {
      'include' => [
        'src/',
        'lib/',
        'docs/',
        '.github/'
      ],
      'exclude' => [
        'node_modules/',
        'vendor/',
        'target/',
        'dist/',
        'build/',
        '.git/',
        'leyline/'
      ]
    },
    'reporting' => {
      'verbosity' => 'normal',
      'fail_on_violation' => true,
      'warnings_as_errors' => false
    },
    'hooks' => {
      'pre_validation' => '',
      'post_validation' => '',
      'on_failure' => ''
    }
  }

  # Add migration metadata
  config['migration_info'] = {
    'migrated_from' => 'direct_copy',
    'migrated_at' => Time.now.utc.iso8601,
    'source_directory' => $options[:from_directory]
  }

  config
end

def main
  standards_dir = $options[:from_directory]

  unless Dir.exist?(standards_dir)
    log_error("Standards directory not found: #{standards_dir}")
    exit 1
  end

  log_info("Analyzing copied standards in #{standards_dir}")

  # Analyze the standards directory
  analysis = analyze_standards_directory(standards_dir)

  if analysis['tenets'].empty? && analysis['binding_categories'].empty?
    log_error("No standards found in #{standards_dir}")
    exit 1
  end

  log_info("Found #{analysis['tenets'].size} tenets and #{analysis['binding_categories'].size} binding categories")

  # Generate submodule configuration
  config = generate_submodule_config(analysis)

  # Write configuration file
  File.write($options[:output_file], YAML.dump(config))
  log_info("Submodule configuration written to #{$options[:output_file]}")

  # Provide next steps
  puts ''
  puts 'Next steps to complete migration from direct copy to git submodule:'
  puts '1. Add Leyline as a submodule: git submodule add https://github.com/phrazzld/leyline.git leyline'
  puts '2. Initialize submodule: git submodule update --init --recursive'
  puts '3. Copy validation workflow: cp leyline/examples/consumer-git-submodule/.github/workflows/leyline-validation.yml .github/workflows/'
  puts "4. Remove copied standards: rm -rf #{standards_dir}"
  puts '5. Test submodule integration with: ruby leyline/tools/validate_front_matter.rb'
end

main if __FILE__ == $0
