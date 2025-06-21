# frozen_string_literal: true

require 'digest'
require 'fileutils'

module Leyline
  module Cache
    class FileCache
      class CacheError < StandardError; end

      def initialize(cache_dir = '~/.leyline/cache')
        @cache_dir = File.expand_path(cache_dir)
        @content_dir = File.join(@cache_dir, 'content')
        @max_cache_size = 50 * 1024 * 1024  # 50MB in bytes
        ensure_directories
      end

      def put(content)
        hash = Digest::SHA256.hexdigest(content)
        file_path = content_file_path(hash)

        # Create directory if needed
        FileUtils.mkdir_p(File.dirname(file_path))

        # Write file
        File.write(file_path, content)

        hash
      end

      def get(hash)
        file_path = content_file_path(hash)
        return nil unless File.exist?(file_path)

        File.read(file_path)
      end

      private

      def ensure_directories
        FileUtils.mkdir_p(@content_dir)
      end

      def content_file_path(hash)
        File.join(@content_dir, hash[0..1], hash[2..-1])
      end
    end
  end
end
