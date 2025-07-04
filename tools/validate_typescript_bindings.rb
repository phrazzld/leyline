#!/usr/bin/env ruby
# tools/validate_typescript_bindings.rb - Automated validation of TypeScript binding configurations
# Validates that all configuration examples in TypeScript binding documents work correctly
#
# This script creates isolated test environments for each binding, extracts configuration
# examples from documentation, and verifies they work through practical execution.
#
# Requirements:
# - Ruby 2.1+ (for Time.now.iso8601 and JSON support)
# - Node.js 18+ and pnpm for TypeScript toolchain
# - Standard library: fileutils, tmpdir, json, time
#
# Usage:
# - Validate all bindings: ruby tools/validate_typescript_bindings.rb
# - Verbose output: ruby tools/validate_typescript_bindings.rb --verbose

require 'fileutils'
require 'tmpdir'
require 'json'
require 'time'
require 'optparse'

# Configuration for structured logging and verbose output
$structured_logging = ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
$correlation_id = "ts-validation-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{rand(1000)}"
$verbose = false

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: validate_typescript_bindings.rb [options]'
  opts.separator ''
  opts.separator 'Automated validation of TypeScript binding configuration examples'
  opts.separator ''
  opts.separator 'Options:'

  opts.on('-v', '--verbose', 'Show detailed output from validation commands') do
    $verbose = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end

  opts.separator ''
  opts.separator 'Environment Variables:'
  opts.separator '  LEYLINE_STRUCTURED_LOGGING=true  Enable JSON structured logging to STDERR'
  opts.separator ''
  opts.separator 'Exit Codes:'
  opts.separator '  0 - All binding configurations validated successfully'
  opts.separator '  1 - One or more binding validations failed'
end.parse!

# Configuration mapping for TypeScript bindings to validate
BINDINGS_TO_VALIDATE = [
  {
    name: 'modern-typescript-toolchain',
    doc: 'docs/bindings/categories/typescript/modern-typescript-toolchain.md',
    configs: {
      'package.json' => 'json',
      'tsconfig.json' => 'json'
    },
    checks: %w[install build test lint]
  },
  {
    name: 'package-json-standards',
    doc: 'docs/bindings/categories/typescript/package-json-standards.md',
    configs: {
      'package.json' => 'json'
    },
    checks: %w[install audit]
  },
  {
    name: 'tsup-build-system',
    doc: 'docs/bindings/categories/typescript/tsup-build-system.md',
    configs: {
      'tsup.config.ts' => 'typescript'
    },
    checks: %w[install build]
  },
  {
    name: 'vitest-testing-framework',
    doc: 'docs/bindings/categories/typescript/vitest-testing-framework.md',
    configs: {
      'vitest.config.ts' => 'typescript'
    },
    checks: %w[install test]
  },
  {
    name: 'eslint-prettier-setup',
    doc: 'docs/bindings/categories/typescript/eslint-prettier-setup.md',
    configs: {
      'eslint.config.js' => 'javascript',
      '.prettierrc' => 'json'
    },
    checks: %w[install lint format]
  }
].freeze

def log_structured(event, data = {})
  return unless $structured_logging

  begin
    log_entry = {
      event: event,
      correlation_id: $correlation_id,
      timestamp: Time.now.iso8601,
      **data
    }

    warn JSON.generate(log_entry)
  rescue StandardError => e
    # Graceful degradation if structured logging fails
    warn "Warning: Structured logging failed: #{e.message}"
  end
end

# Execute a shell command with proper error handling and output capture
def run_command(cmd, binding_name, check_type)
  log_structured('validation_command_start', {
                   binding: binding_name,
                   check: check_type,
                   command: cmd
                 })

  start_time = Time.now

  if $verbose
    puts "    Running: #{cmd}"
    success = system(cmd)
  else
    success = system(cmd, out: '/dev/null', err: '/dev/null')
  end

  duration = (Time.now - start_time).round(3)

  if success
    log_structured('validation_command_success', {
                     binding: binding_name,
                     check: check_type,
                     duration_seconds: duration
                   })
    true
  else
    exit_code = $?.exitstatus
    log_structured('validation_command_failure', {
                     binding: binding_name,
                     check: check_type,
                     duration_seconds: duration,
                     exit_code: exit_code
                   })

    puts "    ❌ Command failed (exit code #{exit_code}): #{cmd}"
    false
  end
