# frozen_string_literal: true

# Shared examples for testing Leyline error classes
# Following Kent Beck's approach: make testing errors trivial
RSpec.shared_examples 'a leyline error' do
  # Every error should be a StandardError
  it 'inherits from StandardError' do
    expect(described_class).to be < StandardError
  end

  # Errors should have a clear message
  describe '#message' do
    let(:error_message) { 'Something went wrong' }
    let(:error) { described_class.new(error_message) }

    it 'returns the provided message' do
      expect(error.message).to eq(error_message)
    end

    it 'has a non-empty message' do
      expect(error.message).not_to be_empty
    end
  end

  # Errors should be raiseable and catchable
  describe 'raising and rescuing' do
    it 'can be raised' do
      expect { raise described_class.new('test error') }.to raise_error(described_class)
    end

    it 'can be rescued as StandardError' do
      result = begin
        raise described_class.new('test error')
        'not reached'
      rescue StandardError => e
        e.message
      end
      expect(result).to eq('test error')
    end
  end
end

RSpec.shared_examples 'an error with context' do
  # Errors with context should store additional debugging information
  describe '#context' do
    let(:error_message) { 'Operation failed' }
    let(:context_data) { { file_path: '/tmp/test.txt', operation: 'read' } }
    let(:error) { described_class.new(error_message, context_data) }

    it 'stores context data' do
      expect(error).to respond_to(:context)
      expect(error.context).to eq(context_data)
    end

    it 'returns frozen context to prevent mutation' do
      expect(error.context).to be_frozen
    end

    it 'works without context data' do
      error_without_context = described_class.new(error_message)
      expect(error_without_context.context).to eq({})
    end
  end
end

RSpec.shared_examples 'an error with recovery suggestions' do
  # Errors should provide actionable recovery suggestions
  describe '#recovery_suggestions' do
    let(:error) { described_class.new('test error') }

    it 'responds to recovery_suggestions' do
      expect(error).to respond_to(:recovery_suggestions)
    end

    it 'returns an array of suggestions' do
      expect(error.recovery_suggestions).to be_an(Array)
    end

    it 'returns string suggestions' do
      error.recovery_suggestions.each do |suggestion|
        expect(suggestion).to be_a(String)
      end
    end

    it 'returns non-empty suggestions when applicable' do
      # This is flexible - some errors might not have suggestions
      suggestions = error.recovery_suggestions
      if suggestions.any?
        suggestions.each do |suggestion|
          expect(suggestion).not_to be_empty
        end
      end
    end
  end
end

RSpec.shared_examples 'a testable error' do
  # Following Kent Beck: errors should be easy to test
  describe 'testability' do
    it 'can be instantiated without side effects' do
      # Creating an error should not perform I/O or have side effects
      expect { described_class.new('test') }.not_to output.to_stdout
      expect { described_class.new('test') }.not_to output.to_stderr
    end

    it 'provides meaningful inspect output' do
      error = described_class.new('test error')
      expect(error.inspect).to include(described_class.name)
      expect(error.inspect).to include('test error')
    end

    it 'can be compared for equality' do
      error1 = described_class.new('same message')
      error2 = described_class.new('same message')
      error3 = described_class.new('different message')

      # Same class and message should be considered similar
      expect(error1.message).to eq(error2.message)
      expect(error1.class).to eq(error2.class)
      expect(error1.message).not_to eq(error3.message)
    end
  end
end
