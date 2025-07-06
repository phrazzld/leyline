#!/usr/bin/env ruby

require 'yaml'

class VerbosityAnalyzer
  TENET_LIMIT = 150
  BINDING_LIMIT = 400

  VERBOSITY_PATTERNS = {
    'multiple_languages' => {
      patterns: [/```\w+/, /```typescript/, /```python/, /```go/, /```rust/, /```java/],
      description: 'Multiple code language examples'
    },
    'tool_configurations' => {
      patterns: [/```yaml/, /```toml/, /```json/, /package\.json/, /Cargo\.toml/, /setup\.py/, /pyproject\.toml/],
      description: 'Tool-specific configuration examples'
    },
    'installation_procedures' => {
      patterns: [/npm install/, /pip install/, /cargo install/, /apt-get/, /brew install/, /curl.*install/],
      description: 'Installation and setup procedures'
    },
    'repetitive_bullets' => {
      patterns: [/^\s*-.*-.*-/, /^\s*\*.*\*.*\*/, /^\s*[•·]/],
      description: 'Repetitive bullet point structures'
    },
    'verbose_analogies' => {
      patterns: [/think of.*like/, /imagine.*as/, /consider.*similar/, /works like.*in/i],
      description: 'Extended analogies and metaphors'
    },
    'tool_comparisons' => {
      patterns: [/vs\./, /compared to/, /alternative to/, /instead of/, /\|\s*Tool\s*\|/, /comparison/i],
      description: 'Tool comparison sections and matrices'
    },
    'troubleshooting' => {
      patterns: [/troubleshoot/i, /common issues/i, /problems/i, /if.*fails/, /error.*occurs/],
      description: 'Troubleshooting and error handling sections'
    },
    'step_by_step' => {
      patterns: [/step\s+\d+/i, /first.*second.*third/i, /^\s*\d+\.\s/, /then.*next.*finally/i],
      description: 'Step-by-step tutorial content'
    },
    'platform_specific' => {
      patterns: [/windows/i, /macos/i, /linux/i, /ubuntu/i, /debian/i, /centos/i],
      description: 'Platform-specific implementation details'
    },
    'version_specifics' => {
      patterns: [/version\s+\d/, /v\d+\.\d+/, />=\s*\d/, /\^\d+/, /~\d+/, /latest/],
      description: 'Version-specific details and constraints'
    }
  }.freeze

  def initialize
    @results = {}
  end

  def analyze_documents
    puts "🔍 Analyzing document verbosity patterns...\n\n"

    # Get all oversized documents
    oversized_docs = find_oversized_documents

    # Analyze each document
    oversized_docs.each do |doc_path, info|
      analyze_document(doc_path, info)
    end

    # Generate summary report
    generate_report
  end

  private

  def find_oversized_documents
    docs = {}

    # Find all markdown files in binding/tenet directories
    markdown_files = Dir.glob([
                                'docs/tenets/*.md',
                                'docs/bindings/**/*.md'
                              ]).reject { |f| f.include?('/00-index.md') }

    markdown_files.each do |file_path|
      line_count = count_lines(file_path)

      # Determine if document is oversized
      is_tenet = file_path.include?('/tenets/')
      limit = is_tenet ? TENET_LIMIT : BINDING_LIMIT

      next unless line_count > limit

      excess = line_count - limit
      docs[file_path] = {
        line_count: line_count,
        limit: limit,
        excess: excess,
        category: categorize_document(file_path),
        is_tenet: is_tenet
      }
    end

    docs
  end

  def count_lines(file_path)
    File.readlines(file_path).count
  rescue StandardError => e
    puts "Warning: Could not read #{file_path}: #{e.message}"
    0
  end

  def categorize_document(file_path)
    case file_path
    when %r{/typescript/}
      'TypeScript'
    when %r{/python/}
      'Python'
    when %r{/go/}
      'Go'
    when %r{/rust/}
      'Rust'
    when %r{/database/}
      'Database'
    when %r{/security/}
      'Security'
    when %r{/frontend/}, %r{/react/}
      'Frontend'
    when %r{/core/}
      'Core'
    when %r{/tenets/}
      'Tenets'
    else
      'Other'
    end
  end

  def analyze_document(file_path, info)
    content = File.read(file_path)
    doc_patterns = {}

    # Count occurrences of each verbosity pattern
    VERBOSITY_PATTERNS.each do |pattern_name, pattern_info|
      matches = 0
      pattern_info[:patterns].each do |regex|
        matches += content.scan(regex).length
      end
      next unless matches > 0

      doc_patterns[pattern_name] = {
        count: matches,
        description: pattern_info[:description]
      }
    end

    # Calculate code block languages
    code_languages = content.scan(/```(\w+)/).flatten.uniq.sort

    @results[file_path] = {
      info: info,
      patterns: doc_patterns,
      code_languages: code_languages,
      estimated_reduction: estimate_reduction_potential(doc_patterns, info[:excess])
    }
  end

  def estimate_reduction_potential(patterns, excess_lines)
    # Estimate potential line reduction based on patterns found
    reduction_score = 0

    # Multiple languages contribute heavily to verbosity
    if patterns['multiple_languages'] && patterns['multiple_languages'][:count] > 4
      reduction_score += [excess_lines * 0.4, 200].min # Up to 40% reduction
    end

    # Tool configurations and installation procedures
    if patterns['tool_configurations'] && patterns['tool_configurations'][:count] > 3
      reduction_score += [excess_lines * 0.2, 100].min # Up to 20% reduction
    end

    if patterns['installation_procedures'] && patterns['installation_procedures'][:count] > 2
      reduction_score += [excess_lines * 0.15, 80].min # Up to 15% reduction
    end

    # Step-by-step and troubleshooting content
    if patterns['step_by_step'] && patterns['step_by_step'][:count] > 5
      reduction_score += [excess_lines * 0.1, 50].min # Up to 10% reduction
    end

    reduction_score.round
  end

  def generate_report
    puts '📊 VERBOSITY ANALYSIS REPORT'
    puts '=' * 50
    puts

    # Summary by category
    generate_category_summary
    puts

    # Top verbosity patterns
    generate_pattern_summary
    puts

    # Priority recommendations
    generate_priority_recommendations
    puts

    # Individual document analysis
    generate_detailed_analysis
  end

  def generate_category_summary
    puts '📁 DOCUMENTS BY CATEGORY'
    puts '-' * 25

    by_category = @results.group_by { |_, data| data[:info][:category] }

    by_category.sort_by do |category, _docs|
      case category
      when 'TypeScript', 'Python', 'Go' then 0 # High priority
      when 'Core', 'Database', 'Security' then 1 # Medium priority
      else 2 # Low priority
      end
    end.each do |category, docs|
      total_excess = docs.sum { |_, data| data[:info][:excess] }
      avg_excess = total_excess / docs.length

      puts "  #{category}: #{docs.length} documents"
      puts "    Total excess: #{total_excess} lines"
      puts "    Average excess: #{avg_excess} lines"
      puts
    end
  end

  def generate_pattern_summary
    puts '🔍 TOP VERBOSITY PATTERNS'
    puts '-' * 25

    pattern_totals = {}

    @results.each do |_, data|
      data[:patterns].each do |pattern_name, pattern_data|
        pattern_totals[pattern_name] ||= { count: 0, docs: 0 }
        pattern_totals[pattern_name][:count] += pattern_data[:count]
        pattern_totals[pattern_name][:docs] += 1
      end
    end

    pattern_totals.sort_by { |_, data| -data[:docs] }.first(8).each do |pattern_name, data|
      description = VERBOSITY_PATTERNS[pattern_name][:description]
      puts "  #{description}:"
      puts "    Found in #{data[:docs]} documents (#{data[:count]} total occurrences)"
      puts
    end
  end

  def generate_priority_recommendations
    puts '🎯 REFACTORING PRIORITY RECOMMENDATIONS'
    puts '-' * 38

    # High-impact documents (high excess + high reduction potential)
    high_impact = @results.select do |_, data|
      data[:info][:excess] > 200 && data[:estimated_reduction] > 100
    end.sort_by { |_, data| -data[:estimated_reduction] }

    puts 'HIGH IMPACT (tackle first):'
    high_impact.first(8).each do |file_path, data|
      category = data[:info][:category]
      excess = data[:info][:excess]
      reduction = data[:estimated_reduction]
      filename = File.basename(file_path)

      puts "  #{filename} (#{category}): #{excess} excess → ~#{reduction} reduction potential"
    end
    puts

    # Quick wins (low excess but easy to fix)
    quick_wins = @results.select do |_, data|
      data[:info][:excess] < 100 && data[:estimated_reduction] > 30
    end.sort_by { |_, data| data[:info][:excess] }

    puts 'QUICK WINS (easy fixes):'
    quick_wins.first(6).each do |file_path, data|
      category = data[:info][:category]
      excess = data[:info][:excess]
      filename = File.basename(file_path)

      puts "  #{filename} (#{category}): #{excess} excess lines"
    end
    puts
  end

  def generate_detailed_analysis
    puts '📋 DETAILED DOCUMENT ANALYSIS'
    puts '-' * 30

    @results.sort_by { |_, data| -data[:info][:excess] }.each do |file_path, data|
      filename = File.basename(file_path)
      info = data[:info]

      puts "#{filename} (#{info[:category]})"
      puts "  Lines: #{info[:line_count]} (#{info[:excess]} over #{info[:limit]} limit)"
      puts "  Estimated reduction potential: #{data[:estimated_reduction]} lines"

      puts "  Code languages: #{data[:code_languages].join(', ')}" if data[:code_languages].any?

      if data[:patterns].any?
        puts '  Verbosity patterns found:'
        data[:patterns].sort_by { |_, pattern_data| -pattern_data[:count] }.each do |_pattern_name, pattern_data|
          puts "    - #{pattern_data[:description]}: #{pattern_data[:count]} occurrences"
        end
      end

      puts
    end
  end
end

# Run analysis if script is executed directly
if __FILE__ == $0
  analyzer = VerbosityAnalyzer.new
  analyzer.analyze_documents
end
