# frozen_string_literal: true

require 'digest'
require 'fileutils'
require_relative 'cache_error_handler'

module Leyline
  module Cache
    class FileCache
      class CacheError < StandardError; end

      def initialize(cache_dir = '~/.leyline/cache')
        @cache_dir = File.expand_path(cache_dir)
        @content_dir = File.join(@cache_dir, 'content')
        @max_cache_size = 50 * 1024 * 1024 # 50MB in bytes
        @error_count = 0
        @operation_count = 0

        begin
          ensure_directories
        rescue StandardError => e
          CacheErrorHandler.handle_error(e, 'initialize', { cache_dir: @cache_dir })
          # Continue without cache rather than failing
        end
      end

      def put(content)
        @operation_count += 1

        begin
          # Validate input
          unless content.is_a?(String)
            CacheErrorHandler.warn('Invalid content type for cache put', {
                                     content_class: content.class.name
                                   })
            return nil
          end

          hash = Digest::SHA256.hexdigest(content)
          file_path = content_file_path(hash)

          # Create directory if needed
          FileUtils.mkdir_p(File.dirname(file_path))

          # Write file
          File.write(file_path, content)

          hash
        rescue StandardError => e
          @error_count += 1
          CacheErrorHandler.handle_error(e, 'put', {
                                           content_size: content&.bytesize,
                                           file_path: file_path
                                         })
          # Return nil to indicate failure, but don't raise
          nil
        end
      end

      def get(hash)
        @operation_count += 1

        begin
          # Validate input
          unless hash.is_a?(String) && hash.match?(/\A[a-f0-9]{64}\z/)
            CacheErrorHandler.warn('Invalid hash format for cache get', {
                                     hash: hash.inspect
                                   })
            return nil
          end

          file_path = content_file_path(hash)
          return nil unless File.exist?(file_path)

          content = File.read(file_path)

          # Basic corruption check - ensure we can compute hash
          actual_hash = Digest::SHA256.hexdigest(content)
          if actual_hash != hash
            @error_count += 1
            CacheErrorHandler.warn('Cache corruption detected', {
                                     expected_hash: hash,
                                     actual_hash: actual_hash,
                                     file_path: file_path
                                   })

            # Attempt to remove corrupted file
            begin
              File.delete(file_path)
            rescue StandardError => e
              CacheErrorHandler.handle_error(e, 'delete_corrupted', { file_path: file_path })
            end

            return nil
          end

          content
        rescue StandardError => e
          @error_count += 1
          CacheErrorHandler.handle_error(e, 'get', {
                                           hash: hash,
                                           file_path: file_path
                                         })
          # Return nil to indicate cache miss, but don't raise
          nil
        end
      end

      def directory_stats
        return { path: @cache_dir, size: 0, file_count: 0, utilization_percent: 0 } unless Dir.exist?(@content_dir)

        total_size = 0
        file_count = 0

        Dir.glob(File.join(@content_dir, '**', '*')).each do |file_path|
          if File.file?(file_path)
            file_count += 1
            total_size += File.size(file_path)
          end
        end

        utilization_percent = @max_cache_size > 0 ? ((total_size.to_f / @max_cache_size) * 100).round(1) : 0

        {
          path: @cache_dir,
          size: total_size,
          file_count: file_count,
          utilization_percent: utilization_percent
        }
      rescue StandardError
        # Return safe defaults on any error
        { path: @cache_dir, size: 0, file_count: 0, utilization_percent: 0 }
      end

      # Get cache health status
      def health_status
        issues = CacheErrorHandler.check_cache_health(@cache_dir)

        {
          healthy: issues.empty?,
          issues: issues,
          error_rate: error_rate,
          operation_count: @operation_count,
          error_count: @error_count
        }
      end

      # Get error rate as percentage
      def error_rate
        return 0.0 if @operation_count == 0

        (@error_count.to_f / @operation_count * 100).round(2)
      end

      private

      def ensure_directories
        return if Dir.exist?(@content_dir)

        begin
          FileUtils.mkdir_p(@content_dir)
        rescue StandardError => e
          CacheErrorHandler.handle_error(e, 'ensure_directories', {
                                           cache_dir: @cache_dir,
                                           content_dir: @content_dir
                                         })
          raise CacheError, "Failed to create cache directory: #{e.message}"
        end
      end

      def content_file_path(hash)
        File.join(@content_dir, hash[0..1], hash[2..-1])
      end
    end
  end
end
