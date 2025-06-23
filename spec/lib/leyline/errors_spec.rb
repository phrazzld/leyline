# frozen_string_literal: true

require 'spec_helper'
require 'leyline/errors'

RSpec.describe Leyline::LeylineError do
  describe '#initialize' do
    it 'creates error with message' do
      error = described_class.new('Test error')
      expect(error.message).to eq('Test error')
    end

    it 'accepts operation and context' do
      error = described_class.new('Test error', operation: :test, context: { file: 'test.rb' })
      expect(error.operation).to eq(:test)
      expect(error.context).to eq({ file: 'test.rb' })
    end

    it 'builds formatted message with context' do
      error = described_class.new('Test error', operation: :test, context: { file: 'test.rb' })
      expect(error.message).to include('Test error')
      expect(error.message).to include('Operation: test')
      expect(error.message).to include('file: test.rb')
    end

    it 'handles nil context gracefully' do
      error = described_class.new('Test error', context: nil)
      expect(error.context).to eq({})
    end
  end

  describe '#recovery_suggestions' do
    it 'provides default recovery suggestions' do
      error = described_class.new('Test error')
      suggestions = error.recovery_suggestions

      expect(suggestions).to be_an(Array)
      expect(suggestions).not_to be_empty
      expect(suggestions.first).to include('--verbose')
    end
  end

  describe '#platform_specific_suggestions' do
    it 'provides platform-specific suggestions' do
      error = described_class.new('Test error')
      suggestions = error.platform_specific_suggestions

      expect(suggestions).to be_an(Array)
      # Should provide suggestions based on current platform
    end
  end

  describe '#to_h' do
    it 'serializes error to hash' do
      error = described_class.new('Test error', operation: :test, context: { file: 'test.rb' })
      hash = error.to_h

      expect(hash).to include(
        error_class: 'Leyline::LeylineError',
        message: include('Test error'),
        operation: :test,
        context: { file: 'test.rb' },
        category: :general
      )
      expect(hash[:timestamp]).to be_a(String)
      expect(hash[:platform]).to be_a(Symbol)
    end
  end
end

RSpec.describe Leyline::ConflictDetectedError do
  let(:conflicts) do
    [
      double(path: 'file1.md', type: :both_modified),
      double(path: 'file2.md', type: :local_added)
    ]
  end

  describe '#initialize' do
    it 'accepts array of conflicts' do
      error = described_class.new(conflicts)
      expect(error.conflicts).to eq(conflicts)
    end

    it 'accepts single conflict' do
      conflict = conflicts.first
      error = described_class.new(conflict)
      expect(error.conflicts).to eq([conflict])
    end

    it 'builds descriptive message' do
      error = described_class.new(conflicts)
      expect(error.message).to include('2 conflicts detected')
      expect(error.message).to include('file1.md, file2.md')
    end

    it 'handles many conflicts' do
      many_conflicts = (1..5).map { |i| double(path: "file#{i}.md") }
      error = described_class.new(many_conflicts)
      expect(error.message).to include('5 conflicts detected')
      expect(error.message).to include('and 2 more')
    end
  end

  describe '#recovery_suggestions' do
    it 'provides conflict-specific recovery suggestions' do
      error = described_class.new(conflicts)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/--force/))
      expect(suggestions).to include(match(/diff/))
      expect(suggestions).to include(match(/backup/))
    end
  end

  describe '#conflicted_paths' do
    it 'extracts paths from conflicts' do
      error = described_class.new(conflicts)
      expect(error.conflicted_paths).to eq(['file1.md', 'file2.md'])
    end

    it 'handles conflicts without path method' do
      simple_conflicts = ['file1.md', 'file2.md']
      error = described_class.new(simple_conflicts)
      expect(error.conflicted_paths).to eq(['file1.md', 'file2.md'])
    end
  end

  describe '#conflict_count' do
    it 'returns number of conflicts' do
      error = described_class.new(conflicts)
      expect(error.conflict_count).to eq(2)
    end
  end
end

