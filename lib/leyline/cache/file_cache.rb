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

      private

      def ensure_directories
        FileUtils.mkdir_p(@content_dir)
      end
    end
  end
end
