# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'leyline/version'

Gem::Specification.new do |spec|
  spec.name          = 'leyline'
  spec.version       = Leyline::VERSION
  spec.authors       = ['Leyline Contributors']
  spec.email         = ['leyline@example.com']

  spec.summary       = 'Sync development standards to your project'
  spec.description   = 'A simple CLI tool to sync Leyline development standards (tenets and bindings) to your project'
  spec.homepage      = 'https://github.com/phrazzld/leyline'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/phrazzld/leyline'
  spec.metadata['changelog_uri'] = 'https://github.com/phrazzld/leyline/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|github))})
    end
  end

  spec.bindir = 'bin'
  spec.executables = ['leyline']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_runtime_dependency 'thor', '~> 1.3'

  # Development dependencies
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'bundler', '~> 2.0'
end