end

# Extract code block from markdown file for a specific language
def extract_code_block(doc_path, lang)
  content = File.read(doc_path)

  # Handle different language aliases
  lang_patterns = case lang.downcase
                  when 'json'
                    %w[json jsonc]
                  when 'javascript', 'js'
                    %w[javascript js]
                  when 'typescript', 'ts'
                    %w[typescript ts]
                  else
                    [lang]
                  end

  # Try each language pattern
  lang_patterns.each do |pattern|
    match = content.match(/```#{pattern}\s*\n(?<code>.*?)```/m)
    return match[:code] if match
  end

  # If no specific language block found, try without language specifier
  match = content.match(/```\s*\n(?<code>.*?)```/m)
  return match[:code] if match

  raise "No '#{lang}' code block found in #{doc_path}"
end

# Create minimal project scaffolding for testing configurations
def create_project_scaffold(dir, binding_name)
  # Create standard project structure
  FileUtils.mkdir_p(File.join(dir, 'src'))
  FileUtils.mkdir_p(File.join(dir, 'tests'))

  # Create basic TypeScript source file
  File.write(File.join(dir, 'src/index.ts'), <<~TS)
    export const greet = (name: string): string => {
      return `Hello, ${name}!`;
    };

    export const add = (a: number, b: number): number => {
      return a + b;
    };
  TS

  # Create basic test file
  File.write(File.join(dir, 'tests/index.test.ts'), <<~TEST)
    import { describe, it, expect } from 'vitest';
    import { greet, add } from '../src/index';

    describe('greet function', () => {
      it('should return a greeting message', () => {
        expect(greet('World')).toBe('Hello, World!');
      });
    });

    describe('add function', () => {
      it('should add two numbers correctly', () => {
        expect(add(2, 3)).toBe(5);
      });
    });
  TEST

  # Add default package.json if none extracted
  unless File.exist?(File.join(dir, 'package.json'))
    File.write(File.join(dir, 'package.json'), <<~JSON)
      {
        "name": "#{binding_name}-validation",
        "version": "0.1.0",
        "type": "module",
        "packageManager": "pnpm@10.12.1",
        "engines": {
          "node": ">=18.0.0"
        },
        "scripts": {
          "build": "tsup src/index.ts --format esm,cjs --dts",
          "test": "vitest run --coverage",
          "lint": "eslint .",
          "format": "prettier --write .",
          "format:check": "prettier --check .",
          "audit": "pnpm audit --audit-level=moderate"
        },
        "devDependencies": {
          "typescript": "^5.0.0",
          "tsup": "^8.0.0",
          "vitest": "^1.0.0",
          "@vitest/coverage-v8": "^1.0.0",
          "eslint": "^8.57.0",
          "@typescript-eslint/parser": "^7.0.0",
          "@typescript-eslint/eslint-plugin": "^7.0.0",
          "prettier": "^3.2.0"
        }
      }
    JSON
  end

  # Add default tsconfig.json if none extracted
  unless File.exist?(File.join(dir, 'tsconfig.json'))
    File.write(File.join(dir, 'tsconfig.json'), <<~JSON)
      {
        "compilerOptions": {
          "target": "ESNext",
          "lib": ["ESNext"],
          "module": "ESNext",
          "moduleResolution": "bundler",
          "declaration": true,
          "strict": true,
          "esModuleInterop": true,
          "allowSyntheticDefaultImports": true,
          "forceConsistentCasingInFileNames": true,
          "skipLibCheck": true,
          "isolatedModules": true,
          "outDir": "./dist"
        },
        "include": ["src/**/*", "tests/**/*"],
        "exclude": ["node_modules", "dist"]
      }
    JSON
  end

  # Add default configs for specific tools if not extracted
  add_default_tool_configs(dir)
end

