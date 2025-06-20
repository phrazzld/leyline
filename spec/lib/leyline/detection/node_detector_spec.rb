# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'json'

RSpec.describe Leyline::Detection::NodeDetector do
  let(:temp_dir) { Dir.mktmpdir('leyline-node-detection-test') }
  let(:detector) { described_class.new(temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  def create_package_json(content)
    File.write(File.join(temp_dir, 'package.json'), content.is_a?(String) ? content : JSON.pretty_generate(content))
  end

  describe 'inheritance' do
    it 'inherits from LanguageDetector' do
      expect(described_class).to be < Leyline::Detection::LanguageDetector
    end
  end

  describe '#detect' do
    context 'when no package.json exists' do
      it 'returns empty array' do
        expect(detector.detect).to eq([])
      end
    end

    context 'when package.json exists but is invalid JSON' do
      before do
        create_package_json('{ invalid json')
      end

      it 'raises DetectionError' do
        expect { detector.detect }.to raise_error(
          Leyline::Detection::LanguageDetector::DetectionError,
          /Failed to parse package\.json/
        )
      end
    end

    context 'when package.json is valid but empty' do
      before do
        create_package_json({})
      end

      it 'returns empty array' do
        expect(detector.detect).to eq([])
      end
    end

    context 'TypeScript detection' do
      it 'detects typescript dependency' do
        create_package_json({
          dependencies: { typescript: '^4.9.0' }
        })

        expect(detector.detect).to include('typescript')
      end

      it 'detects typescript in devDependencies' do
        create_package_json({
          devDependencies: { typescript: '^4.9.0' }
        })

        expect(detector.detect).to include('typescript')
      end

      it 'detects @types packages' do
        create_package_json({
          devDependencies: { '@types/node': '^18.0.0' }
        })

        expect(detector.detect).to include('typescript')
      end

      it 'detects ts-node' do
        create_package_json({
          devDependencies: { 'ts-node': '^10.0.0' }
        })

        expect(detector.detect).to include('typescript')
      end

      it 'detects tsx' do
        create_package_json({
          devDependencies: { tsx: '^3.0.0' }
        })

        expect(detector.detect).to include('typescript')
      end

      it 'detects tsc' do
        create_package_json({
          devDependencies: { tsc: '^2.0.0' }
        })

        expect(detector.detect).to include('typescript')
      end
    end

    context 'Web/React detection' do
      it 'detects react' do
        create_package_json({
          dependencies: { react: '^18.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects react-dom' do
        create_package_json({
          dependencies: { 'react-dom': '^18.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects @types/react' do
        create_package_json({
          devDependencies: { '@types/react': '^18.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects Next.js' do
        create_package_json({
          dependencies: { next: '^13.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects Gatsby' do
        create_package_json({
          dependencies: { gatsby: '^5.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects Vue.js' do
        create_package_json({
          dependencies: { vue: '^3.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects Angular' do
        create_package_json({
          dependencies: { '@angular/core': '^15.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects Svelte' do
        create_package_json({
          dependencies: { svelte: '^3.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects Vite' do
        create_package_json({
          devDependencies: { vite: '^4.0.0' }
        })

        expect(detector.detect).to include('web')
      end

      it 'detects webpack' do
        create_package_json({
          devDependencies: { webpack: '^5.0.0' }
        })

        expect(detector.detect).to include('web')
      end
    end

    context 'Combined detection' do
      it 'detects both typescript and web for React + TypeScript project' do
        create_package_json({
          dependencies: {
            react: '^18.0.0',
            'react-dom': '^18.0.0'
          },
          devDependencies: {
            typescript: '^4.9.0',
            '@types/react': '^18.0.0',
            '@types/react-dom': '^18.0.0'
          }
        })

        result = detector.detect
        expect(result).to include('typescript')
        expect(result).to include('web')
        expect(result.size).to eq(2)
      end

      it 'detects both typescript and web for Next.js TypeScript project' do
        create_package_json({
          dependencies: {
            next: '^13.0.0',
            react: '^18.0.0'
          },
          devDependencies: {
            typescript: '^4.9.0',
            '@types/node': '^18.0.0'
          }
        })

        result = detector.detect
        expect(result).to include('typescript')
        expect(result).to include('web')
        expect(result.size).to eq(2)
      end

      it 'returns unique categories only' do
        create_package_json({
          dependencies: {
            react: '^18.0.0',
            vue: '^3.0.0',
            '@angular/core': '^15.0.0'
          }
        })

        result = detector.detect
        expect(result).to eq(['web'])
      end
    end

    context 'Complex package.json structures' do
      it 'handles peerDependencies' do
        create_package_json({
          peerDependencies: {
            typescript: '^4.9.0'
          }
        })

        expect(detector.detect).to include('typescript')
      end

      it 'handles optionalDependencies' do
        create_package_json({
          optionalDependencies: {
            react: '^18.0.0'
          }
        })

        expect(detector.detect).to include('web')
      end

      it 'handles nested dependency objects' do
        create_package_json({
          dependencies: {
            'some-package': '^1.0.0'
          },
          devDependencies: {
            typescript: '^4.9.0',
            '@types/node': '^18.0.0'
          },
          peerDependencies: {
            react: '^18.0.0'
          }
        })

        result = detector.detect
        expect(result).to include('typescript')
        expect(result).to include('web')
      end
    end

    context 'Edge cases' do
      it 'handles package.json without dependency sections' do
        create_package_json({
          name: 'test-package',
          version: '1.0.0',
          description: 'A test package'
        })

        expect(detector.detect).to eq([])
      end

      it 'handles package.json with null dependency values' do
        create_package_json({
          dependencies: nil,
          devDependencies: { typescript: '^4.9.0' }
        })

        expect(detector.detect).to include('typescript')
      end

      it 'handles package.json with empty dependency objects' do
        create_package_json({
          dependencies: {},
          devDependencies: {}
        })

        expect(detector.detect).to eq([])
      end
    end
  end
end
