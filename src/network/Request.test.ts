import { Request } from './Request';
import nodeFetch from 'node-fetch';

jest.mock('node-fetch', () => jest.fn());

const nodeFetchMock = nodeFetch as unknown as jest.Mock;

describe('Request', () => {
	it('should generate a json request successfully', async () => {
		const r = new Request({
			url: 'http://test.url/com',
			apiKey: 'test-api-key',
			body: {
				test: {
					var: 'test',
				},
			},
			json: true,
			message: 'loading test',
			method: 'PUT',
			require200: true,
		});
		const textMock = jest.fn();
		const blobMock = jest.fn();
		const output = { output: 'result' };
		const jsonMock = jest.fn(() => output);
		nodeFetchMock.mockResolvedValue({
			status: 200,
			text: textMock,
			json: jsonMock,
			blob: blobMock,
		});
		const result = await r.run();
		expect(nodeFetchMock.mock.calls[0]).toMatchInlineSnapshot(`
Array [
  "http://test.url/com",
  Object {
    "body": "{\\"test\\":{\\"var\\":\\"test\\"}}",
    "headers": Object {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-Api-Auth": "test-api-key",
      "X-Sitechef-Version": undefined,
    },
    "method": "PUT",
  },
]
`);
		expect(jsonMock).toHaveBeenCalled();
		expect(result).toBe(output);
	});
});