def add_default_tool_configs(dir)
  # Default tsup config if not present
  unless File.exist?(File.join(dir, 'tsup.config.ts'))
    File.write(File.join(dir, 'tsup.config.ts'), <<~TS)
      import { defineConfig } from 'tsup';

      export default defineConfig({
        entry: ['src/index.ts'],
        format: ['esm', 'cjs'],
        dts: true,
        sourcemap: true,
        clean: true,
        minify: false
      });
    TS
  end

  # Default vitest config if not present
  unless File.exist?(File.join(dir, 'vitest.config.ts'))
    File.write(File.join(dir, 'vitest.config.ts'), <<~TS)
      import { defineConfig } from 'vitest/config';

      export default defineConfig({
        test: {
          coverage: {
            provider: 'v8',
            thresholds: {
              lines: 80,
              functions: 80,
              branches: 80,
              statements: 80
            }
          }
        }
      });
    TS
  end

  # Default ESLint config if not present
  unless File.exist?(File.join(dir, 'eslint.config.js'))
    File.write(File.join(dir, 'eslint.config.js'), <<~JS)
      import tseslint from '@typescript-eslint/eslint-plugin';
      import tsparser from '@typescript-eslint/parser';

      export default [
        {
          // Global ignore patterns - must be first
          ignores: [
            'dist/**/*',
            'build/**/*',
            'coverage/**/*',
            'node_modules/**/*',
            '*.d.ts',
            '**/*.d.ts',
            '.pnpm-lock.yaml',
            'pnpm-lock.yaml'
          ]
        },
        {
          // JavaScript files
          files: ['**/*.{js,mjs,cjs}'],
          languageOptions: {
            ecmaVersion: 'latest',
            sourceType: 'module'
          },
          rules: {
            'no-unused-vars': 'error',
            'no-console': 'warn'
          }
        },
        {
          // TypeScript source and test files with type-aware linting
          files: ['src/**/*.{ts,tsx}', 'tests/**/*.{ts,tsx}'],
          languageOptions: {
            ecmaVersion: 'latest',
            sourceType: 'module',
            parser: tsparser,
            parserOptions: {
              project: './tsconfig.json',
              tsconfigRootDir: '.'
            }
          },
          plugins: {
            '@typescript-eslint': tseslint
          },
          rules: {
            // Disable base ESLint rules that conflict with TypeScript
            'no-unused-vars': 'off',
            '@typescript-eslint/no-unused-vars': 'error',
            'no-console': 'warn'
          }
        },
        {
          // TypeScript config files without project-based typing
          files: ['*.{ts,tsx}', '**/*.config.{ts,tsx}'],
          languageOptions: {
            ecmaVersion: 'latest',
            sourceType: 'module',
            parser: tsparser
          },
          plugins: {
            '@typescript-eslint': tseslint
          },
          rules: {
            'no-unused-vars': 'off',
            '@typescript-eslint/no-unused-vars': 'error',
            'no-console': 'warn'
          }
        }
      ];
    JS
  end

  # Default Prettier config if not present
  return if File.exist?(File.join(dir, '.prettierrc'))

  File.write(File.join(dir, '.prettierrc'), <<~JSON)
    {
      "semi": true,
      "trailingComma": "es5",
      "singleQuote": true,
      "printWidth": 80,
      "tabWidth": 2
    }
  JSON
end

