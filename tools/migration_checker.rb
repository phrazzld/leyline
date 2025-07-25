#!/usr/bin/env ruby
# migration_checker.rb - Analyze compatibility and breaking changes between Leyline versions
#
# This tool helps teams understand what changes when migrating between different
# versions of Leyline, providing detailed analysis and migration guidance.

require 'yaml'
require 'json'
require 'optparse'
require 'net/http'
require 'uri'
require 'fileutils'
require 'digest'

# Configuration and options
$options = {
  from_version: nil,
  to_version: nil,
  detailed: false,
  breaking_changes_only: false,
  generate_plan: false,
  output_format: 'text',
  output_file: nil,
  verbose: false
}

$errors = []
$warnings = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: migration_checker.rb [options]'

  opts.on('--from VERSION', 'Source Leyline version (e.g., v0.1.0)') do |version|
    $options[:from_version] = version
  end

  opts.on('--to VERSION', 'Target Leyline version (e.g., v0.2.0)') do |version|
    $options[:to_version] = version
  end

  opts.on('--detailed', 'Provide detailed analysis with recommendations') do
    $options[:detailed] = true
  end

  opts.on('--breaking-changes-only', 'Show only breaking changes') do
    $options[:breaking_changes_only] = true
  end

  opts.on('--generate-plan', 'Generate a migration plan file') do
    $options[:generate_plan] = true
  end

  opts.on('--format FORMAT', 'Output format (text, json, yaml)') do |format|
    $options[:output_format] = format
  end

  opts.on('-o', '--output FILE', 'Output file path') do |file|
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

# Helper methods
def log_info(message)
  puts "[INFO] #{message}"
end

def log_verbose(message)
  puts "[VERBOSE] #{message}" if $options[:verbose]
end

def log_warning(message)
  puts "[WARNING] #{message}"
  $warnings << message
end

def log_error(message)
  puts "[ERROR] #{message}"
  $errors << message
end

def exit_with_summary
  if $warnings.any?
    puts "\n#{$warnings.size} warning(s) found:"
    $warnings.each { |warning| puts "  - #{warning}" }
  end

  if $errors.any?
    puts "\n#{$errors.size} error(s) found:"
    $errors.each { |error| puts "  - #{error}" }
    puts "\nMigration analysis failed!"
    exit 1
  else
    puts "\nMigration analysis completed successfully!"
    exit 0
  end
end

# Version comparison and validation
def validate_version_format(version)
  unless version =~ /^v?\d+\.\d+\.\d+(-.*)?$/
    log_error("Invalid version format: #{version}. Expected format: v1.0.0")
    return false
  end
  true
end

def normalize_version(version)
  version.start_with?('v') ? version : "v#{version}"
end

def compare_versions(v1, v2)
  # Simple semantic version comparison
  # Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2

  def parse_version(v)
    v.gsub(/^v/, '').split('.').map(&:to_i)
  end

  parts1 = parse_version(v1)
  parts2 = parse_version(v2)

  [parts1.length, parts2.length].max.times do |i|
    a = parts1[i] || 0
    b = parts2[i] || 0

    return -1 if a < b
    return 1 if a > b
  end

  0
end

def migration_type(from_version, to_version)
  def parse_version(v)
    v.gsub(/^v/, '').split('.').map(&:to_i)
  end

  from_parts = parse_version(from_version)
  to_parts = parse_version(to_version)

  if from_parts[0] != to_parts[0]
    'major'
  elsif from_parts[1] != to_parts[1]
    'minor'
  else
    'patch'
  end
end

# Fetch version information from repository analysis
def fetch_version_info(version)
  log_verbose("Analyzing repository data for #{version}")

  # Check if this is the current working directory
  return analyze_current_repository if %w[HEAD current].include?(version)

  # Check if the version tag exists
  unless tag_exists?(version)
    log_warning("Version tag #{version} not found in repository")
    return nil
  end

  # Analyze the repository at this specific version
  analyze_repository_at_version(version)
end

# Check if a Git tag exists
def tag_exists?(version)
  result = system("git rev-parse #{version} >/dev/null 2>&1")
  result == true
end

