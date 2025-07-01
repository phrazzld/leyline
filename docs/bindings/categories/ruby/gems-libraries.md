---
derived_from: modularity
enforced_by: RubyGems standards & review
id: ruby-gems-libraries
last_modified: '2025-07-01'
version: '0.1.0'
---
# Binding: Ruby Gems & Libraries

Create reusable, well-documented Ruby gems following community standards.

## Rules

- **Semantic versioning** (MAJOR.MINOR.PATCH) for releases
- **Gemspec configuration** with proper metadata and dependencies
- **YARD documentation** for all public APIs
- **RSpec tests** with high coverage for public interfaces
- **CI/CD pipeline** for automated testing and publishing

## Examples

```ruby
# ✅ GOOD: Proper gemspec
Gem::Specification.new do |spec|
  spec.name = 'my_awesome_gem'
  spec.version = MyAwesomeGem::VERSION
  spec.authors = ['Developer Name']
  spec.email = ['dev@example.com']

  spec.summary = 'A brief, one-line description'
  spec.description = 'A longer description explaining what the gem does'
  spec.homepage = 'https://github.com/user/my_awesome_gem'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.0.0'

  spec.files = Dir.glob('{lib,exe}/**/*') + %w[README.md LICENSE.txt]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'thor', '~> 1.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'yard', '~> 0.9'
end

# YARD documentation
class MyAwesomeGem
  # Processes data according to specified options
  #
  # @param data [Array<String>] the input data to process
  # @param options [Hash] processing options
  # @option options [Boolean] :reverse (false) whether to reverse the data
  # @option options [Integer] :limit (nil) maximum items to process
  # @return [Array<String>] the processed data
  # @raise [ArgumentError] if data is not an array
  # @example Basic usage
  #   processor = MyAwesomeGem.new
  #   result = processor.process(['a', 'b', 'c'])
  #   #=> ['a', 'b', 'c']
  # @example With options
  #   result = processor.process(['a', 'b', 'c'], reverse: true, limit: 2)
  #   #=> ['c', 'b']
  def process(data, options = {})
    raise ArgumentError, 'data must be an array' unless data.is_a?(Array)

    result = data.dup
    result.reverse! if options[:reverse]
    result = result.first(options[:limit]) if options[:limit]
    result
  end
end
```

```ruby
# ✅ GOOD: Version management
module MyAwesomeGem
  VERSION = '1.2.3'
end

# Changelog following Keep a Changelog format
## [1.2.3] - 2025-07-01
### Fixed
- Fix edge case in data processing
### Changed
- Improve error messages for invalid input

## [1.2.0] - 2025-06-15
### Added
- New `limit` option for processing
### Deprecated
- Old `max_items` parameter (use `limit` instead)

## [1.1.0] - 2025-06-01
### Added
- Support for reverse processing
```

```ruby
# ✅ GOOD: Library structure
my_awesome_gem/
├── lib/
│   ├── my_awesome_gem.rb        # Main entry point
│   ├── my_awesome_gem/
│   │   ├── version.rb           # Version constant
│   │   ├── processor.rb         # Core functionality
│   │   └── cli.rb              # CLI interface
├── spec/
│   ├── spec_helper.rb
│   ├── my_awesome_gem_spec.rb
│   └── my_awesome_gem/
│       └── processor_spec.rb
├── exe/
│   └── my_awesome_gem          # Executable
├── my_awesome_gem.gemspec
├── Gemfile
├── README.md
├── LICENSE.txt
└── CHANGELOG.md

# RSpec testing
RSpec.describe MyAwesomeGem::Processor do
  describe '#process' do
    it 'processes array data' do
      processor = described_class.new
      result = processor.process(['a', 'b', 'c'])
      expect(result).to eq(['a', 'b', 'c'])
    end

    it 'raises error for non-array input' do
      processor = described_class.new
      expect { processor.process('string') }.to raise_error(ArgumentError)
    end
  end
end
```

```ruby
# ❌ BAD: Poor gem structure
# No proper gemspec
# No version management
# No documentation
# No tests
# Unclear file organization

# Bad gemspec
Gem::Specification.new do |spec|
  spec.name = 'gem'  # Too generic
  # Missing required fields
  spec.files = Dir['**/*']  # Includes everything
end

# No documentation
def process(data, opts)
  # What does this do? What are the parameters?
  # No error handling
  data.reverse if opts
end
```