RSpec.describe Leyline::InvalidSyncStateError do
  describe '#initialize' do
    it 'uses default message when none provided' do
      error = described_class.new
      expect(error.message).to include('invalid or corrupted')
    end

    it 'accepts custom message' do
      error = described_class.new('Custom sync error')
      expect(error.message).to include('Custom sync error')
    end

    it 'stores state file path' do
      error = described_class.new(state_file: '/path/to/state.yaml')
      expect(error.state_file).to eq('/path/to/state.yaml')
    end

    it 'stores validation errors' do
      errors = ['Invalid YAML', 'Missing required field']
      error = described_class.new(validation_errors: errors)
      expect(error.validation_errors).to eq(errors)
    end
  end

  describe '#recovery_suggestions' do
    it 'provides basic recovery suggestions' do
      error = described_class.new
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/--force/))
      expect(suggestions).to include(match(/permissions/))
    end

    it 'includes state file specific suggestions' do
      error = described_class.new(state_file: '/path/to/state.yaml')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(%r{rm '/path/to/state.yaml'}))
      expect(suggestions).to include(match(/disk space/))
    end

    it 'includes validation error details' do
      errors = ['Invalid YAML', 'Missing field']
      error = described_class.new(validation_errors: errors)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/Invalid YAML, Missing field/))
    end
  end
end

RSpec.describe Leyline::ComparisonFailedError do
  describe '#initialize' do
    it 'stores file paths' do
      error = described_class.new('file_a.txt', 'file_b.txt')
      expect(error.file_a).to eq('file_a.txt')
      expect(error.file_b).to eq('file_b.txt')
    end

    it 'stores reason for failure' do
      error = described_class.new('file_a.txt', 'file_b.txt', reason: 'Permission denied')
      expect(error.reason).to eq('Permission denied')
    end

    it 'builds descriptive message' do
      error = described_class.new('file_a.txt', 'file_b.txt', reason: 'Permission denied')
      expect(error.message).to include('Failed to compare files')
      expect(error.message).to include('file_a.txt')
      expect(error.message).to include('file_b.txt')
      expect(error.message).to include('Permission denied')
    end
  end

  describe '#recovery_suggestions' do
    it 'provides general recovery suggestions' do
      error = described_class.new('file_a.txt', 'file_b.txt')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/readable/))
    end

    it 'provides permission-specific suggestions' do
      error = described_class.new('file_a.txt', 'file_b.txt', reason: 'Permission denied')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/permissions/))
      expect(suggestions).to include(match(/ls -la/))
    end

    it 'provides encoding-specific suggestions' do
      error = described_class.new('file_a.txt', 'file_b.txt', reason: 'Encoding error')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/UTF-8/))
      expect(suggestions).to include(match(/file.*command/))
    end

    it 'provides size-specific suggestions' do
      error = described_class.new('file_a.txt', 'file_b.txt', reason: 'File too large')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/too large/))
      expect(suggestions).to include(match(/memory/))
    end

    it 'provides lock-specific suggestions' do
      error = described_class.new('file_a.txt', 'file_b.txt', reason: 'File locked')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/locked/))
      expect(suggestions).to include(match(/other processes/))
    end
  end
end

RSpec.describe Leyline::RemoteAccessError do
  describe '#initialize' do
    it 'stores URL and operation type' do
      error = described_class.new('Network error', url: 'https://github.com/repo', operation_type: :fetch)
      expect(error.url).to eq('https://github.com/repo')
      expect(error.operation_type).to eq(:fetch)
    end

    it 'stores HTTP status code' do
      error = described_class.new('Not found', http_status: 404)
      expect(error.http_status).to eq(404)
    end
  end

  describe '#recovery_suggestions' do
    it 'provides auth-specific suggestions for 401/403' do
      error = described_class.new('Unauthorized', http_status: 401)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/credentials/))
      expect(suggestions).to include(match(/access/))
    end

    it 'provides not-found suggestions for 404' do
      error = described_class.new('Not found', http_status: 404)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/URL.*correct/))
      expect(suggestions).to include(match(/exists/))
    end

    it 'provides network suggestions for 5xx errors' do
      error = described_class.new('Server error', http_status: 503)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/retry/))
      expect(suggestions).to include(match(/connection/))
    end

    it 'provides rate limiting suggestions for 429' do
      error = described_class.new('Rate limited', http_status: 429)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/Rate limited/))
      expect(suggestions).to include(match(/wait/))
    end

    it 'includes DNS suggestions when URL provided' do
      error = described_class.new('DNS error', url: 'https://github.com/repo')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/nslookup github.com/))
    end
  end
