#!/usr/bin/env ruby
# tools/test_templates.rb - Tests validation of template files

require 'fileutils'

# Copy templates to test directories
FileUtils.cp('docs/templates/tenet_template.md', 'tenets/test_tenet_template.md')
FileUtils.cp('docs/templates/binding_template.md', 'bindings/test_binding_template.md')

begin
  # Run validation
  puts 'Testing templates against validation...'
  system('ruby tools/validate_front_matter.rb')
  status = $?.exitstatus

  if status == 0
    puts "\n✅ Templates passed validation!"
  else
    puts "\n❌ Templates failed validation. Please check the errors above."
  end
ensure
  # Clean up
  FileUtils.rm('tenets/test_tenet_template.md')
  FileUtils.rm('bindings/test_binding_template.md')
end