# Main validation function for a single binding
def validate_binding(binding)
  binding_name = binding[:name]
  log_structured('binding_validation_start', {
                   binding: binding_name,
                   doc: binding[:doc],
                   configs: binding[:configs].keys,
                   checks: binding[:checks]
                 })

  puts "\n🔍 Validating #{binding_name}..."
  start_time = Time.now

  Dir.mktmpdir("binding-#{binding_name}-") do |tmpdir|
    Dir.chdir(tmpdir) do
      # Extract and write configuration files from documentation
      binding[:configs].each do |filename, lang|
        puts "  📄 Extracting #{filename} from documentation..."

        begin
          code = extract_code_block(binding[:doc], lang)
          FileUtils.mkdir_p(File.dirname(filename))
          File.write(filename, code)
          puts "    ✅ #{filename} extracted successfully"
        rescue StandardError => e
          puts "    ⚠️  Could not extract #{filename}: #{e.message}"
          puts '    📝 Will use default configuration for validation'
        end
      end

      # Create project scaffolding
      create_project_scaffold(tmpdir, binding_name)

      # Run validation checks
      binding[:checks].each do |check|
        puts "  🔧 Running #{check} check..."

        case check
        when 'install'
          success = run_command('pnpm install', binding_name, check)
        when 'build'
          success = run_command('pnpm run build', binding_name, check)
        when 'test'
          success = run_command('pnpm run test', binding_name, check)
        when 'lint'
          success = run_command('pnpm run lint', binding_name, check)
        when 'format'
          success = run_command('pnpm run format:check', binding_name, check)
        when 'audit'
          success = run_command('pnpm audit --audit-level=moderate', binding_name, check)
        else
          puts "    ⚠️  Unknown check type: #{check}"
          success = false
        end

        raise "#{check.capitalize} check failed" unless success
      end

      duration = (Time.now - start_time).round(3)
      puts "  ✅ All checks passed for #{binding_name} (#{duration}s)"

      log_structured('binding_validation_success', {
                       binding: binding_name,
                       duration_seconds: duration,
                       checks_passed: binding[:checks].length
                     })

      return true
    rescue StandardError => e
      duration = (Time.now - start_time).round(3)
      puts "  ❌ Validation failed for #{binding_name}: #{e.message}"

      log_structured('binding_validation_failure', {
                       binding: binding_name,
                       duration_seconds: duration,
                       error: e.message
                     })

      return false
    end
  end
end

# Check prerequisites
def check_prerequisites
  puts '🔍 Checking prerequisites...'

  # Check Ruby
  unless system('ruby --version >/dev/null 2>&1')
    puts '❌ Ruby not found'
    return false
  end

  # Check Node.js
  unless system('node --version >/dev/null 2>&1')
    puts '❌ Node.js not found - required for TypeScript toolchain'
    puts '   Install Node.js 18+ from https://nodejs.org/'
    return false
  end

  # Check pnpm
  unless system('pnpm --version >/dev/null 2>&1')
    puts '❌ pnpm not found - required for package management'
    puts '   Install with: npm install -g pnpm'
    return false
  end

  puts '✅ All prerequisites available'
  true
end

# Main execution function
def main
  log_structured('typescript_validation_start', {
                   tool: 'validate_typescript_bindings',
                   bindings_count: BINDINGS_TO_VALIDATE.length,
                   verbose: $verbose
                 })

  puts '🚀 TypeScript Binding Configuration Validation'
  puts '=============================================='
  puts "Correlation ID: #{$correlation_id}"
  puts "Bindings to validate: #{BINDINGS_TO_VALIDATE.length}"
  puts ''

  # Check prerequisites
  unless check_prerequisites
    puts "\n❌ Prerequisites check failed"
    exit 1
  end

  start_time = Time.now
  failed_bindings = []

  # Validate each binding
  BINDINGS_TO_VALIDATE.each do |binding|
    failed_bindings << binding[:name] unless validate_binding(binding)
  end

  # Summary
  total_duration = (Time.now - start_time).round(3)
  puts "\n📊 Validation Summary"
  puts '===================='

  if failed_bindings.empty?
    puts "✅ All #{BINDINGS_TO_VALIDATE.length} TypeScript binding configurations validated successfully!"
    puts '🎉 Configuration examples are working correctly'
    puts "⏱️  Total time: #{total_duration}s"

    log_structured('typescript_validation_success', {
                     duration_seconds: total_duration,
                     bindings_validated: BINDINGS_TO_VALIDATE.length,
                     failed_bindings: []
                   })

    exit 0
  else
    puts "❌ #{failed_bindings.length} binding(s) failed validation:"
    failed_bindings.each { |binding| puts "   • #{binding}" }
    puts ''
    puts '💡 Review the error messages above and fix the configuration issues'
    puts "⏱️  Total time: #{total_duration}s"

    log_structured('typescript_validation_failure', {
                     duration_seconds: total_duration,
                     bindings_validated: BINDINGS_TO_VALIDATE.length,
                     failed_bindings: failed_bindings,
                     failed_count: failed_bindings.length
                   })

    exit 1
  end
end

# Run main function
main