end

RSpec.describe Leyline::CacheOperationError do
  describe '#initialize' do
    it 'stores cache path and operation type' do
      error = described_class.new('Cache error', cache_path: '/cache/file', operation_type: :write)
      expect(error.cache_path).to eq('/cache/file')
      expect(error.operation_type).to eq(:write)
    end
  end

  describe '#recovery_suggestions' do
    it 'provides write-specific suggestions' do
      error = described_class.new('Write failed', operation_type: :write)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/disk space/))
      expect(suggestions).to include(match(/permissions/))
    end

    it 'provides read-specific suggestions' do
      error = described_class.new('Read failed', operation_type: :read)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/corrupted/))
      expect(suggestions).to include(match(/clearing/))
    end

    it 'provides delete-specific suggestions' do
      error = described_class.new('Delete failed', operation_type: :delete)
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/locked/))
      expect(suggestions).to include(match(/write permissions/))
    end

    it 'includes general cache suggestions' do
      error = described_class.new('Cache error')
      suggestions = error.recovery_suggestions

      expect(suggestions).to include(match(/LEYLINE_CACHE_DIR/))
      expect(suggestions).to include(match(/concurrent/))
    end
  end
end

RSpec.describe Leyline::PlatformError do
  describe '#initialize' do
    it 'stores platform operation' do
      error = described_class.new('Platform error', platform_operation: :file_locking)
      expect(error.platform_operation).to eq(:file_locking)
    end
  end

  describe '#recovery_suggestions' do
    it 'provides file locking suggestions' do
      error = described_class.new('File locked', platform_operation: :file_locking)
      suggestions = error.recovery_suggestions

      # Should provide platform-specific file locking advice
      expect(suggestions).not_to be_empty
    end

    it 'provides permission suggestions' do
      error = described_class.new('Permission denied', platform_operation: :permissions)
      suggestions = error.recovery_suggestions

      # Should provide platform-specific permission advice
      expect(suggestions).not_to be_empty
    end
  end
end

RSpec.describe Leyline::ErrorHandler do
  let(:test_class) do
    Class.new do
      include Leyline::ErrorHandler

      def test_method
        raise Leyline::ConflictDetectedError.new(['file1.md'])
      end
    end
  end

  let(:instance) { test_class.new }

  describe '.handle_transparency_errors' do
    it 'catches and handles ConflictDetectedError' do
      expect do
        test_class.handle_transparency_errors { instance.test_method }
      end.to output(/Conflicts detected/).to_stderr.and raise_error(SystemExit)
    end

    it 'catches and handles InvalidSyncStateError' do
      expect do
        test_class.handle_transparency_errors do
          raise Leyline::InvalidSyncStateError.new
        end
      end.to output(/Sync state error/).to_stderr.and raise_error(SystemExit)
    end

    it 'catches and handles ComparisonFailedError' do
      expect do
        test_class.handle_transparency_errors do
          raise Leyline::ComparisonFailedError.new('file1', 'file2')
        end
      end.to output(/File comparison failed/).to_stderr.and raise_error(SystemExit)
    end

    it 'catches and handles RemoteAccessError' do
      expect do
        test_class.handle_transparency_errors do
          raise Leyline::RemoteAccessError.new('Network error')
        end
      end.to output(/Remote access failed/).to_stderr.and raise_error(SystemExit)
    end

    it 'catches and handles CacheOperationError' do
      expect do
        test_class.handle_transparency_errors do
          raise Leyline::CacheOperationError.new('Cache error')
        end
      end.to output(/Cache operation failed/).to_stderr.and raise_error(SystemExit)
    end

    it 'catches and handles PlatformError' do
      expect do
        test_class.handle_transparency_errors do
          raise Leyline::PlatformError.new('Platform error')
        end
      end.to output(/Platform-specific error/).to_stderr.and raise_error(SystemExit)
    end

    it 'catches and handles generic LeylineError' do
      expect do
        test_class.handle_transparency_errors do
          raise Leyline::LeylineError.new('Generic error')
        end
      end.to output(/Operation failed/).to_stderr.and raise_error(SystemExit)
    end
  end
end
