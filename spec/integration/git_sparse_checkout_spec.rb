# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'GitClient sparse-checkout integration', type: :integration do
  let(:source_repo_dir) { Dir.mktmpdir('leyline-source-repo') }
  let(:checkout_dir) { Dir.mktmpdir('leyline-checkout') }
  let(:git_client) { Leyline::Sync::GitClient.new }

  after do
    git_client.cleanup
    FileUtils.rm_rf(source_repo_dir) if Dir.exist?(source_repo_dir)
    FileUtils.rm_rf(checkout_dir) if Dir.exist?(checkout_dir)
  end

  def create_source_repository
    # Create a real git repository with known content structure
    Dir.chdir(source_repo_dir) do
      system('git init')
      system('git config user.email "test@example.com"')
      system('git config user.name "Test User"')

      # Create directory structure similar to leyline
      FileUtils.mkdir_p('docs/tenets')
      FileUtils.mkdir_p('docs/bindings/core')
      FileUtils.mkdir_p('docs/bindings/categories/typescript')
      FileUtils.mkdir_p('src/lib')
      FileUtils.mkdir_p('spec/fixtures')

      # Create test files
      File.write('README.md', '# Test Repository')
      File.write('docs/tenets/simplicity.md', '# Simplicity Tenet')
      File.write('docs/tenets/testability.md', '# Testability Tenet')
      File.write('docs/bindings/core/automated-quality-gates.md', '# Automated Quality Gates')
      File.write('docs/bindings/categories/typescript/modern-typescript.md', '# Modern TypeScript')
      File.write('src/lib/main.rb', 'puts "Hello World"')
      File.write('spec/fixtures/test.md', '# Test Fixture')

      # Add and commit all files
      system('git add .')
      system('git commit -m "Initial commit"')
    end
  end

  describe 'sparse-checkout functionality' do
    before do
      create_source_repository
    end

    it 'checks out only specified single file' do
      git_client.setup_sparse_checkout(checkout_dir)
      git_client.add_sparse_paths(['docs/tenets/simplicity.md'])
      git_client.fetch_version("file://#{source_repo_dir}", 'HEAD')

      # Verify only the specified file is present
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to be true
      expect(File.read(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to eq('# Simplicity Tenet')

      # Verify other files are not present
      expect(File.exist?(File.join(checkout_dir, 'README.md'))).to be false
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/testability.md'))).to be false
      expect(File.exist?(File.join(checkout_dir, 'src/lib/main.rb'))).to be false
    end

    it 'checks out multiple specified files' do
      git_client.setup_sparse_checkout(checkout_dir)
      git_client.add_sparse_paths([
                                    'docs/tenets/simplicity.md',
                                    'docs/bindings/core/automated-quality-gates.md'
                                  ])
      git_client.fetch_version("file://#{source_repo_dir}", 'HEAD')

      # Verify specified files are present
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to be true
      expect(File.exist?(File.join(checkout_dir, 'docs/bindings/core/automated-quality-gates.md'))).to be true

      # Verify content is correct
      expect(File.read(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to eq('# Simplicity Tenet')
      expect(File.read(File.join(checkout_dir,
                                 'docs/bindings/core/automated-quality-gates.md'))).to eq('# Automated Quality Gates')

      # Verify other files are not present
      expect(File.exist?(File.join(checkout_dir, 'README.md'))).to be false
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/testability.md'))).to be false
    end

    it 'checks out entire directory with wildcard' do
      git_client.setup_sparse_checkout(checkout_dir)
      git_client.add_sparse_paths(['docs/tenets/*'])
      git_client.fetch_version("file://#{source_repo_dir}", 'HEAD')

      # Verify all files in tenets directory are present
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to be true
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/testability.md'))).to be true

      # Verify files outside the directory are not present
      expect(File.exist?(File.join(checkout_dir, 'README.md'))).to be false
      expect(File.exist?(File.join(checkout_dir, 'docs/bindings/core/automated-quality-gates.md'))).to be false
    end

    it 'handles nested directory paths' do
      git_client.setup_sparse_checkout(checkout_dir)
      git_client.add_sparse_paths(['docs/bindings/categories/typescript/*'])
      git_client.fetch_version("file://#{source_repo_dir}", 'HEAD')

      # Verify nested file is present
      expect(File.exist?(File.join(checkout_dir,
                                   'docs/bindings/categories/typescript/modern-typescript.md'))).to be true
      expect(File.read(File.join(checkout_dir,
                                 'docs/bindings/categories/typescript/modern-typescript.md'))).to eq('# Modern TypeScript')

      # Verify other files are not present
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to be false
      expect(File.exist?(File.join(checkout_dir, 'docs/bindings/core/automated-quality-gates.md'))).to be false
    end

    it 'adds additional paths incrementally' do
      git_client.setup_sparse_checkout(checkout_dir)

      # First add one path
      git_client.add_sparse_paths(['docs/tenets/simplicity.md'])
      git_client.fetch_version("file://#{source_repo_dir}", 'HEAD')

      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to be true
      expect(File.exist?(File.join(checkout_dir, 'README.md'))).to be false

      # Then add another path
      git_client.add_sparse_paths(['README.md'])
      # Re-fetch to update sparse-checkout
      system('git checkout HEAD', chdir: checkout_dir, out: '/dev/null', err: '/dev/null')

      # Both files should now be present
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to be true
      expect(File.exist?(File.join(checkout_dir, 'README.md'))).to be true
    end

    it 'works with different git references' do
      # Create another commit in source repo
      Dir.chdir(source_repo_dir) do
        File.write('docs/tenets/new-tenet.md', '# New Tenet')
        system('git add docs/tenets/new-tenet.md')
        system('git commit -m "Add new tenet"')
      end

      git_client.setup_sparse_checkout(checkout_dir)
      git_client.add_sparse_paths(['docs/tenets/*'])
      git_client.fetch_version("file://#{source_repo_dir}", 'HEAD')

      # Verify the new file from latest commit is present
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/new-tenet.md'))).to be true
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/simplicity.md'))).to be true
      expect(File.exist?(File.join(checkout_dir, 'docs/tenets/testability.md'))).to be true
    end
  end

  describe 'error scenarios' do
    before do
      create_source_repository
    end

    it 'handles sparse-checkout when no files match pattern' do
      git_client.setup_sparse_checkout(checkout_dir)
      git_client.add_sparse_paths(['nonexistent/path/*'])
      git_client.fetch_version("file://#{source_repo_dir}", 'HEAD')

      # Verify working directory exists but contains no matched files
      expect(Dir.exist?(checkout_dir)).to be true
      expect(Dir.entries(checkout_dir) - ['.', '..', '.git']).to be_empty
    end

    it 'fails gracefully when source repository does not exist' do
      nonexistent_repo = 'file:///tmp/nonexistent-repo'

      git_client.setup_sparse_checkout(checkout_dir)
      git_client.add_sparse_paths(['docs/tenets/*'])

      expect { git_client.fetch_version(nonexistent_repo, 'HEAD') }.to raise_error(
        Leyline::Sync::GitClient::GitCommandError,
        /Git command failed/
      )
    end
  end
end
