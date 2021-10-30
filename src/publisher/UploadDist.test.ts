import { mkdirSync, writeFileSync } from 'fs';
import path from 'path';
import t from 'temp';
import { MimeData, UploadDist } from './UploadDist';
import { S3Upload } from './S3Upload';
import { Request } from '../network/Request';
const temp = t.track();

jest.mock('../network/Request', () => ({
	Request: jest.fn(),
}));

jest.mock('./S3Upload', () => ({
	S3Upload: jest.fn(),
}));

const s3Mock = S3Upload as unknown as jest.Mock;

const reqMock = Request as unknown as jest.Mock;

describe('UploadDist', () => {
	let tempDir: string;
	beforeEach(() => {
		tempDir = temp.mkdirSync('stchf');
		const distDir = path.join(tempDir, 'dist');
		const subdir = path.join(tempDir, 'dist', 'subdir');
		mkdirSync(distDir);
		mkdirSync(subdir);
		['test.jpg', 'test.css', 'test.json'].forEach((f) => {
			writeFileSync(path.join(distDir, f), 'some-data');
			writeFileSync(path.join(subdir, f), 'some-data');
		});
	});
	afterEach(() => {
		temp.cleanupSync();
	});

	it('should upload all files in dist to s3', async () => {
		reqMock.mockImplementation((opts) => {
			expect(opts).toMatchInlineSnapshot(`
Object {
  "apiKey": "api-key",
  "body": Object {
    "files": Array [
      Object {
        "contentType": "text/css",
        "path": "subdir/test.css",
      },
      Object {
        "contentType": "image/jpeg",
        "path": "subdir/test.jpg",
      },
      Object {
        "contentType": "application/json",
        "path": "subdir/test.json",
      },
      Object {
        "contentType": "text/css",
        "path": "test.css",
      },
      Object {
        "contentType": "image/jpeg",
        "path": "test.jpg",
      },
      Object {
        "contentType": "application/json",
        "path": "test.json",
      },
    ],
  },
  "json": true,
  "method": "POST",
  "url": "https://themes.sitechef.co.uk/dist",
}
`);
			return {
				run: () =>
					opts.body.files.map((f: MimeData) => ({
						localPath: f.path,
						gzip: true,
					})),
			};
		});
		let paths: string[] = [];
		let policies: unknown[] = [];
		s3Mock.mockImplementation((path, policy) => {
			paths.push(path);
			policies.push(policy);
			return {
				start: () => undefined,
			};
		});

		const dist = new UploadDist(tempDir, 'api-key');
		await dist.start();
		expect(paths.length).toBe(6);
		expect(policies).toMatchInlineSnapshot(`
Array [
  Object {
    "gzip": true,
    "localPath": "subdir/test.css",
  },
  Object {
    "gzip": true,
    "localPath": "subdir/test.jpg",
  },
  Object {
    "gzip": true,
    "localPath": "subdir/test.json",
  },
  Object {
    "gzip": true,
    "localPath": "test.css",
  },
  Object {
    "gzip": true,
    "localPath": "test.jpg",
  },
  Object {
    "gzip": true,
    "localPath": "test.json",
  },
]
`);
	});
});
