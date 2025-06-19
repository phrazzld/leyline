import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { beforeAll, afterEach, afterAll } from 'vitest';

const handlers = [
  http.get('https://api.example.com/users/:userId', ({ params }) => {
    const { userId } = params;
    if (userId === '1') {
      return HttpResponse.json({
        id: '1',
        name: 'Leyline User',
        email: 'user@leyline.io',
      });
    }
    return new HttpResponse(null, { status: 404 });
  }),
];

export const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
