# frozen_string_literal: true

require 'spec_helper'
require 'leyline/errors'

RSpec.describe 'Cache-specific errors' do
  describe Leyline::CacheError do
    it_behaves_like 'a leyline error' do
      let(:described_class) { Leyline::CacheError }
    end

    it_behaves_like 'an error with context' do
      let(:described_class) { Leyline::CacheError }
    end

    describe 'CacheCorruptionError' do
      before do
        stub_const('Leyline::CacheCorruptionError', Class.new(Leyline::CacheError) do
          def recovery_suggestions
            [
              'Clear the cache directory: rm -rf ~/.cache/leyline',
              'Run sync with --no-cache flag to bypass cache',
              'Set LEYLINE_CACHE_AUTO_RECOVERY=true for automatic recovery'
            ]
          end
        end)
      end

      let(:error) { Leyline::CacheCorruptionError.new('Cache file corrupted', file: '/path/to/cache') }

      it 'provides cache recovery suggestions' do
        suggestions = error.recovery_suggestions
        expect(suggestions).to include('Clear the cache directory: rm -rf ~/.cache/leyline')
        expect(suggestions).to include('Run sync with --no-cache flag to bypass cache')
      end

      it 'includes file path in context' do
        expect(error.context[:file]).to eq('/path/to/cache')
      end
    end

    describe 'CachePermissionError' do
      before do
        stub_const('Leyline::CachePermissionError', Class.new(Leyline::CacheError) do
          def recovery_suggestions
            [
              'Check cache directory permissions',
              'Ensure you have write access to cache directory',
              'Try: chmod -R u+rw ~/.cache/leyline',
              'Or set a different cache directory: export LEYLINE_CACHE_DIR=/tmp/leyline-cache'
            ]
          end
        end)
      end

      let(:error) { Leyline::CachePermissionError.new('Permission denied', directory: '~/.cache/leyline') }

      it 'suggests permission fixes' do
        suggestions = error.recovery_suggestions
        expect(suggestions).to include('Check cache directory permissions')
        expect(suggestions).to include('Try: chmod -R u+rw ~/.cache/leyline')
      end

      it 'suggests alternative cache directory' do
        suggestions = error.recovery_suggestions
        expect(suggestions.any? { |s| s.include?('LEYLINE_CACHE_DIR') }).to be true
      end
    end
  end
end
