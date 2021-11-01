import { mkdirSync, writeFileSync } from 'fs';
import path from 'path';
import t from 'temp';
import { UploadZip } from './UploadZip';
import { Request } from '../network/Request';
import glob from 'glob-promise';
import AdmZip from 'adm-zip';
import { unlink } from 'fs/promises';

const temp = t.track();

jest.mock('../network/Request', () => ({
	Request: jest.fn(),
}));

const reqMock = Request as unknown as jest.Mock;

describe('UploadZip', () => {
	let tempDir: string;

	beforeEach(() => {
		tempDir = temp.mkdirSync('stchf');
		const distDir = path.join(tempDir, 'dist');
		const subdir = path.join(tempDir, 'dist', 'subdir');
		const fakeNode = path.join(tempDir, 'node_modules');
		const ignoredSubdir = path.join(tempDir, 'ignored');
		mkdirSync(distDir);
		mkdirSync(subdir);
		mkdirSync(fakeNode);
		mkdirSync(ignoredSubdir);
		[
			'test.jpg',
			'test.css',
			'test.json',
			'.sitechef',
			'prefs.scss',
			'tmp',
		].forEach((f) => {
			writeFileSync(path.join(tempDir, f), 'some-data');
			writeFileSync(path.join(distDir, f), 'some-data');
			writeFileSync(path.join(subdir, f), 'some-data');
			writeFileSync(path.join(fakeNode, f), 'some-data');
			writeFileSync(path.join(ignoredSubdir, f), 'some-data');
		});
	});
	afterEach(async () => {
		await temp.cleanup();
	});

	it('should zip up temp directory excluding ignored files', async () => {
		const z = new UploadZip(['ignored'], 'api-key', tempDir);
		const uploadZip = jest.fn();
		(z as any).uploadZipS3 = uploadZip;
		reqMock.mockImplementation((opts) => {
			expect(opts).toMatchInlineSnapshot(`
Object {
  "apiKey": "api-key",
  "method": "PUT",
  "url": "https://themes.sitechef.co.uk/srczip",
}
`);
			return {
				run: () => ({
					policy: 'example-policy',
				}),
			};
		});
		await z.start(false);
		expect(reqMock).toHaveBeenCalled();
		expect(uploadZip.mock.calls[0][0]).toMatchInlineSnapshot(`
Object {
  "policy": "example-policy",
}
`);
		const filePath = uploadZip.mock.calls[0][1];
		expect(filePath).toContain('zip');
		// unzip this to a temporary directory
		const dir = temp.mkdirSync();
		const zip = new AdmZip(filePath);
		await zip.extractAllTo(dir, true);
		const output = await glob.promise('**/*', {
			cwd: dir,
		});
		expect(output).toMatchInlineSnapshot(`
Array [
  "dist",
  "dist/prefs.scss",
  "dist/subdir",
  "dist/subdir/prefs.scss",
  "dist/subdir/test.css",
  "dist/subdir/test.jpg",
  "dist/subdir/test.json",
  "dist/subdir/tmp",
  "dist/test.css",
  "dist/test.jpg",
  "dist/test.json",
  "dist/tmp",
  "test.css",
  "test.jpg",
  "test.json",
]
`);
		await unlink(filePath);
		temp.cleanupSync();
	});
});
