import { S3Policy, S3Upload } from './S3Upload';
import request from 'request';
import temp from 'temp';
import { writeFileSync } from 'fs';

jest.mock('request', () => jest.fn());

describe('S3Upload', () => {
	const policy: S3Policy = {
		'Content-Type': 'text/plain',
		AWSAccessKeyId: 'aws-access-key',
		acl: 'acl-settings',
		bucket: 'testbucket',
		key: 'path/to/file',
		localPath: 'local/path',
		policy: '{"s3policy": true}',
		signature: 's3-signature',
		gzip: true,
	};
	let filePath: string;
	beforeEach(() => {
		filePath = temp.path();
		writeFileSync(filePath, 'demoFile');
	});
	afterEach(() => {
		temp.cleanupSync();
	});
	it('should upload to s3', async () => {
		const s3 = new S3Upload(filePath, policy);
		(request as unknown as jest.Mock).mockImplementation((opts, cb) => {
			const { url, method, formData } = opts;
			expect(method).toBe('POST');
			expect(url).toBe('https://testbucket.s3.amazonaws.com/');
			const { file, ...otherOpts } = formData;
			expect(file).toBeTruthy();
			expect(otherOpts).toMatchInlineSnapshot(`
Object {
  "AWSAccessKeyId": "aws-access-key",
  "Content-Encoding": "gzip",
  "Content-Length": 8,
  "Content-Type": "text/plain",
  "acl": "acl-settings",
  "key": "path/to/file",
  "policy": "{\\"s3policy\\": true}",
  "signature": "s3-signature",
}
`);
			cb(null, {
				statusCode: 200,
				statusMessage: 'ok',
			});
		});
		await s3.start();
	});
	it('should retry if failed the first time', async () => {
		const s3 = new S3Upload(filePath, policy);
		let count = 0;
		(request as unknown as jest.Mock).mockImplementation((_, cb) => {
			if (count == 1) {
				return cb(null, {
					statusCode: 200,
					statusMessage: 'ok',
				});
			}
			count++;
			return cb(null, {
				statusCode: 503,
				statusMessage: 'try again',
			});
		});
		await s3.start();
		expect(s3.retried).toBe(1);
	});
});