# Analyze current repository state
def analyze_current_repository
  log_verbose('Analyzing current repository state')

  info = {
    'tenets_count' => 0,
    'core_bindings_count' => 0,
    'category_bindings' => {},
    'directory_structure' => 'unknown',
    'yaml_frontmatter_version' => '1.0',
    'breaking_changes' => []
  }

  # Count tenets
  if Dir.exist?('docs/tenets')
    tenets = Dir.glob('docs/tenets/*.md').reject { |f| f.include?('00-index.md') }
    info['tenets_count'] = tenets.length
    log_verbose("Found #{tenets.length} tenets")
  end

  # Count core bindings
  if Dir.exist?('docs/bindings/core')
    core_bindings = Dir.glob('docs/bindings/core/*.md').reject { |f| f.include?('00-index.md') }
    info['core_bindings_count'] = core_bindings.length
    log_verbose("Found #{core_bindings.length} core bindings")
  end

  # Count category bindings
  if Dir.exist?('docs/bindings/categories')
    categories = Dir.glob('docs/bindings/categories/*').select { |d| File.directory?(d) }
    categories.each do |category_dir|
      category = File.basename(category_dir)
      binding_files = Dir.glob("#{category_dir}/*.md").reject { |f| f.include?('00-index.md') }
      if binding_files.length > 0
        info['category_bindings'][category] = binding_files.length
        log_verbose("Found #{binding_files.length} #{category} bindings")
      end
    end
  end

  # Determine directory structure
  info['directory_structure'] = if Dir.exist?('docs/bindings/categories')
                                  'hierarchical'
                                elsif Dir.exist?('docs/bindings') && Dir.glob('docs/bindings/*.md').any?
                                  'flat'
                                else
                                  'unknown'
                                end

  # Detect YAML front-matter version by examining a sample file
  sample_files = Dir.glob('docs/**/*.md').reject { |f| f.include?('00-index.md') }.first(3)
  sample_files.each do |file|
    next unless File.exist?(file)

    content = File.read(file)
    next unless content.start_with?('---')

    yaml_end = content.index('---', 3)
    next unless yaml_end

    begin
      yaml_content = content[4...yaml_end]
      yaml_data = YAML.safe_load(yaml_content)
      if yaml_data.is_a?(Hash) && yaml_data.key?('version')
        info['yaml_frontmatter_version'] = '1.0' # Has version field
        break
      end
    rescue StandardError
      # Skip invalid YAML
    end
  end

  log_verbose('Repository analysis complete')
  info
end

# Analyze repository at a specific version/tag
def analyze_repository_at_version(version)
  log_verbose("Analyzing repository at version #{version}")

  info = {
    'tenets_count' => 0,
    'core_bindings_count' => 0,
    'category_bindings' => {},
    'directory_structure' => 'unknown',
    'yaml_frontmatter_version' => '1.0',
    'breaking_changes' => []
  }

  # Use git show to get file listings at the specific version
  begin
    # Count tenets at this version
    tenets_output = `git ls-tree -r --name-only #{version} -- docs/tenets/ 2>/dev/null`
    if $?.success?
      tenets = tenets_output.lines.map(&:strip).select { |f| f.end_with?('.md') && !f.include?('00-index.md') }
      info['tenets_count'] = tenets.length
      log_verbose("Found #{tenets.length} tenets at #{version}")
    end

    # Count core bindings at this version
    core_bindings_output = `git ls-tree -r --name-only #{version} -- docs/bindings/core/ 2>/dev/null`
    if $?.success?
      core_bindings = core_bindings_output.lines.map(&:strip).select do |f|
        f.end_with?('.md') && !f.include?('00-index.md')
      end
      info['core_bindings_count'] = core_bindings.length
      log_verbose("Found #{core_bindings.length} core bindings at #{version}")
    end

    # Count category bindings at this version
    categories_output = `git ls-tree -r --name-only #{version} -- docs/bindings/categories/ 2>/dev/null`
    if $?.success?
      category_files = categories_output.lines.map(&:strip).select do |f|
        f.end_with?('.md') && !f.include?('00-index.md')
      end

      # Group by category
      category_files.each do |file|
        # Extract category from path like "docs/bindings/categories/go/interface-design.md"
        parts = file.split('/')
        next unless parts.length >= 5 && parts[2] == 'categories'

        category = parts[3]
        info['category_bindings'][category] ||= 0
        info['category_bindings'][category] += 1
      end

      info['category_bindings'].each do |category, count|
        log_verbose("Found #{count} #{category} bindings at #{version}")
      end
    end

    # Determine directory structure at this version
    structure_check = `git ls-tree -r --name-only #{version} -- docs/bindings/ 2>/dev/null`
    if $?.success?
      files = structure_check.lines.map(&:strip)
      if files.any? { |f| f.include?('docs/bindings/categories/') }
        info['directory_structure'] = 'hierarchical'
      elsif files.any? { |f| f.match(%r{^docs/bindings/[^/]+\.md$}) }
        info['directory_structure'] = 'flat'
      end
    end

    # Get breaking changes from commit messages since previous version
    info['breaking_changes'] = get_breaking_changes_since_previous_version(version)
  rescue StandardError => e
    log_warning("Error analyzing version #{version}: #{e.message}")
    return nil
  end

  log_verbose("Repository analysis complete for #{version}")
  info
