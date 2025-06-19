import { describe, it, expect } from 'vitest';
import { greet, add } from '../src/index';

describe('Core Functions', () => {
  it('should greet a user properly', () => {
    expect(greet('World')).toBe(
      'Hello, World! Welcome to the Leyline TypeScript toolchain.'
    );
  });

  it('should add two numbers correctly', () => {
    expect(add(2, 3)).toBe(5);
    expect(add(-1, 1)).toBe(0);
  });
});
