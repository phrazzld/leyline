# Discovery Commands Refactoring

## Overview

This document describes the refactoring of Leyline's discovery commands (categories, show, search) from a monolithic implementation in the CLI class to a modular command-based architecture.

## Architecture

### Module Structure

```
lib/leyline/
├── commands/
│   ├── base_command.rb          # Base for all commands
│   ├── discovery_base.rb        # Base for discovery commands
│   ├── categories_command.rb    # Categories listing
│   ├── show_command.rb          # Show documents by category
│   └── search_command.rb        # Search documents
└── cli.rb                       # Thor CLI (simplified)
```

### Class Hierarchy

```
BaseCommand
    └── DiscoveryBase
        ├── CategoriesCommand
        ├── ShowCommand
        └── SearchCommand
```

## Key Design Decisions

### 1. Shared Discovery Logic

The `DiscoveryBase` class provides:
- Cache initialization and warming
- Performance statistics display
- Common formatting utilities (bytes, relevance scores, content truncation)
- Shared error handling

### 2. Command Pattern

Each discovery command:
- Inherits from `DiscoveryBase`
- Implements `execute` method
- Handles its own option validation
- Provides both JSON and human-readable output
- Includes proper error handling with recovery suggestions

### 3. Performance Optimization

- Background cache warming preserved
- <200ms response time target maintained
- Shared cache instance across command lifecycle
- Microsecond precision telemetry support

### 4. Thor Integration

The main CLI now simply:
```ruby
def categories
  require_relative 'commands/categories_command'
  command = Commands::CategoriesCommand.new(options.to_h)
  command.execute
end
```

## Benefits

1. **Modularity**: Each command is self-contained and testable
2. **Reusability**: Shared logic in `DiscoveryBase`
3. **Maintainability**: Clear separation of concerns
4. **Extensibility**: Easy to add new discovery commands
5. **Testing**: Simplified unit testing per command

## Future Thor Subcommand Structure

The architecture supports future migration to Thor subcommands:
```bash
leyline discovery categories
leyline discovery show typescript
leyline discovery search "error handling"
```

A `CLI::Discovery` Thor subcommand class is ready at `lib/leyline/cli/discovery.rb`.

## Migration Guide

For adding new discovery commands:

1. Create new command class inheriting from `DiscoveryBase`
2. Implement `execute` method
3. Override `output_human_readable` for custom formatting
4. Add Thor method in main CLI
5. Write unit tests

Example:
```ruby
module Leyline
  module Commands
    class TagsCommand < DiscoveryBase
      def execute
        tags = metadata_cache.all_tags
        output_result(build_tags_data(tags))
        show_stats_if_requested
      rescue StandardError => e
        handle_error(e)
        nil
      end

      private

      def build_tags_data(tags)
        { tags: tags, count: tags.length }
      end

      def output_human_readable(data)
        puts "Available tags (#{data[:count]}):"
        data[:tags].each { |tag| puts "  - #{tag}" }
      end
    end
  end
end
```

## Performance Characteristics

- First run: Cache warming in background (~100-200ms)
- Subsequent runs: <50ms with warm cache
- Memory usage: Bounded by `DiscoveryBase` cache management
- Statistics: Optional with `--stats` flag
