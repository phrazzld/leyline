import { QueryClient } from '@tanstack/query-core';

export interface User {
  id: string;
  name: string;
  email: string;
}

export const queryClient = new QueryClient();

export async function fetchUser(userId: string): Promise<User> {
  const response = await fetch(`https://api.example.com/users/${userId}`);
  if (!response.ok) {
    throw new Error('Network response was not ok');
  }
  return response.json() as Promise<User>;
}

export function getUserQueryOptions(userId: string) {
  return {
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  };
}
