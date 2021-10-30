import { mkdirSync, writeFileSync } from 'fs';
import path from 'path';
import t from 'temp';
import { FindAndUpload } from './FindAndUpload';
import { Request } from '../network/Request';
const temp = t.track();

jest.mock('../network/Request', () => ({
	Request: jest.fn(),
}));

const reqMock = Request as unknown as jest.Mock;

describe('FindAndUpload', () => {
	let baseDir: string;
	beforeEach(() => {
		baseDir = temp.mkdirSync('stcf');
		const scssDir = path.join(baseDir, 'scss');
		mkdirSync(scssDir);
		[
			'a.scss',
			'b.sass',
			'test.json',
			'.sitechef',
			'prefs.scss',
			'other.scss',
		].forEach((f) => {
			writeFileSync(path.join(scssDir, f), 'some-data');
		});
	});
	afterEach(() => {
		temp.cleanupSync();
	});
	it('should create a new request for each file', async () => {
		const paths: Set<string> = new Set();
		const output: Set<any> = new Set();
		const messages: Set<string> = new Set();
		reqMock.mockImplementation((opts) => {
			const { url, message, ...otherOpts } = opts;
			messages.add(message);
			paths.add(url);
			output.add(otherOpts);
			return {
				run: () => Promise.resolve(true),
			};
		});
		const u = new FindAndUpload(baseDir, 'api-key');
		await u.start();
		expect(Array.from(paths).sort()).toMatchInlineSnapshot(`
Array [
  "https://themes.sitechef.co.uk/scss/a.scss",
  "https://themes.sitechef.co.uk/scss/b.sass",
  "https://themes.sitechef.co.uk/scss/other.scss",
  "https://themes.sitechef.co.uk/scss/prefs.scss",
]
`);
		expect(output).toMatchInlineSnapshot(`
Set {
  Object {
    "apiKey": "api-key",
    "body": "some-data",
    "json": false,
    "method": "PUT",
  },
  Object {
    "apiKey": "api-key",
    "body": "some-data",
    "json": false,
    "method": "PUT",
  },
  Object {
    "apiKey": "api-key",
    "body": "some-data",
    "json": false,
    "method": "PUT",
  },
  Object {
    "apiKey": "api-key",
    "body": "some-data",
    "json": false,
    "method": "PUT",
  },
}
`);
		expect(Array.from(messages).sort()).toMatchInlineSnapshot(`
Array [
  "Uploading a.scss",
  "Uploading b.sass",
  "Uploading other.scss",
  "Uploading prefs.scss",
]
`);
	});
});
