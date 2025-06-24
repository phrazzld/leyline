# frozen_string_literal: true

require 'digest'
require 'fileutils'
require_relative 'errors'
require_relative 'platform_helper'

module Leyline
  # File comparison service for transparency commands
  # Provides specialized comparison methods for diff, status, and update operations
  # Leverages existing FileSyncer SHA256 patterns for consistency and performance
  class FileComparator
    class ComparisonError < StandardError; end

    def initialize(cache: nil, base_directory: nil)
      @cache = cache
      @base_directory = base_directory
    end

    # Compare local files against remote leyline content for a specific category
    # Returns hash with added, modified, removed files
    def compare_with_remote(local_path, category)
      raise ComparisonError, "Local path does not exist: #{local_path}" unless Dir.exist?(local_path)
      raise ComparisonError, "Category cannot be nil or empty" if category.nil? || category.strip.empty?

      local_files = discover_local_files(local_path, category)
      remote_files = discover_remote_files(category)

      {
        added: remote_files.keys - local_files.keys,
        modified: detect_modified_files(local_files, remote_files),
        removed: local_files.keys - remote_files.keys,
        unchanged: detect_unchanged_files(local_files, remote_files)
      }
    end

    # Detect modifications between base manifest and current files
    # Returns array of file paths that have been modified
    def detect_modifications(base_manifest, current_files)
      return [] if base_manifest.nil? || current_files.nil?

      modifications = []

      current_files.each do |file_path|
        next unless File.exist?(file_path)

        current_hash = content_hash(file_path)
        base_hash = base_manifest[file_path]

        if base_hash.nil? || current_hash != base_hash
          modifications << file_path
        end
      end

      modifications
    end

    # Generate diff data between two files
    # Returns hash with file info and content comparison
    def generate_diff_data(file_a, file_b)
      raise ComparisonError, "File A does not exist: #{file_a}" unless File.exist?(file_a)
      raise ComparisonError, "File B does not exist: #{file_b}" unless File.exist?(file_b)

      begin
        {
          file_a: file_a,
          file_b: file_b,
          identical: files_identical?(file_a, file_b),
          size_a: File.size(file_a),
          size_b: File.size(file_b),
          hash_a: content_hash(file_a),
          hash_b: content_hash(file_b),
          modified_time_a: File.mtime(file_a),
          modified_time_b: File.mtime(file_b)
        }
      rescue Errno::EACCES => e
        raise ComparisonFailedError.new(
          "Permission denied comparing files",
          reason: :permission_denied,
          file_a: file_a,
          file_b: file_b
        )
      rescue Encoding::InvalidByteSequenceError => e
        raise ComparisonFailedError.new(
          "File encoding error during comparison",
          reason: :encoding_error,
          file_a: file_a,
          file_b: file_b
        )
      end
    end

    # Create file manifest for tracking sync state
    # Returns hash mapping file paths to their SHA256 hashes
    def create_manifest(file_paths)
      manifest = {}

      file_paths.each do |file_path|
        next unless File.exist?(file_path)

        begin
          manifest[file_path] = content_hash(file_path)
        rescue ComparisonFailedError => e
          # For manifest creation, we can continue with warnings for individual file failures
          if e.context[:reason] == :permission_denied
            warn "Warning: Permission denied reading #{file_path}" if defined?(@verbose) && @verbose
          elsif e.context[:reason] == :encoding_error
            warn "Warning: Encoding error in #{file_path}" if defined?(@verbose) && @verbose
          else
            warn "Warning: Could not hash file #{file_path}: #{e.message}"
          end
        rescue => e
          # Skip files that can't be read but don't fail entire operation
          warn "Warning: Could not hash file #{file_path}: #{e.message}"
        end
      end

      manifest
    end

    # Check if file contents are identical using SHA256 comparison
    # Leverages existing FileSyncer pattern with cache optimization
    def files_identical?(file_a, file_b)
      return false unless File.exist?(file_a) && File.exist?(file_b)
      return true if file_a == file_b

      # Handle platform-specific path normalization
      if PlatformHelper.windows?
        # Windows: case-insensitive comparison
        return true if file_a.downcase == file_b.downcase
      end

      # Quick size check first
      return false if File.size(file_a) != File.size(file_b)

      # Use content hashing for accurate comparison
      hash_a = content_hash(file_a)
      hash_b = content_hash(file_b)

      hash_a == hash_b
    rescue => e
      # If we can't read files for comparison, assume they're different
      false
    end

    private

    # Compute SHA256 hash of file content with cache optimization
    # Reuses FileSyncer's proven SHA256 pattern for consistency
    def content_hash(file_path)
      content = File.read(file_path)
      hash = Digest::SHA256.hexdigest(content)

      # Cache the content for future use if cache is available
      if @cache
        begin
          @cache.put(content)
        rescue => e
          # Cache errors should not interrupt file comparison
          # Error is already logged by FileCache
        end
      end

      hash
    rescue Errno::ENOENT => e
      raise ComparisonFailedError.new(
        file_path, nil,
        reason: :file_not_found
      )
    rescue Errno::EACCES => e
      raise ComparisonFailedError.new(
        file_path, nil,
        reason: :permission_denied
      )
    rescue Errno::EMFILE, Errno::ENFILE => e
      raise ComparisonFailedError.new(
        file_path, nil,
        reason: :too_many_files,
        suggestion: 'Close other applications or increase file descriptor limit'
      )
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
      raise ComparisonFailedError.new(
        file_path, nil,
        reason: :encoding_error
      )
    rescue IOError => e
      if e.message.include?('closed stream')
        raise ComparisonFailedError.new(
          file_path, nil,
          reason: :concurrent_modification
        )
      else
        raise ComparisonError, "Failed to read file #{file_path}: #{e.message}"
      end
    rescue => e
      raise ComparisonError, "Failed to read file #{file_path}: #{e.message}"
    end

    # Discover local files for a specific category
    def discover_local_files(local_path, category)
      files = {}
      category_path = File.join(local_path, 'docs', 'leyline')

      return files unless Dir.exist?(category_path)

      patterns = build_category_patterns(category)
      patterns.each do |pattern|
        search_path = File.join(category_path, pattern)
        Dir.glob(search_path).each do |file_path|
          next unless File.file?(file_path)

          relative_path = file_path.sub("#{category_path}/", '')
          files[relative_path] = content_hash(file_path)
        end
      end

      files
    rescue => e
      raise ComparisonError, "Failed to discover local files: #{e.message}"
    end

    # Discover remote files for a specific category (placeholder)
    # This will be implemented when transparency commands need remote comparison
    def discover_remote_files(category)
      # TODO: Implement remote file discovery using GitClient
      # For now, return empty hash to support testing and initial implementation
      {}
    end

    # Build file patterns for category filtering (reuse sync logic)
    def build_category_patterns(category)
      patterns = []

      # Always include tenets and core bindings
      patterns << 'tenets/**/*.md'
      patterns << 'bindings/core/**/*.md'

      # Add category-specific bindings
      unless category == 'core'
        patterns << "bindings/categories/#{category}/**/*.md"
      end

      patterns
    end

    # Detect files that have been modified between local and remote
    def detect_modified_files(local_files, remote_files)
      modified = []

      local_files.each do |file_path, local_hash|
        remote_hash = remote_files[file_path]
        if remote_hash && local_hash != remote_hash
          modified << file_path
        end
      end

      modified
    end

    # Detect files that are unchanged between local and remote
    def detect_unchanged_files(local_files, remote_files)
      unchanged = []

      local_files.each do |file_path, local_hash|
        remote_hash = remote_files[file_path]
        if remote_hash && local_hash == remote_hash
          unchanged << file_path
        end
      end

      unchanged
    end
  end
end
