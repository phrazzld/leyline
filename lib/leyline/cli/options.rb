# frozen_string_literal: true

module Leyline
  module CliOptions
      VALID_CATEGORIES = %w[
        core
        api
        browser-extension
        browser-extensions
        cli
        database
        go
        python
        react
        rust
        security
        typescript
        web
      ].freeze

      class ValidationError < StandardError; end

      class << self
        def validate_categories(categories)
          return true if categories.nil? || categories.empty?

          unless categories.is_a?(Array)
            raise ValidationError, "Categories must be an array, got #{categories.class}"
          end

          categories.each do |category|
            unless category.is_a?(String)
              raise ValidationError, "Category must be a string, got #{category.class}: #{category}"
            end

            unless VALID_CATEGORIES.include?(category)
              raise ValidationError, "Invalid category '#{category}'. Valid categories: #{VALID_CATEGORIES.join(', ')}"
            end
          end

          true
        end

        def validate_boolean_option(value, option_name)
          return true if value.nil?

          unless [true, false].include?(value)
            raise ValidationError, "#{option_name} must be a boolean, got #{value.class}: #{value}"
          end

          true
        end

        def validate_path(path)
          return true if path.nil?

          unless path.is_a?(String)
            raise ValidationError, "Path must be a string, got #{path.class}: #{path}"
          end

          expanded_path = File.expand_path(path)

          unless File.exist?(File.dirname(expanded_path))
            raise ValidationError, "Parent directory does not exist: #{File.dirname(expanded_path)}"
          end

          true
        end

        def validate_sync_options(options, path = nil)
          validate_categories(options[:categories])
          validate_boolean_option(options[:force], 'force')
          validate_boolean_option(options[:dry_run], 'dry_run')
          validate_boolean_option(options[:verbose], 'verbose')
          validate_path(path)

          true
        end

        def normalize_categories(categories)
          return nil if categories.nil? || categories.empty?

          categories.map(&:to_s).uniq.sort
        end
      end
    end
  end
