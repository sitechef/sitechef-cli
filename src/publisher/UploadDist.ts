import { createGzip } from 'zlib';
import glob from 'glob-promise';
import path from 'path';
import mime from 'mime';
import { v1 } from 'uuid';
import { Request } from '../network/Request';
import { getUrl } from '../config';
import { S3Policy, S3Upload } from './S3Upload';
import { concurrentPromises } from '../utils/concurrentPromises';
import { tmpdir } from 'os';
import { createReadStream, createWriteStream } from 'fs';
import { unlink } from 'fs/promises';

export interface MimeData {
	path: string;
	contentType: string;
}

export class UploadDist {
	public glob = '**/*';
	public maxConcurrent = parseInt(`${process.env.MAX_CONCURRENT ?? 3}`, 10);

	public constructor(public themeRoot: string, public apiKey: string) {}

	public async start(): Promise<void> {
		const files = await this.getFileList();
		const mimes = this.getMimes(files);
		const policies = await this.getPolicies(mimes);
		await this.uploadAllFiles(policies);
	}

	public async getFileList(): Promise<string[]> {
		return await glob.promise(this.glob, {
			cwd: path.join(this.themeRoot, 'dist'),
			nodir: true,
		});
	}

	public getMimes(files: string[]): MimeData[] {
		return files.map<MimeData>((f) => ({
			path: f,
			contentType: mime.getType(f) ?? 'text/plain',
		}));
	}

	public async getPolicies(files: MimeData[]): Promise<S3Policy[]> {
		const r = new Request<S3Policy[], { files: MimeData[] }>({
			method: 'POST',
			url: getUrl('dist'),
			apiKey: this.apiKey,
			json: true,
			body: {
				files,
			},
		});
		return r.run();
	}

	public async uploadAllFiles(policies: S3Policy[]): Promise<void> {
		await concurrentPromises(
			this.maxConcurrent,
			policies.map((p) => () => this.uploadFile(p))
		);
	}

	public async uploadFile(policy: S3Policy): Promise<void> {
		const path = await this.getFilePath(policy);
		const s3 = new S3Upload(path, policy);
		await s3.start();
		await this.deleteGzipFile(policy, path);
	}

	public async getFilePath(policy: S3Policy): Promise<string> {
		const localPath = path.join(this.themeRoot, 'dist', policy.localPath);

		if (!policy.gzip) {
			return localPath;
		}
		// create new gzip file
		const tmpLocation = path.join(tmpdir(), 'stchf-' + v1());

		const input = createReadStream(localPath);
		const output = createWriteStream(tmpLocation);
		return new Promise((rs, rj) => {
			output.on('finish', () => rs(tmpLocation));
			output.on('error', (e) => rj(e));
			const gzip = createGzip();
			input.pipe(gzip).pipe(output);
		});
	}

	public async deleteGzipFile(policy: S3Policy, path: string): Promise<void> {
		if (!policy.gzip) return;
		if (!path.match(/stchf/)) return;

		await unlink(path);
	}
}
