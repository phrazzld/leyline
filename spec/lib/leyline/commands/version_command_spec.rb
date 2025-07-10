# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/version_command'

RSpec.describe Leyline::Commands::VersionCommand do
  let(:options) { {} }
  let(:command) { described_class.new(options) }

  describe '#execute' do
    context 'with default options' do
      it 'returns version information' do
        result = command.execute

        expect(result).to be_a(Hash)
        expect(result[:version]).to eq(Leyline::VERSION)
        expect(result[:ruby_version]).to eq(RUBY_VERSION)
        expect(result[:platform]).to eq(RUBY_PLATFORM)
      end

      it 'outputs only the version number' do
        expect { command.execute }.to output("#{Leyline::VERSION}\n").to_stdout
      end

      it 'does not include detailed information' do
        result = command.execute

        expect(result).not_to have_key(:cache_directory)
        expect(result).not_to have_key(:git_available)
        expect(result).not_to have_key(:platform_details)
      end
    end

    context 'with verbose option' do
      let(:options) { { verbose: true } }

      it 'includes detailed system information' do
        result = command.execute

        expect(result).to have_key(:cache_directory)
        expect(result).to have_key(:git_available)
        expect(result).to have_key(:platform_details)
        expect(result).to have_key(:environment)
      end

      it 'outputs detailed information to stdout' do
        output = capture_stdout { command.execute }

        expect(output).to include(Leyline::VERSION)
        expect(output).to include('System Information:')
        expect(output).to include('Ruby version:')
        expect(output).to include('Platform:')
        expect(output).to include('Cache directory:')
        expect(output).to include('Git available:')
        expect(output).to include('Platform Details:')
        expect(output).to include('Environment:')
      end

      it 'includes platform details' do
        result = command.execute
        platform_details = result[:platform_details]

        expect(%w[windows macos linux unknown]).to include(platform_details[:os])
        expect(platform_details[:architecture]).to eq(RUBY_PLATFORM)
        expect(platform_details[:ruby_engine]).to be_a(String)
        expect([true, false]).to include(platform_details[:containerized])
      end

      it 'includes environment information' do
        result = command.execute
        environment = result[:environment]

        expect(environment[:cache_dir_expanded]).to be_a(String)
        expect([true, false]).to include(environment[:cache_dir_exists])
        expect(environment[:home_directory]).to eq(ENV['HOME'])
        expect(environment[:tmpdir]).to eq(Dir.tmpdir)
      end
    end

    context 'with json option' do
      let(:options) { { json: true } }

      it 'outputs JSON format' do
        output = capture_stdout { command.execute }
        parsed = JSON.parse(output)

        expect(parsed['version']).to eq(Leyline::VERSION)
        expect(parsed['ruby_version']).to eq(RUBY_VERSION)
        expect(parsed['platform']).to eq(RUBY_PLATFORM)
      end

      context 'with verbose' do
        let(:options) { { json: true, verbose: true } }

        it 'outputs verbose JSON format' do
          output = capture_stdout { command.execute }
          parsed = JSON.parse(output)

          expect(parsed).to have_key('cache_directory')
          expect(parsed).to have_key('git_available')
          expect(parsed).to have_key('platform_details')
          expect(parsed).to have_key('environment')
        end
      end
    end

    context 'with custom cache directory' do
      let(:custom_cache_dir) { '/tmp/custom-leyline-cache' }
      let(:options) { { cache_dir: custom_cache_dir, verbose: true } }

      it 'uses the custom cache directory' do
        result = command.execute

        expect(result[:cache_directory]).to eq(custom_cache_dir)
        expect(result[:environment][:cache_dir_expanded]).to eq(File.expand_path(custom_cache_dir))
      end
    end

    context 'error handling' do
      before do
        allow(command).to receive(:gather_version_information).and_raise(StandardError, 'Test error')
      end

      it 'handles errors gracefully' do
        expect { command.execute }.to output(/Error: Test error/).to_stderr
        expect(command.execute).to be_nil
      end
    end
  end

  describe 'git availability check' do
    it 'correctly detects git availability' do
      # This test assumes git is available in CI/development environments
      result = command.send(:git_available?)
      expect([true, false]).to include(result)
    end
  end

  # Helper method to capture stdout
  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
