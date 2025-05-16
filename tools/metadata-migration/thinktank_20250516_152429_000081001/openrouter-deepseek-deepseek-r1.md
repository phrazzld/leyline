```
## Chosen Approach
Modular parser with strict validation and error recovery using a state machine approach.

## Rationale
- **Simplicity**: Direct line-by-line parsing avoids over-engineering while handling core requirements
- **Modularity**: Separates parsing/validation/error handling into testable units
- **Testability**: Clear boundaries enable testing all edge cases with minimal mocking
- **Coding Standards**: Full type safety with no `any` and strict eslint compliance
- **Docs**: Self-documenting types with JSDoc-style comments

## Build Steps
1. Create `src/legacyParser.ts` with core parser logic:
```typescript
import { LegacyMetadata, MetadataFormat } from './types';
import { logger } from './logger';

type ParseResult = {
  metadata: LegacyMetadata;
  warnings: string[];
};

const REQUIRED_FIELDS = ['id', 'last_modified'];

export class LegacyParser {
  parse(rawMetadata: string): ParseResult {
    const lines = this.normalizeLines(rawMetadata);
    const parsed = this.parseLines(lines);
    const result = this.validateMetadata(parsed);

    logger.debug('Legacy metadata parsed', {
      fields: Object.keys(result.metadata),
      warningCount: result.warnings.length
    });

    return result;
  }

  private normalizeLines(input: string): string[] {
    return input.split(/\r\n|\n|\r/).map(l => l.trim());
  }

  private parseLines(lines: string[]): Map<string, string> {
    const data = new Map<string, string>();
    let currentKey = '';

    for (const line of lines) {
      if (!line) continue;

      const colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        currentKey = line.slice(0, colonIndex).trim();
        const value = line.slice(colonIndex + 1).trim();
        data.set(currentKey, value);
      } else if (currentKey) {
        data.set(currentKey, `${data.get(currentKey)} ${line.trim()}`);
      }
    }

    return data;
  }

  private validateMetadata(data: Map<string, string>): ParseResult {
    const metadata = Object.fromEntries(data) as unknown as LegacyMetadata;
    const warnings: string[] = [];

    // Validate required fields
    for (const field of REQUIRED_FIELDS) {
      if (!data.has(field)) {
        throw new LegacyParseError(`Missing required field: ${field}`);
      }
    }

    // Validate date format
    if (!/^\d{4}-\d{2}-\d{2}$/.test(metadata.last_modified)) {
      warnings.push('Invalid date format in last_modified field');
    }

    return { metadata, warnings };
  }
}

export class LegacyParseError extends Error {
  constructor(message: string) {
    super(`Legacy parse error: ${message}`);
    this.name = 'LegacyParseError';
  }
}
```

2. Add comprehensive test suite:
```typescript
import { LegacyParser, LegacyParseError } from '../src/legacyParser';
import { readFixture } from './test-utils';

describe('LegacyParser', () => {
  const parser = new LegacyParser();

  test('parses basic metadata', () => {
    const input = readFixture('legacy-basic-binding.md');
    const { metadata, warnings } = parser.parse(input);

    expect(metadata.id).toBe('no-any');
    expect(metadata.derived_from).toBe('simplicity');
    expect(warnings).toHaveLength(0);
  });

  test('throws on missing required fields', () => {
    const input = readFixture('malformed-missing-required.md');
    expect(() => parser.parse(input)).toThrow(LegacyParseError);
  });

  test('handles multiline values', () => {
    const input = readFixture('legacy-multiline-values.md');
    const { metadata } = parser.parse(input);

    expect(metadata.description).toContain('standardization provides consistency');
  });
});
```
