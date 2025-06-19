import { describe, it, expect } from 'vitest';
import { queryClient, getUserQueryOptions, User } from '../src/user-api';

describe('User API with TanStack Query', () => {
  it('should fetch a user successfully', async () => {
    const options = getUserQueryOptions('1');
    const data = await queryClient.fetchQuery<User>(options);

    expect(data.id).toBe('1');
    expect(data.name).toBe('Leyline User');
  });

  it('should throw an error for a non-existent user', async () => {
    const options = getUserQueryOptions('2');
    await expect(queryClient.fetchQuery(options)).rejects.toThrow(
      'Network response was not ok'
    );
  });
});
