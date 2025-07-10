# frozen_string_literal: true

require 'tmpdir'
require_relative 'base_command'

module Leyline
  module Commands
    # Implements the 'leyline version' command to display version and system information
    # Shows basic version number or detailed system information in verbose mode
    class VersionCommand < BaseCommand
      class VersionError < Leyline::LeylineError
        def error_type
          :command
        end

        def recovery_suggestions
          [
            'Check that Leyline is properly installed',
            'Verify Ruby version compatibility (requires Ruby 2.7+)',
            'Reinstall Leyline gem if issues persist'
          ]
        end
      end

      # Execute version command and return results
      def execute
        version_data = gather_version_information

        if @options[:json]
          output_json(version_data)
        else
          output_human_readable(version_data)
        end

        version_data
      rescue StandardError => e
        handle_error(e)
        nil
      end

      private

      def gather_version_information
        data = {
          version: VERSION,
          ruby_version: RUBY_VERSION,
          platform: RUBY_PLATFORM
        }

        if verbose?
          data.merge!(gather_detailed_information)
        end

        data
      end

      def gather_detailed_information
        {
          cache_directory: @cache_dir,
          git_available: git_available?,
          platform_details: platform_details,
          environment: environment_info
        }
      end

      def git_available?
        system('which git > /dev/null 2>&1')
      end

      def platform_details
        {
          os: detect_platform,
          architecture: RUBY_PLATFORM,
          ruby_engine: defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby',
          containerized: PlatformHelper.containerized?
        }
      end

      def environment_info
        {
          cache_dir_expanded: File.expand_path(@cache_dir),
          cache_dir_exists: Dir.exist?(@cache_dir),
          home_directory: ENV['HOME'],
          tmpdir: Dir.tmpdir
        }
      end

      def output_human_readable(data)
        puts data[:version]

        return unless verbose?

        puts "\nSystem Information:"
        puts "  Ruby version: #{data[:ruby_version]}"
        puts "  Platform: #{data[:platform]}"
        puts "  Cache directory: #{data[:cache_directory]}"
        puts "  Git available: #{data[:git_available] ? 'Yes' : 'No'}"

        if data[:platform_details]
          puts "\nPlatform Details:"
          puts "  OS: #{data[:platform_details][:os]}"
          puts "  Ruby engine: #{data[:platform_details][:ruby_engine]}"
          puts "  Containerized: #{data[:platform_details][:containerized] ? 'Yes' : 'No'}"
        end

        if data[:environment]
          puts "\nEnvironment:"
          puts "  Cache exists: #{data[:environment][:cache_dir_exists] ? 'Yes' : 'No'}"
          puts "  Temp directory: #{data[:environment][:tmpdir]}"
        end
      end
    end
  end
end
