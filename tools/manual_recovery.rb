#!/usr/bin/env ruby
# manual_recovery.rb - Guide for manual release recovery
#
# This tool provides step-by-step instructions for manually recovering
# from failed releases when automated rollback isn't possible.

require 'optparse'

$options = {
  guide: false,
  check: false,
  version: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: manual_recovery.rb [options]"

  opts.on("--guide", "Show manual recovery guide") do
    $options[:guide] = true
  end

  opts.on("--check", "Check current release state") do
    $options[:check] = true
  end

  opts.on("-v", "--version VERSION", "Version to recover from") do |version|
    $options[:version] = version
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit 0
  end
end.parse!

def show_recovery_guide
  puts <<~GUIDE
    # Manual Release Recovery Guide

    This guide helps you manually recover from a failed release when automated
    rollback isn't possible.

    ## Prerequisites

    1. Git command-line access
    2. GitHub CLI (`gh`) installed and authenticated
    3. Write access to the repository
    4. Knowledge of the failed version number

    ## Step 1: Assess the Situation

    Run: ruby tools/manual_recovery.rb --check --version vX.Y.Z

    This will help you understand what needs to be fixed.

    ## Step 2: Revert Local Files

    ### Revert VERSION file
    ```bash
    # Find the previous version
    git log --oneline VERSION | head -5

    # Revert to previous version
    echo "X.Y.Z" > VERSION  # Use previous version number
    ```

    ### Revert CHANGELOG.md
    ```bash
    # View changelog history
    git log --oneline CHANGELOG.md | head -5

    # Either revert the file or manually edit
    git checkout HEAD~1 -- CHANGELOG.md
    # OR manually remove the failed version section
    ```

    ## Step 3: Delete Git Tag

    ### Delete local tag
    ```bash
    git tag -d vX.Y.Z
    ```

    ### Delete remote tag
    ```bash
    git push origin :refs/tags/vX.Y.Z
    ```

    ## Step 4: Delete GitHub Release

    ### Using GitHub CLI
    ```bash
    gh release delete vX.Y.Z --yes
    ```

    ### Using GitHub Web Interface
    1. Go to https://github.com/[owner]/[repo]/releases
    2. Find the failed release
    3. Click "Delete" (trash icon)

    ## Step 5: Commit Fixes

    ```bash
    git add VERSION CHANGELOG.md
    git commit -m "chore: rollback failed release vX.Y.Z

    Manually rolled back due to [reason]
    - Reverted VERSION file
    - Reverted CHANGELOG.md
    - Deleted tag and GitHub release"

    git push origin main
    ```

    ## Step 6: Create Rollback Issue

    ```bash
    gh issue create \\
      --title "Manual rollback completed for vX.Y.Z" \\
      --body "Release vX.Y.Z was manually rolled back.

    Reason: [Explain why rollback was needed]

    Actions taken:
    - Reverted VERSION to previous version
    - Removed vX.Y.Z entry from CHANGELOG
    - Deleted git tag vX.Y.Z
    - Deleted GitHub release

    Next steps:
    - Fix the issues that caused the failure
    - Prepare a new release when ready"
    ```

    ## Step 7: Notify Team

    Post in your team's communication channel about the rollback.

    ## Common Issues

    ### Permission Denied
    - Ensure you have write access to the repository
    - Check your GitHub token permissions

    ### Tag Already Deleted
    - This is fine, continue with other steps

    ### Can't Find Previous Version
    - Check git tags: `git tag -l | sort -V`
    - Check VERSION file history: `git log --oneline VERSION`

    ### Conflicts When Pushing
    - Pull latest changes: `git pull --rebase`
    - Resolve conflicts manually
    - Continue with push

    ## Prevention Tips

    1. Always test releases in a staging environment first
    2. Use the automated rollback system when possible
    3. Keep release sizes small to minimize impact
    4. Document any manual changes in commit messages

  GUIDE
end

def check_release_state
  version = $options[:version]

  unless version
    puts "Error: Version required for check (use --version)"
    exit 1
  end

  puts "Checking release state for #{version}..."
  puts ""

  # Check VERSION file
  if File.exist?('VERSION')
    current_version = File.read('VERSION').strip
    puts "✓ Current VERSION: #{current_version}"

    if "v#{current_version}" == version || current_version == version.gsub(/^v/, '')
      puts "  ⚠️  VERSION file still shows failed version"
    else
      puts "  ✓ VERSION file already reverted"
    end
  else
    puts "✗ VERSION file not found"
  end

  # Check CHANGELOG
  if File.exist?('CHANGELOG.md')
    changelog = File.read('CHANGELOG.md')
    if changelog.include?(version.gsub(/^v/, ''))
      puts "⚠️  CHANGELOG still contains #{version} entry"
    else
      puts "✓ CHANGELOG does not contain #{version}"
    end
  else
    puts "✗ CHANGELOG.md not found"
  end

  # Check git tag
  if system("git rev-parse #{version} >/dev/null 2>&1")
    puts "⚠️  Git tag #{version} still exists locally"

    # Check if pushed to remote
    if system("git ls-remote --tags origin | grep #{version} >/dev/null 2>&1")
      puts "  ⚠️  Tag also exists on remote"
    else
      puts "  ✓ Tag not on remote"
    end
  else
    puts "✓ Git tag #{version} not found locally"
  end

  # Check GitHub release (requires gh CLI)
  if system("which gh >/dev/null 2>&1")
    if system("gh release view #{version} >/dev/null 2>&1")
      puts "⚠️  GitHub release #{version} still exists"
    else
      puts "✓ GitHub release #{version} not found"
    end
  else
    puts "ℹ️  GitHub CLI not available - can't check releases"
  end

  puts ""
  puts "Based on this check, you may need to:"
  puts "- Revert VERSION file" if "v#{current_version}" == version
  puts "- Remove #{version} from CHANGELOG" if changelog&.include?(version.gsub(/^v/, ''))
  puts "- Delete git tag #{version}" if system("git rev-parse #{version} >/dev/null 2>&1")
  puts "- Delete GitHub release" if system("gh release view #{version} >/dev/null 2>&1")
end

# Main execution
if $options[:guide]
  show_recovery_guide
elsif $options[:check]
  check_release_state
else
  puts "Manual Recovery Tool"
  puts ""
  puts "Options:"
  puts "  --guide     Show step-by-step manual recovery guide"
  puts "  --check     Check current release state"
  puts "  --version   Version to check (with --check)"
  puts ""
  puts "Example:"
  puts "  ruby tools/manual_recovery.rb --guide"
  puts "  ruby tools/manual_recovery.rb --check --version v0.2.0"
end
