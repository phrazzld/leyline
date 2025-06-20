# frozen_string_literal: true

require 'thor'
require_relative 'version'

module Leyline
  class CLI < Thor
    package_name 'leyline'

    desc 'version', 'Show version information'
    def version
      puts VERSION
    end

    desc 'sync [PATH]', 'Synchronize leyline standards to target directory'
    method_option :categories,
                  type: :array,
                  desc: 'Specific categories to sync (e.g., typescript, go, core)',
                  aliases: '-c'
    method_option :force,
                  type: :boolean,
                  desc: 'Overwrite local modifications without confirmation',
                  aliases: '-f'
    method_option :dry_run,
                  type: :boolean,
                  desc: 'Show what would be synced without making changes',
                  aliases: '-n'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed output',
                  aliases: '-v'
    def sync(path = '.')
      puts "Synchronizing leyline standards to: #{File.expand_path(path)}"
      puts "Categories: #{options[:categories]&.join(', ') || 'auto-detected'}"
      puts "Options: #{options.select { |k, v| v }.keys.join(', ')}" if options.any? { |_, v| v }

      # TODO: Implement actual sync logic
      puts "Sync functionality not yet implemented"
    end

    default_task :sync
  end
end
