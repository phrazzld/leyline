# frozen_string_literal: true

require 'spec_helper'
require 'leyline/configuration/leyline_file'
require 'tmpdir'
require 'fileutils'

RSpec.describe Leyline::Configuration::LeylineFile do
  let(:temp_dir) { Dir.mktmpdir }
  let(:leyline_file_path) { File.join(temp_dir, '.leyline') }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '.load' do
    context 'when .leyline file exists' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript\n  - go")
      end

      it 'returns a LeylineFile instance' do
        result = described_class.load(temp_dir)
        expect(result).to be_a(described_class)
      end

      it 'parses the configuration correctly' do
        result = described_class.load(temp_dir)
        expect(result.categories).to eq(['typescript', 'go'])
      end
    end

    context 'when .leyline file does not exist' do
      it 'returns nil' do
        result = described_class.load(temp_dir)
        expect(result).to be_nil
      end
    end

    context 'when directory does not exist' do
      it 'returns nil' do
        result = described_class.load('/nonexistent/directory')
        expect(result).to be_nil
      end
    end

    context 'with default directory' do
      around do |example|
        original_pwd = Dir.pwd
        Dir.chdir(temp_dir)
        example.run
      ensure
        Dir.chdir(original_pwd)
      end

      it 'uses current directory when no directory specified' do
        File.write('.leyline', "categories:\n  - rust")
        result = described_class.load
        expect(result.categories).to eq(['rust'])
      end
    end
  end

  describe '#initialize' do
    context 'with valid YAML configuration' do
      let(:config_content) do
        <<~YAML
          categories:
            - typescript
            - go
            - rust
          version: ">=2.0.0"
          docs_path: "custom/docs/path"
        YAML
      end

      before do
        File.write(leyline_file_path, config_content)
      end

      it 'parses all configuration fields correctly' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq(['typescript', 'go', 'rust'])
        expect(leyline_file.version).to eq('>=2.0.0')
        expect(leyline_file.docs_path).to eq('custom/docs/path')
        expect(leyline_file).to be_valid
      end

      it 'provides hash representation' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.to_h).to eq({
          categories: ['typescript', 'go', 'rust'],
          version: '>=2.0.0',
          docs_path: 'custom/docs/path'
        })
      end
    end

    context 'with minimal valid configuration' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript")
      end

      it 'uses default values for missing fields' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq(['typescript'])
        expect(leyline_file.version).to be_nil
        expect(leyline_file.docs_path).to eq('docs/leyline')
      end
    end

    context 'with empty file' do
      before do
        File.write(leyline_file_path, '')
      end

      it 'uses default values' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq([])
        expect(leyline_file.version).to be_nil
        expect(leyline_file.docs_path).to eq('docs/leyline')
        expect(leyline_file).to be_valid
      end
    end

    context 'with only whitespace' do
      before do
        File.write(leyline_file_path, "   \n  \n   ")
      end

      it 'treats as empty and uses defaults' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq([])
        expect(leyline_file.version).to be_nil
        expect(leyline_file.docs_path).to eq('docs/leyline')
        expect(leyline_file).to be_valid
      end
    end
  end

  describe 'categories parsing' do
    context 'with valid categories array' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript\n  - go\n  - rust")
      end

      it 'parses categories correctly' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.categories).to eq(['typescript', 'go', 'rust'])
      end
    end

    context 'with duplicate categories' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript\n  - go\n  - typescript")
      end

      it 'removes duplicates' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.categories).to eq(['typescript', 'go'])
      end
    end

    context 'with mixed valid and invalid categories' do
      before do
        File.write(leyline_file_path, <<~YAML)
          categories:
            - typescript
            - ""
            - go
            - 123
            - rust
        YAML
      end

      it 'filters out invalid categories and reports errors' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq(['typescript', 'go', 'rust'])
        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors).to include(match(/Invalid categories.*"", 123/))
      end
    end

    context 'with core category explicitly listed' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript\n  - core\n  - go")
      end

      it 'silently removes core category' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.categories).to eq(['typescript', 'go'])
        expect(leyline_file).to be_valid
      end
    end

    context 'with "all" category' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript\n  - all\n  - go")
      end

      it 'reports error for "all" category' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors).to include("Use specific category names instead of 'all'")
      end
    end

    context 'when categories is not an array' do
      before do
        File.write(leyline_file_path, "categories: typescript")
      end

      it 'reports error and defaults to empty array' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq([])
        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors).to include('categories must be an array')
      end
    end

    context 'when categories is nil' do
      before do
        File.write(leyline_file_path, "version: '>=1.0.0'")
      end

      it 'defaults to empty array' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.categories).to eq([])
      end
    end
  end

  describe 'version parsing' do
    context 'with valid version constraints' do
      [
        '>=2.0.0',
        '>1.5.0',
        '<=3.0.0',
        '<2.0.0',
        '=1.0.0',
        '~>1.2.0',
        '>=1.0',
        '>2.5'
      ].each do |version|
        it "accepts version constraint: #{version}" do
          File.write(leyline_file_path, "version: '#{version}'")
          leyline_file = described_class.new(leyline_file_path)

          expect(leyline_file.version).to eq(version)
          expect(leyline_file).to be_valid
        end
      end
    end

    context 'with invalid version constraints' do
      [
        'invalid',
        '1.0.0',
        'version-1.0',
        '>',
        '>=',
        '1.0.0-beta'
      ].each do |version|
        it "rejects invalid version: #{version}" do
          File.write(leyline_file_path, "version: '#{version}'")
          leyline_file = described_class.new(leyline_file_path)

          expect(leyline_file.version).to be_nil
          expect(leyline_file).not_to be_valid
          expect(leyline_file.errors).to include("Invalid version constraint: #{version}")
        end
      end
    end

    context 'when version is not a string' do
      before do
        File.write(leyline_file_path, "version: 123")
      end

      it 'reports error and defaults to nil' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.version).to be_nil
        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors).to include('version must be a string')
      end
    end

    context 'when version is nil' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript")
      end

      it 'defaults to nil' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.version).to be_nil
      end
    end
  end

  describe 'docs_path parsing' do
    context 'with valid docs_path' do
      before do
        File.write(leyline_file_path, "docs_path: 'custom/documentation/path'")
      end

      it 'uses provided docs_path' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.docs_path).to eq('custom/documentation/path')
      end
    end

    context 'with docs_path that needs trimming' do
      before do
        File.write(leyline_file_path, "docs_path: '  custom/path  '")
      end

      it 'trims whitespace from docs_path' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.docs_path).to eq('custom/path')
      end
    end

    context 'when docs_path is not a string' do
      before do
        File.write(leyline_file_path, "docs_path: 123")
      end

      it 'reports error and uses default' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.docs_path).to eq('docs/leyline')
        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors).to include('docs_path must be a string')
      end
    end

    context 'when docs_path is nil' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript")
      end

      it 'uses default docs_path' do
        leyline_file = described_class.new(leyline_file_path)
        expect(leyline_file.docs_path).to eq('docs/leyline')
      end
    end
  end

  describe 'unknown keys handling' do
    context 'with unknown configuration keys' do
      before do
        File.write(leyline_file_path, <<~YAML)
          categories:
            - typescript
          version: ">=1.0.0"
          docs_path: "docs"
          unknown_key: "value"
          another_unknown: 123
        YAML
      end

      it 'reports unknown keys as errors' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors).to include('Unknown configuration keys: unknown_key, another_unknown')
      end

      it 'still parses known keys correctly' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq(['typescript'])
        expect(leyline_file.version).to eq('>=1.0.0')
        expect(leyline_file.docs_path).to eq('docs')
      end
    end
  end

  describe 'YAML syntax error handling' do
    context 'with malformed YAML' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript\n  unclosed: 'quote")
      end

      it 'reports YAML syntax error' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors.first).to match(/YAML syntax error:/)
      end

      it 'uses default values when parsing fails' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file.categories).to eq([])
        expect(leyline_file.version).to be_nil
        expect(leyline_file.docs_path).to eq('docs/leyline')
      end
    end

    context 'with non-hash YAML root' do
      before do
        File.write(leyline_file_path, "- item1\n- item2")
      end

      it 'reports configuration structure error' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors).to include('Configuration must be a YAML hash')
      end
    end
  end

  describe 'file system error handling' do
    context 'when file cannot be read' do
      let(:nonexistent_file) { '/nonexistent/path/.leyline' }

      it 'reports parsing error' do
        leyline_file = described_class.new(nonexistent_file)

        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors.first).to match(/Failed to parse configuration:/)
      end
    end

    context 'when file has permission issues' do
      before do
        File.write(leyline_file_path, "categories:\n  - typescript")
        File.chmod(0000, leyline_file_path)
      end

      after do
        File.chmod(0644, leyline_file_path) # Restore permissions for cleanup
      end

      it 'reports parsing error' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file).not_to be_valid
        expect(leyline_file.errors.first).to match(/Failed to parse configuration:/)
      end
    end
  end

  describe 'error collection and validation' do
    context 'with multiple validation errors' do
      before do
        File.write(leyline_file_path, <<~YAML)
          categories: "not an array"
          version: "invalid-version"
          docs_path: 123
          unknown_field: "value"
        YAML
      end

      it 'collects all validation errors' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file).not_to be_valid
        errors = leyline_file.errors

        expect(errors).to include('categories must be an array')
        expect(errors).to include('Invalid version constraint: invalid-version')
        expect(errors).to include('docs_path must be a string')
        expect(errors).to include('Unknown configuration keys: unknown_field')
      end

      it 'returns a copy of errors array' do
        leyline_file = described_class.new(leyline_file_path)

        errors1 = leyline_file.errors
        errors2 = leyline_file.errors

        expect(errors1).to eq(errors2)
        expect(errors1).not_to be(errors2)  # Different object instances
      end
    end

    context 'with valid configuration' do
      before do
        File.write(leyline_file_path, <<~YAML)
          categories:
            - typescript
            - go
          version: ">=2.0.0"
          docs_path: "docs/custom"
        YAML
      end

      it 'reports no validation errors' do
        leyline_file = described_class.new(leyline_file_path)

        expect(leyline_file).to be_valid
        expect(leyline_file.errors).to be_empty
      end
    end
  end

  describe Leyline::Configuration::LeylineFile::ConfigurationError do
    let(:error) { described_class.new('Test configuration error') }

    it 'has correct error type' do
      expect(error.error_type).to eq(:configuration)
    end

    it 'provides helpful recovery suggestions' do
      suggestions = error.recovery_suggestions

      expect(suggestions).to include('Check .leyline file syntax (must be valid YAML)')
      expect(suggestions).to include('Ensure categories is an array of strings')
      expect(suggestions).to include('Validate version constraint format (e.g., ">=2.0.0")')
      expect(suggestions).to include('Run leyline categories to see available categories')
    end
  end
end
