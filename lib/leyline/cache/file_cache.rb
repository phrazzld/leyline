# frozen_string_literal: true

module Leyline
  module Cache
    class FileCache
      class CacheError < StandardError; end

      def initialize(cache_dir = '~/.leyline/cache')
        @cache_dir = File.expand_path(cache_dir)
      end
    end
  end
end
