# frozen_string_literal: true

module Leyline
  module Detection
    class LanguageDetector
      class DetectionError < StandardError; end

      def initialize(project_path)
        @project_path = File.expand_path(project_path)
        validate_project_path
      end

      def detect
        raise NotImplementedError, "#{self.class}#detect must be implemented by subclasses"
      end

      protected

      attr_reader :project_path

      def file_exists?(relative_path)
        File.exist?(File.join(project_path, relative_path))
      end

      def read_file(relative_path)
        full_path = File.join(project_path, relative_path)
        return nil unless File.exist?(full_path)

        File.read(full_path)
      rescue StandardError => e
        raise DetectionError, "Failed to read file #{relative_path}: #{e.message}"
      end

      private

      def validate_project_path
        unless Dir.exist?(project_path)
          raise DetectionError, "Project path does not exist: #{project_path}"
        end
      end
    end
  end
end
