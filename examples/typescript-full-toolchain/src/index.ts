export { fetchUser, getUserQueryOptions, queryClient } from './user-api';
export type { User } from './user-api';

export const greet = (name: string): string => {
  return `Hello, ${name}! Welcome to the Leyline TypeScript toolchain.`;
};

export const add = (a: number, b: number): number => {
  return a + b;
};
