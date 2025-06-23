# frozen_string_literal: true

require 'spec_helper'
require 'leyline/errors'

RSpec.describe 'Configuration-specific errors' do
  describe Leyline::ConfigurationError do
    it_behaves_like 'a leyline error' do
      let(:described_class) { Leyline::ConfigurationError }
    end

    describe 'InvalidConfigurationError' do
      before do
        stub_const('Leyline::InvalidConfigurationError', Class.new(Leyline::ConfigurationError) do
          def recovery_suggestions
            suggestions = []

            if context[:key]
              suggestions << "Check the value of '#{context[:key]}' in your configuration"
            end

            if context[:expected]
              suggestions << "Expected: #{context[:expected]}"
            end

            suggestions << 'Review leyline configuration documentation'
            suggestions << 'Use --verbose flag for detailed configuration validation'
            suggestions
          end
        end)
      end

      it 'provides context-aware suggestions' do
        error = Leyline::InvalidConfigurationError.new(
          'Invalid configuration value',
          key: 'cache_threshold',
          expected: 'number between 0 and 1',
          actual: '2.0'
        )

        suggestions = error.recovery_suggestions
        expect(suggestions).to include("Check the value of 'cache_threshold' in your configuration")
        expect(suggestions).to include('Expected: number between 0 and 1')
      end
    end

    describe 'MissingConfigurationError' do
      before do
        stub_const('Leyline::MissingConfigurationError', Class.new(Leyline::ConfigurationError) do
          def recovery_suggestions
            [
              "Set the required configuration: #{context[:key]}",
              "Example: export #{context[:key]}=#{context[:example]}" || '',
              'Check environment variables and config files'
            ].compact
          end
        end)
      end

      it 'suggests how to set missing configuration' do
        error = Leyline::MissingConfigurationError.new(
          'Required configuration missing',
          key: 'LEYLINE_REPO_URL',
          example: 'https://github.com/your-org/leyline.git'
        )

        suggestions = error.recovery_suggestions
        expect(suggestions).to include('Set the required configuration: LEYLINE_REPO_URL')
        expect(suggestions).to include('Example: export LEYLINE_REPO_URL=https://github.com/your-org/leyline.git')
      end
    end
  end
end