end

# Get breaking changes from Git history
def get_breaking_changes_since_previous_version(version)
  breaking_changes = []

  begin
    # Get the previous tag
    previous_tags = `git tag --sort=-version:refname`.lines.map(&:strip)
    current_index = previous_tags.index(version)

    if current_index && current_index < previous_tags.length - 1
      previous_version = previous_tags[current_index + 1]

      # Get commits between versions that mention breaking changes
      commits = `git log #{previous_version}..#{version} --oneline --grep="BREAKING CHANGE" --grep="breaking change" -i 2>/dev/null`

      if $?.success? && !commits.empty?
        commits.lines.each do |commit|
          # Extract breaking change info from commit message
          commit_detail = `git show --format=%B -s #{commit.split(' ').first} 2>/dev/null`
          breaking_changes << if commit_detail.match(/BREAKING CHANGE[:\s]+(.+?)$/i)
                                Regexp.last_match(1).strip
                              elsif commit_detail.match(/breaking change[:\s]+(.+?)$/i)
                                Regexp.last_match(1).strip
                              else
                                "Breaking change in #{commit.strip}"
                              end
        end
      end
    end
  rescue StandardError => e
    log_verbose("Could not determine breaking changes: #{e.message}")
  end

  breaking_changes.uniq
end

# Analyze changes between versions
def analyze_changes(from_info, to_info, from_version, to_version)
  changes = {
    'migration_type' => migration_type(from_version, to_version),
    'breaking_changes' => [],
    'new_features' => [],
    'enhancements' => [],
    'deprecations' => [],
    'removals' => []
  }

  # Analyze tenets changes
  if from_info['tenets_count'] != to_info['tenets_count']
    diff = to_info['tenets_count'] - from_info['tenets_count']
    if diff > 0
      changes['new_features'] << "#{diff} new tenets added"
    else
      changes['removals'] << "#{diff.abs} tenets removed"
    end
  end

  # Analyze core bindings changes
  if from_info['core_bindings_count'] != to_info['core_bindings_count']
    diff = to_info['core_bindings_count'] - from_info['core_bindings_count']
    if diff > 0
      changes['new_features'] << "#{diff} new core bindings added"
    else
      changes['removals'] << "#{diff.abs} core bindings removed"
    end
  end

  # Analyze category bindings changes
  all_categories = (from_info['category_bindings'].keys + to_info['category_bindings'].keys).uniq
  all_categories.each do |category|
    from_count = from_info['category_bindings'][category] || 0
    to_count = to_info['category_bindings'][category] || 0

    if from_count == 0 && to_count > 0
      changes['new_features'] << "New binding category: #{category} (#{to_count} bindings)"
    elsif from_count > 0 && to_count == 0
      changes['removals'] << "Removed binding category: #{category} (#{from_count} bindings)"
    elsif from_count != to_count
      diff = to_count - from_count
      if diff > 0
        changes['enhancements'] << "#{category} category: #{diff} new bindings"
      else
        changes['removals'] << "#{category} category: #{diff.abs} bindings removed"
      end
    end
  end

  # Analyze directory structure changes
  if from_info['directory_structure'] != to_info['directory_structure']
    changes['breaking_changes'] << "Directory structure changed: #{from_info['directory_structure']} → #{to_info['directory_structure']}"
  end

  # Analyze YAML front-matter changes
  if from_info['yaml_frontmatter_version'] != to_info['yaml_frontmatter_version']
    changes['breaking_changes'] << "YAML front-matter version changed: #{from_info['yaml_frontmatter_version']} → #{to_info['yaml_frontmatter_version']}"
  end

  # Add version-specific breaking changes
  changes['breaking_changes'].concat(to_info['breaking_changes'])

  changes
end

