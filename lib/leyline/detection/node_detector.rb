# frozen_string_literal: true

require 'json'
require_relative 'language_detector'

module Leyline
  module Detection
    class NodeDetector < LanguageDetector
      TYPESCRIPT_INDICATORS = %w[
        typescript
        ts-node
        tsx
        tsc
      ].freeze

      TYPESCRIPT_TYPE_PATTERNS = [
        /\A@types\//
      ].freeze

      WEB_INDICATORS = %w[
        react
        react-dom
        next
        gatsby
        vue
        svelte
        vite
        webpack
        @angular/core
        @angular/cli
      ].freeze

      WEB_TYPE_PATTERNS = [
        /\A@types\/react/
      ].freeze

      DEPENDENCY_SECTIONS = %w[
        dependencies
        devDependencies
        peerDependencies
        optionalDependencies
      ].freeze

      def detect
        return [] unless file_exists?('package.json')

        package_data = parse_package_json
        return [] if package_data.nil? || package_data.empty?

        detected_categories = []
        all_dependencies = collect_all_dependencies(package_data)

        detected_categories << 'typescript' if typescript_detected?(all_dependencies)
        detected_categories << 'web' if web_detected?(all_dependencies)

        detected_categories
      end

      private

      def parse_package_json
        content = read_file('package.json')
        return nil if content.nil?

        JSON.parse(content)
      rescue JSON::ParserError => e
        raise DetectionError, "Failed to parse package.json: #{e.message}"
      end

      def collect_all_dependencies(package_data)
        dependencies = []

        DEPENDENCY_SECTIONS.each do |section|
          section_deps = package_data[section]
          next if section_deps.nil? || !section_deps.is_a?(Hash)

          dependencies.concat(section_deps.keys)
        end

        dependencies
      end

      def typescript_detected?(dependencies)
        return true if dependencies.any? { |dep| TYPESCRIPT_INDICATORS.include?(dep) }
        return true if dependencies.any? { |dep| TYPESCRIPT_TYPE_PATTERNS.any? { |pattern| pattern.match?(dep) } }

        false
      end

      def web_detected?(dependencies)
        return true if dependencies.any? { |dep| WEB_INDICATORS.include?(dep) }
        return true if dependencies.any? { |dep| WEB_TYPE_PATTERNS.any? { |pattern| pattern.match?(dep) } }

        false
      end
    end
  end
end
