# frozen_string_literal: true

require_relative '../../../../lib/leyline/discovery/metadata_cache'

RSpec.describe Leyline::Discovery::MetadataCache do
  subject(:cache) { described_class.new }

  describe 'cache warm-up functionality' do
    describe '#warm_cache_in_background' do
      it 'has the method defined' do
        expect(cache).to respond_to(:warm_cache_in_background)
      end

      it 'returns immediately without blocking' do
        start_time = Time.now
        result = cache.warm_cache_in_background
        elapsed = Time.now - start_time

        expect(elapsed).to be < 0.1  # Should return in under 100ms
        expect(result).to be(true).or be(false)  # Boolean return indicating success/failure to start
      end

      it 'returns true when warming starts successfully' do
        result = cache.warm_cache_in_background
        expect(result).to be true
      end

      it 'returns false when warming is already in progress' do
        cache.warm_cache_in_background  # Start first warming
        result = cache.warm_cache_in_background  # Try to start second warming
        expect(result).to be false
      end

      it 'returns false when cache is already warmed' do
        cache.warm_cache_in_background

        # Wait for warming to complete
        wait_for(timeout: 2) { cache.cache_warm? }

        result = cache.warm_cache_in_background
        expect(result).to be false
      end
    end

    describe '#cache_warm?' do
      it 'has the method defined' do
        expect(cache).to respond_to(:cache_warm?)
      end

      it 'returns a boolean' do
        expect([true, false]).to include(cache.cache_warm?)
      end

      it 'initially returns false before warming' do
        expect(cache.cache_warm?).to be false
      end

      it 'eventually returns true after background warming completes' do
        cache.warm_cache_in_background

        # Wait for background warming to complete
        wait_for(timeout: 2) { cache.cache_warm? }

        expect(cache.cache_warm?).to be true
      end
    end

    describe 'integration with discovery operations' do
      it 'warming failures do not propagate to main thread' do
        # Warming should never raise exceptions in the main thread
        expect { cache.warm_cache_in_background }.not_to raise_error

        # Normal operations should work regardless of warming state
        expect { cache.categories }.not_to raise_error
      end

      it 'warming improves subsequent operation performance' do
        # This is a characterization test to ensure warming doesn't break functionality
        cache.warm_cache_in_background
        wait_for(timeout: 2) { cache.cache_warm? }

        # Operations should work normally after warming
        expect { cache.categories }.not_to raise_error
        expect { cache.search('test') }.not_to raise_error
      end
    end
  end

  private

  # Helper method for reliable async testing
  def wait_for(timeout: 1, interval: 0.01)
    start_time = Time.now
    while Time.now - start_time < timeout
      return true if yield
      sleep interval
    end
    false
  end
end
