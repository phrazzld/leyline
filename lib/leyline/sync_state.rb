# frozen_string_literal: true

require 'yaml'
require 'time'
require 'fileutils'
require_relative 'cache/cache_error_handler'
require_relative 'version'

module Leyline
  # Manages sync state persistence for transparency commands
  # Tracks sync metadata including timestamp, version, categories, and file manifest
  # Stores state in human-readable YAML format in cache directory
  class SyncState
    class SyncStateError < StandardError; end

    SCHEMA_VERSION = 1
    STATE_FILENAME = 'sync_state.yaml'

    def initialize(cache_dir = nil)
      @cache_dir = cache_dir || ENV.fetch('LEYLINE_CACHE_DIR', '~/.cache/leyline')
      @cache_dir = File.expand_path(@cache_dir)
      @state_file_path = File.join(@cache_dir, STATE_FILENAME)
    end

    # Save sync state metadata to YAML file
    # Returns true on success, false on failure
    def save_sync_state(metadata)
      validate_metadata!(metadata)

      state_data = build_state_data(metadata)

      ensure_cache_directory

      # Atomic write with temp file for safety
      temp_file = "#{@state_file_path}.tmp"

      begin
        File.write(temp_file, state_data.to_yaml)
        File.rename(temp_file, @state_file_path)
        true
      rescue StandardError => e
        # Clean up temp file if it exists
        File.delete(temp_file) if File.exist?(temp_file)

        Cache::CacheErrorHandler.handle_error(e, 'save_sync_state', {
                                                state_file: @state_file_path
                                              })
        false
      end
    end

    # Load sync state from YAML file
    # Returns hash with state data or nil if not available/corrupt
    def load_sync_state
      return nil unless state_exists?

      begin
        content = File.read(@state_file_path)
        state = YAML.safe_load(content, permitted_classes: [Time])

        # Validate loaded state structure
        validate_state_structure!(state)

        state
      rescue StandardError => e
        Cache::CacheErrorHandler.handle_error(e, 'load_sync_state', {
                                                state_file: @state_file_path
                                              })
        nil
      end
    end

    # Check if sync state file exists
    def state_exists?
      File.exist?(@state_file_path)
    end

    # Clear sync state (useful for force syncs or recovery)
    # Returns true on success, false on failure
    def clear_sync_state
      return true unless state_exists?

      begin
        File.delete(@state_file_path)
        true
      rescue StandardError => e
        Cache::CacheErrorHandler.handle_error(e, 'clear_sync_state', {
                                                state_file: @state_file_path
                                              })
        false
      end
    end

    # Get age of sync state in seconds
    # Returns nil if state doesn't exist or can't be read
    def state_age_seconds
      return nil unless state_exists?

      Time.now - File.mtime(@state_file_path)
    rescue StandardError
      nil
    end

    # Get cache directory path
    def cache_directory
      @cache_dir
    end

    # Get state file path (useful for debugging)
    attr_reader :state_file_path

    # Compare current files against sync state manifest
    # Returns comparison data or nil if no valid state
    def compare_with_current_files(current_file_manifest)
      state = load_sync_state
      return nil unless state && state['manifest']

      base_manifest = state['manifest']
      base_files = Set.new(base_manifest.keys)
      current_files = Set.new(current_file_manifest.keys)

      {
        base_timestamp: state['timestamp'],
        base_version: state['leyline_version'],
        base_categories: state['categories'],
        added: current_files - base_files,
        removed: base_files - current_files,
        modified: detect_modified_files(base_manifest, current_file_manifest),
        unchanged: detect_unchanged_files(base_manifest, current_file_manifest)
      }
    end

    private

    def validate_metadata!(metadata)
      raise SyncStateError, 'Metadata cannot be nil' if metadata.nil?
      raise SyncStateError, 'Categories must be an array' unless metadata[:categories].is_a?(Array)
      raise SyncStateError, 'Manifest must be a hash' unless metadata[:manifest].is_a?(Hash)

      # Validate manifest values are strings (SHA256 hashes)
      metadata[:manifest].each do |file, hash|
        unless hash.is_a?(String) && hash.match?(/\A[a-f0-9]{64}\z/)
          raise SyncStateError, "Invalid hash for file #{file}: #{hash}"
        end
      end
    end

    def build_state_data(metadata)
      {
        'version' => SCHEMA_VERSION,
        'timestamp' => Time.now.utc.iso8601,
        'leyline_version' => metadata[:leyline_version] || VERSION,
        'categories' => metadata[:categories],
        'manifest' => metadata[:manifest],
        'metadata' => build_optional_metadata(metadata)
      }
    end

    def build_optional_metadata(metadata)
      optional = {}

      # Include performance metrics if available
      optional['total_files'] = metadata[:manifest].size
      optional['cache_hit_ratio'] = metadata[:cache_hit_ratio] if metadata[:cache_hit_ratio]
      optional['sync_duration_ms'] = metadata[:sync_duration_ms] if metadata[:sync_duration_ms]

      optional
    end

    def validate_state_structure!(state)
      raise SyncStateError, 'Invalid state structure' unless state.is_a?(Hash)
      raise SyncStateError, 'Missing version' unless state['version']
      raise SyncStateError, 'Missing timestamp' unless state['timestamp']
      raise SyncStateError, 'Missing categories' unless state['categories'].is_a?(Array)
      raise SyncStateError, 'Missing manifest' unless state['manifest'].is_a?(Hash)

      # Validate schema version compatibility
      return unless state['version'] > SCHEMA_VERSION

      raise SyncStateError, "Incompatible state version #{state['version']} (expected <= #{SCHEMA_VERSION})"
    end

    def ensure_cache_directory
      return if Dir.exist?(@cache_dir)

      begin
        FileUtils.mkdir_p(@cache_dir)
      rescue StandardError => e
        Cache::CacheErrorHandler.handle_error(e, 'ensure_cache_directory', {
                                                cache_dir: @cache_dir
                                              })
        raise SyncStateError, "Failed to create cache directory: #{e.message}"
      end
    end

    def detect_modified_files(base_manifest, current_manifest)
      modified = []

      base_manifest.each do |file_path, base_hash|
        current_hash = current_manifest[file_path]
        modified << file_path if current_hash && current_hash != base_hash
      end

      modified
    end

    def detect_unchanged_files(base_manifest, current_manifest)
      unchanged = []

      base_manifest.each do |file_path, base_hash|
        current_hash = current_manifest[file_path]
        unchanged << file_path if current_hash && current_hash == base_hash
      end

      unchanged
    end
  end
end
