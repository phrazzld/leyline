# frozen_string_literal: true

require 'fileutils'
require 'digest'

module Leyline
  module Sync
    class FileSyncer
      class SyncError < StandardError; end

      def initialize(source_directory, target_directory, cache: nil)
        @source_directory = source_directory
        @target_directory = target_directory
        @cache = cache
        @sync_results = {
          copied: [],
          skipped: [],
          errors: []
        }
      end

      def sync(force: false)
        unless Dir.exist?(@source_directory)
          raise SyncError, "Source directory does not exist: #{@source_directory}"
        end

        # Create target directory if it doesn't exist
        FileUtils.mkdir_p(@target_directory) unless Dir.exist?(@target_directory)

        # Find all files in source directory
        source_files = find_files(@source_directory)

        source_files.each do |source_file|
          sync_file(source_file, force: force)
        end

        @sync_results
      end

      private

      def find_files(directory)
        files = []
        Dir.glob("**/*", base: directory).each do |relative_path|
          full_path = File.join(directory, relative_path)
          files << relative_path if File.file?(full_path)
        end
        files
      end

      def sync_file(relative_path, force: false)
        source_path = File.join(@source_directory, relative_path)
        target_path = File.join(@target_directory, relative_path)

        # Create target directory if needed
        target_dir = File.dirname(target_path)
        FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

        # Check if target file exists
        target_existed = File.exist?(target_path)
        if target_existed
          if !files_different?(source_path, target_path)
            # Files are identical, skip copying
            @sync_results[:skipped] << relative_path
            return
          elsif !force
            # Files are different and no force flag, skip to avoid overwriting
            @sync_results[:skipped] << relative_path
            return
          end
          # If force is true and files are different, we'll overwrite below
        end

        # Copy the file
        begin
          FileUtils.cp(source_path, target_path)
          @sync_results[:copied] << relative_path

          # Cache the content after successful copy (only if target didn't exist before)
          # If target existed, files_different? already cached the content
          if @cache && !target_existed
            source_content = File.read(source_path)
            @cache.put(source_content)
          end
        rescue => e
          @sync_results[:errors] << { file: relative_path, error: e.message }
        end
      end

      def files_different?(source_path, target_path)
        # Read source file and compute hash
        source_content = File.read(source_path)
        source_hash = Digest::SHA256.hexdigest(source_content)

        # Read target file and compute hash
        target_content = File.read(target_path)
        target_hash = Digest::SHA256.hexdigest(target_content)

        # Cache the source content for future use
        @cache&.put(source_content)

        source_hash != target_hash
      rescue => e
        # If we can't read files for comparison, assume they're different
        true
      end
    end
  end
end