# Generate migration recommendations
def generate_recommendations(changes, _from_version, _to_version)
  recommendations = []

  case changes['migration_type']
  when 'major'
    recommendations << '⚠️  MAJOR VERSION MIGRATION: Breaking changes present, migration required'
    recommendations << '📋 Create backup before proceeding'
    recommendations << '🧪 Test migration in staging environment first'
    recommendations << '📚 Review all breaking changes and update configurations'
  when 'minor'
    recommendations << '✅ MINOR VERSION MIGRATION: Backward compatible, optional adoption'
    recommendations << '🆕 Review new features and consider adoption'
    recommendations << '📈 Enhanced features available for existing components'
  when 'patch'
    recommendations << '🔧 PATCH VERSION MIGRATION: Safe to update immediately'
    recommendations << '🐛 Bug fixes and minor improvements'
  end

  # Breaking change specific recommendations
  if changes['breaking_changes'].any?
    recommendations << ''
    recommendations << '🚨 BREAKING CHANGES DETECTED:'
    changes['breaking_changes'].each do |change|
      recommendations << "   - #{change}"
    end

    recommendations << ''
    recommendations << '📋 Required Actions:'

    if changes['breaking_changes'].any? { |c| c.include?('YAML front-matter') }
      recommendations << '   - Run YAML front-matter migration tool'
      recommendations << '   - Validate all metadata after migration'
    end

    if changes['breaking_changes'].any? { |c| c.include?('Directory structure') }
      recommendations << '   - Update file references and imports'
      recommendations << '   - Regenerate indexes and navigation'
    end

    if changes['breaking_changes'].any? { |c| c.include?('validation') }
      recommendations << '   - Update validation configurations'
      recommendations << '   - Install new validation dependencies'
    end
  end

  # New feature recommendations
  if changes['new_features'].any?
    recommendations << ''
    recommendations << '🆕 NEW FEATURES AVAILABLE:'
    changes['new_features'].each do |feature|
      recommendations << "   - #{feature}"
    end

    recommendations << ''
    recommendations << '💡 Consider adopting:'
    recommendations << '   - Review new tenets for team alignment'
    recommendations << '   - Evaluate new bindings for current projects'
    recommendations << '   - Update integration patterns if beneficial'
  end

  recommendations
end

# Generate migration plan
def generate_migration_plan(changes, from_version, to_version, recommendations)
  plan = {
    'migration_info' => {
      'from_version' => from_version,
      'to_version' => to_version,
      'migration_type' => changes['migration_type'],
      'estimated_time' => estimate_migration_time(changes),
      'risk_level' => assess_risk_level(changes)
    },
    'pre_migration' => [
      'Create backup branch or commit',
      'Review release notes and breaking changes',
      'Set up staging environment for testing',
      'Notify team members of planned migration'
    ],
    'migration_steps' => generate_migration_steps(changes),
    'post_migration' => [
      'Run validation tools',
      'Test integration workflows',
      'Update documentation',
      'Monitor for issues'
    ],
    'rollback_plan' => [
      'Restore from backup branch/commit',
      'Revert configuration changes',
      'Validate rollback success',
      'Document issues encountered'
    ]
  }

  if changes['breaking_changes'].any?
    plan['breaking_changes'] = changes['breaking_changes']
    plan['required_actions'] = extract_required_actions(recommendations)
  end

  plan
end

def estimate_migration_time(changes)
  base_time = 30 # minutes

  base_time += changes['breaking_changes'].size * 15
  base_time += changes['new_features'].size * 5
  base_time += changes['enhancements'].size * 3

  case changes['migration_type']
  when 'major'
    base_time += 60
  when 'minor'
    base_time += 20
  end

  "#{base_time} minutes"
end

def assess_risk_level(changes)
  if changes['breaking_changes'].any?
    'high'
  elsif changes['new_features'].any?
    'medium'
  else
    'low'
  end
end

def generate_migration_steps(changes)
  steps = []

  case changes['migration_type']
  when 'major'
    steps << 'Update version references in configuration'

    if changes['breaking_changes'].any? { |c| c.include?('YAML') }
      steps << 'Run YAML front-matter migration: ruby tools/migrate_yaml_frontmatter.rb'
    end

    if changes['breaking_changes'].any? { |c| c.include?('Directory') }
      steps << 'Run directory structure migration: ruby tools/migrate_directory_structure.rb'
    end

    steps << 'Update validation configurations'
    steps << 'Run comprehensive validation: ruby tools/validate_migration.rb'

  when 'minor'
    steps << 'Update version references'
    steps << 'Review and optionally adopt new features'
    steps << 'Run validation to ensure compatibility'

  when 'patch'
    steps << 'Update version references'
    steps << 'Run basic validation'
  end

  steps
end

def extract_required_actions(recommendations)
  actions = []
  in_required_section = false

  recommendations.each do |line|
    if line.include?('Required Actions:')
      in_required_section = true
      next
    elsif line.strip.empty? || !line.start_with?('   -')
      in_required_section = false
    end

    actions << line.strip.sub(/^- /, '') if in_required_section
  end

  actions
end

