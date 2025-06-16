#!/usr/bin/env ruby

require 'fileutils'
require 'yaml'

class BatchRefactoringWorkflow
  def initialize
    @base_dir = Dir.pwd
    @tools_dir = File.join(@base_dir, 'tools')
    @log_file = File.join(@tools_dir, 'refactoring_log.txt')
    @results = {
      processed: 0,
      successful: 0,
      failed: 0,
      total_lines_reduced: 0,
      documents: []
    }
  end

  def run_workflow(tier = nil)
    puts "🚀 BATCH REFACTORING WORKFLOW"
    puts "=" * 40
    puts

    log("Starting batch refactoring workflow for tier: #{tier || 'all'}")

    # Load priority matrix
    documents_to_process = load_priority_documents(tier)

    if documents_to_process.empty?
      puts "No documents found for processing."
      return
    end

    puts "📋 Documents to process: #{documents_to_process.length}"
    puts

    # Process each document
    documents_to_process.each_with_index do |doc_info, index|
      puts "Processing #{index + 1}/#{documents_to_process.length}: #{doc_info[:filename]}"
      process_document(doc_info)
      puts
    end

    # Generate final report
    generate_summary_report

    # Run validation suite
    run_validation_suite

    puts "✅ Batch refactoring workflow completed!"
    puts "📊 Check #{@log_file} for detailed results"
  end

  private

  def load_priority_documents(tier)
    # Define priority tiers based on the matrix
    tier_1_high_impact = [
      'type-safe-state-management.md',
      'async-patterns.md',
      'module-organization.md',
      'dependency-injection-patterns.md',
      'concurrency-patterns.md',
      'audit-logging-implementation.md',
      'database-testing-strategies.md'
    ]

    tier_2_medium = [
      'comprehensive-security-automation.md',
      'technical-debt-tracking.md',
      'context-propagation.md',
      'feature-flag-management.md',
      'extract-common-logic.md',
      'pyproject-toml-configuration.md',
      'ruff-code-quality.md',
      'package-structure.md',
      'interface-design.md',
      'error-context-propagation.md',
      'package-design.md'
    ]

    tier_3_quick_wins = [
      'functional-composition-patterns.md',
      'trait-composition-patterns.md',
      'testing-patterns.md',
      'orm-usage-patterns.md',
      'type-hinting.md'
    ]

    # Select documents based on tier
    target_files = case tier&.to_s
                   when '1', 'tier1', 'high'
                     tier_1_high_impact
                   when '2', 'tier2', 'medium'
                     tier_2_medium
                   when '3', 'tier3', 'quick'
                     tier_3_quick_wins
                   else
                     tier_1_high_impact + tier_2_medium + tier_3_quick_wins
                   end

    # Find actual file paths
    documents = []
    target_files.each do |filename|
      file_paths = Dir.glob([
        "docs/tenets/#{filename}",
        "docs/bindings/**/**/#{filename}"
      ])

      if file_paths.any?
        file_path = file_paths.first
        documents << {
          filename: filename,
          path: file_path,
          category: categorize_document(file_path),
          current_lines: count_lines(file_path)
        }
      else
        puts "⚠️  Warning: Could not find #{filename}"
      end
    end

    documents
  end

  def categorize_document(file_path)
    case file_path
    when /\/typescript\// then 'TypeScript'
    when /\/python\// then 'Python'
    when /\/go\// then 'Go'
    when /\/rust\// then 'Rust'
    when /\/database\// then 'Database'
    when /\/security\// then 'Security'
    when /\/frontend\//, /\/react\// then 'Frontend'
    when /\/core\// then 'Core'
    when /\/tenets\// then 'Tenets'
    else 'Other'
    end
  end

  def count_lines(file_path)
    File.readlines(file_path).count
  rescue => e
    log("Error counting lines for #{file_path}: #{e.message}")
    0
  end

  def process_document(doc_info)
    start_time = Time.now
    @results[:processed] += 1

    begin
      # Pre-refactoring state
      original_lines = doc_info[:current_lines]
      original_size = File.size(doc_info[:path])

      # Create backup
      backup_path = create_backup(doc_info[:path])

      # Validate current state
      if !validate_document_structure(doc_info[:path])
        log("❌ Pre-validation failed for #{doc_info[:filename]}")
        @results[:failed] += 1
        return
      end

      # Apply refactoring template
      puts "  📝 Applying refactoring template..."
      refactoring_notes = apply_refactoring_guidance(doc_info)

      # Manual intervention point
      puts "  ⏸️  Ready for manual refactoring of #{doc_info[:filename]}"
      puts "     Original: #{original_lines} lines"
      puts "     Target: ≤400 lines (≤150 for tenets)"
      puts "     Category: #{doc_info[:category]}"
      puts "     Backup created: #{backup_path}"
      puts "     Template guidance: #{refactoring_notes[:key_strategies].join(', ')}"
      puts
      puts "  👉 Apply refactoring manually, then press Enter to continue..."

      # Wait for user to complete manual refactoring
      STDIN.gets

      # Post-refactoring validation
      puts "  🔍 Validating refactored document..."

      if validate_post_refactoring(doc_info[:path], original_lines)
        new_lines = count_lines(doc_info[:path])
        lines_reduced = original_lines - new_lines

        @results[:successful] += 1
        @results[:total_lines_reduced] += lines_reduced

        completion_time = Time.now - start_time

        result = {
          filename: doc_info[:filename],
          category: doc_info[:category],
          original_lines: original_lines,
          new_lines: new_lines,
          lines_reduced: lines_reduced,
          reduction_percentage: ((lines_reduced.to_f / original_lines) * 100).round(1),
          processing_time: completion_time.round(2),
          status: 'SUCCESS'
        }

        @results[:documents] << result

        puts "  ✅ Success! Reduced #{lines_reduced} lines (#{result[:reduction_percentage]}%)"
        log("SUCCESS: #{doc_info[:filename]} - #{lines_reduced} lines reduced")

        # Cleanup backup if successful
        File.delete(backup_path) if File.exist?(backup_path)

      else
        @results[:failed] += 1
        puts "  ❌ Post-validation failed"

        # Restore from backup
        FileUtils.cp(backup_path, doc_info[:path])
        puts "  🔄 Restored from backup"

        log("FAILED: #{doc_info[:filename]} - validation failed, restored from backup")
      end

    rescue => e
      @results[:failed] += 1
      puts "  💥 Error processing #{doc_info[:filename]}: #{e.message}"
      log("ERROR: #{doc_info[:filename]} - #{e.message}")

      # Restore from backup if it exists
      backup_path = "#{doc_info[:path]}.backup"
      if File.exist?(backup_path)
        FileUtils.cp(backup_path, doc_info[:path])
        puts "  🔄 Restored from backup"
      end
    end
  end

  def create_backup(file_path)
    backup_path = "#{file_path}.backup"
    FileUtils.cp(file_path, backup_path)
    backup_path
  end

  def validate_document_structure(file_path)
    # Run existing YAML validation
    output = `ruby #{@tools_dir}/validate_front_matter.rb -f "#{file_path}" 2>&1`
    $?.success?
  end

  def apply_refactoring_guidance(doc_info)
    content = File.read(doc_info[:path])

    # Analyze patterns in the document
    analysis = analyze_document_patterns(content)

    # Generate specific guidance
    strategies = []

    if analysis[:multiple_languages] > 4
      strategies << "Apply 'one example rule' - #{analysis[:languages].join(', ')} → choose primary language"
    end

    if analysis[:verbose_sections] > 3
      strategies << "Consolidate verbose sections and repetitive explanations"
    end

    if analysis[:tool_configs] > 2
      strategies << "Remove tool-specific configurations, focus on principles"
    end

    if analysis[:step_by_step] > 5
      strategies << "Simplify step-by-step content to core implementation patterns"
    end

    {
      key_strategies: strategies,
      target_reduction: estimate_reduction_potential(analysis, doc_info[:current_lines]),
      focus_areas: analysis[:focus_areas]
    }
  end

  def analyze_document_patterns(content)
    {
      multiple_languages: content.scan(/```(\w+)/).length,
      languages: content.scan(/```(\w+)/).flatten.uniq,
      verbose_sections: content.scan(/^##\s+|^###\s+|^####\s+/).length,
      tool_configs: content.scan(/```(?:yaml|toml|json)/).length,
      step_by_step: content.scan(/^\s*\d+\./).length,
      focus_areas: identify_focus_areas(content)
    }
  end

  def identify_focus_areas(content)
    areas = []
    areas << 'Examples section' if content.include?('## Examples')
    areas << 'Implementation section' if content.include?('## Practical Implementation')
    areas << 'Configuration details' if content.match(/```(?:yaml|toml|json)/)
    areas << 'Multi-language examples' if content.scan(/```\w+/).length > 6
    areas
  end

  def estimate_reduction_potential(analysis, current_lines)
    excess = current_lines - 400
    return 0 if excess <= 0

    potential = 0
    potential += [excess * 0.4, 200].min if analysis[:multiple_languages] > 4
    potential += [excess * 0.2, 100].min if analysis[:tool_configs] > 3
    potential += [excess * 0.15, 80].min if analysis[:step_by_step] > 5

    potential.round
  end

  def validate_post_refactoring(file_path, original_lines)
    # Check basic requirements
    new_lines = count_lines(file_path)
    is_tenet = file_path.include?('/tenets/')
    limit = is_tenet ? 150 : 400

    # Must be under limit
    return false if new_lines > limit

    # Must have reduced lines (unless already compliant)
    return false if new_lines >= original_lines && original_lines > limit

    # Must pass YAML validation
    return false unless validate_document_structure(file_path)

    # Must preserve essential structure
    content = File.read(file_path)
    return false unless content.include?('## Rationale')
    return false unless content.include?('## Rule Definition') || content.include?('## Implementation')
    return false unless content.include?('## Related')

    true
  end

  def generate_summary_report
    puts
    puts "📊 REFACTORING SUMMARY REPORT"
    puts "=" * 40
    puts "Documents processed: #{@results[:processed]}"
    puts "Successful: #{@results[:successful]}"
    puts "Failed: #{@results[:failed]}"
    puts "Total lines reduced: #{@results[:total_lines_reduced]}"
    puts

    if @results[:documents].any?
      puts "📋 Document Results:"
      @results[:documents].each do |doc|
        status_icon = doc[:status] == 'SUCCESS' ? '✅' : '❌'
        puts "  #{status_icon} #{doc[:filename]}: #{doc[:lines_reduced]} lines (#{doc[:reduction_percentage]}%)"
      end
      puts
    end

    # Log detailed results
    log("SUMMARY: #{@results[:successful]}/#{@results[:processed]} successful, #{@results[:total_lines_reduced]} total lines reduced")
  end

  def run_validation_suite
    puts "🔍 Running comprehensive validation suite..."

    # Run document length validation
    puts "  Checking document lengths..."
    length_result = system("ruby #{@tools_dir}/check_document_length.rb")

    # Run YAML front-matter validation
    puts "  Validating YAML front-matter..."
    yaml_result = system("ruby #{@tools_dir}/validate_front_matter.rb")

    # Run cross-reference validation
    puts "  Checking cross-references..."
    xref_result = system("ruby #{@tools_dir}/fix_cross_references.rb")

    # Run index regeneration
    puts "  Regenerating indexes..."
    index_result = system("ruby #{@tools_dir}/reindex.rb --strict")

    all_passed = length_result && yaml_result && xref_result && index_result

    if all_passed
      puts "  ✅ All validation checks passed!"
    else
      puts "  ❌ Some validation checks failed - review output above"
    end

    log("Validation suite completed: #{all_passed ? 'PASSED' : 'FAILED'}")
  end

  def log(message)
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    log_entry = "[#{timestamp}] #{message}\n"

    File.open(@log_file, 'a') { |f| f.write(log_entry) }
  end
end

# CLI interface
if __FILE__ == $0
  tier = ARGV[0]

  puts "🎯 Leyline Document Refactoring Workflow"
  puts

  if tier
    puts "Processing tier: #{tier}"
  else
    puts "Processing all tiers (use argument to specify: 1, 2, 3)"
  end

  puts "This workflow will:"
  puts "  1. Analyze documents for verbosity patterns"
  puts "  2. Create backups before refactoring"
  puts "  3. Provide refactoring guidance"
  puts "  4. Wait for manual refactoring"
  puts "  5. Validate results"
  puts "  6. Run comprehensive validation suite"
  puts
  puts "Continue? (y/N)"

  response = STDIN.gets.chomp.downcase
  if response == 'y' || response == 'yes'
    workflow = BatchRefactoringWorkflow.new
    workflow.run_workflow(tier)
  else
    puts "Aborted."
  end
end