# Output formatting
def format_output(analysis_result)
  case $options[:output_format]
  when 'json'
    JSON.pretty_generate(analysis_result)
  when 'yaml'
    YAML.dump(analysis_result)
  else
    format_text_output(analysis_result)
  end
end

def format_text_output(analysis_result)
  output = []

  output << '# Leyline Migration Analysis'
  output << ''
  output << "**From:** #{analysis_result['from_version']}"
  output << "**To:** #{analysis_result['to_version']}"
  output << "**Migration Type:** #{analysis_result['changes']['migration_type'].upcase}"
  output << ''

  if analysis_result['changes']['breaking_changes'].any?
    output << '## Breaking Changes'
    analysis_result['changes']['breaking_changes'].each do |change|
      output << "- #{change}"
    end
    output << ''
  end

  if analysis_result['changes']['new_features'].any?
    output << '## New Features'
    analysis_result['changes']['new_features'].each do |feature|
      output << "- #{feature}"
    end
    output << ''
  end

  if analysis_result['changes']['enhancements'].any?
    output << '## Enhancements'
    analysis_result['changes']['enhancements'].each do |enhancement|
      output << "- #{enhancement}"
    end
    output << ''
  end

  if analysis_result['recommendations'].any?
    output << '## Recommendations'
    analysis_result['recommendations'].each do |rec|
      output << rec
    end
    output << ''
  end

  if $options[:detailed] && analysis_result['migration_plan']
    output << '## Migration Plan'
    output << ''
    output << "**Estimated Time:** #{analysis_result['migration_plan']['migration_info']['estimated_time']}"
    output << "**Risk Level:** #{analysis_result['migration_plan']['migration_info']['risk_level'].upcase}"
    output << ''

    output << '### Migration Steps'
    analysis_result['migration_plan']['migration_steps'].each_with_index do |step, i|
      output << "#{i + 1}. #{step}"
    end
    output << ''
  end

  output.join("\n")
end

# Write output to file or stdout
def write_output(content)
  if $options[:output_file]
    File.write($options[:output_file], content)
    log_info("Analysis written to #{$options[:output_file]}")
  else
    puts content
  end
end

# Main execution
def main
  # Validate required options
  unless $options[:from_version] && $options[:to_version]
    log_error('Both --from and --to versions are required')
    exit_with_summary
  end

  # Validate version formats
  exit_with_summary unless validate_version_format($options[:from_version])
  exit_with_summary unless validate_version_format($options[:to_version])

  # Normalize versions
  from_version = normalize_version($options[:from_version])
  to_version = normalize_version($options[:to_version])

  log_info("Analyzing migration from #{from_version} to #{to_version}")

  # Check if migration is needed
  version_comparison = compare_versions(from_version, to_version)
  if version_comparison == 0
    log_info('Versions are identical, no migration needed')
    exit 0
  elsif version_comparison > 0
    log_warning("Target version (#{to_version}) is older than source version (#{from_version})")
    log_warning('This appears to be a rollback rather than a migration')
  end

  # Fetch version information
  from_info = fetch_version_info(from_version)
  to_info = fetch_version_info(to_version)

  # Analyze changes
  changes = analyze_changes(from_info, to_info, from_version, to_version)

  # Filter for breaking changes only if requested
  if $options[:breaking_changes_only]
    filtered_changes = {
      'migration_type' => changes['migration_type'],
      'breaking_changes' => changes['breaking_changes']
    }
    changes = filtered_changes
  end

  # Generate recommendations
  recommendations = generate_recommendations(changes, from_version, to_version)

  # Build analysis result
  analysis_result = {
    'from_version' => from_version,
    'to_version' => to_version,
    'changes' => changes,
    'recommendations' => recommendations
  }

  # Generate migration plan if requested
  if $options[:generate_plan] || $options[:detailed]
    analysis_result['migration_plan'] = generate_migration_plan(changes, from_version, to_version, recommendations)
  end

  # Format and output results
  formatted_output = format_output(analysis_result)
  write_output(formatted_output)

  # Generate separate migration plan file if requested
  if $options[:generate_plan]
    plan_filename = "migration-plan-#{from_version}-to-#{to_version}.yml"
    File.write(plan_filename, YAML.dump(analysis_result['migration_plan']))
    log_info("Migration plan written to #{plan_filename}")
  end

  exit_with_summary
end

# Run the script
if __FILE__ == $0
  begin
    main
  rescue Interrupt
    puts "\nInterrupted by user"
    exit 1
  rescue StandardError => e
    log_error("Unexpected error: #{e.message}")
    log_error("Backtrace: #{e.backtrace.join("\n")}")
    exit 1
  end
end
