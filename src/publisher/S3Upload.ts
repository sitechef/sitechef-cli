import { createReadStream, ReadStream } from 'fs';
import { stat } from 'fs/promises';
import request from 'request';
import { log, logError } from '../logger';

export interface S3Policy {
	policy: string;
	signature: string;
	gzip?: boolean;
	bucket: string;
	key: string;
	acl: string;
	localPath: string;
	'Content-Type': string;
	AWSAccessKeyId: string;
}

interface RequestOptions {
	method: 'POST';
	url: string;
	formData: {
		key: string;
		AWSAccessKeyId: string;
		acl: string;
		policy: string;
		signature: string;
		'Content-Type': string;
		'Content-Encoding'?: string;
		'Content-Length'?: number;
		file?: ReadStream;
	};
}

export class S3Upload {
	public retryLimit = 2;

	public retried = 0;
	public complete = false;

	public constructor(
		public filePath: string,
		public policy: S3Policy,
		public acl = 'public-read'
	) {}

	public async start(): Promise<void> {
		const size = await this.getFileSize();
		await this.upload(size);
	}

	public async upload(fileSize: number): Promise<void> {
		const opts = this.makeOptions(fileSize);

		log(`Uploading to ${this.policy.key}...`);

		const response = await new Promise<request.Response>((rs, rj) => {
			request(opts, (err, resp) => {
				if (err) return rj(err);
				rs(resp);
			});
		});

		if ([200, 204].includes(response.statusCode)) {
			log(`Successfully uploaded ${this.policy.key}`);
			return;
		}
		logError(
			`Failed to upload ${this.policy.key}. Status ${response.statusCode} -- ${response.statusMessage}`
		);

		if (this.retried < this.retryLimit) {
			this.retried++;
			return this.upload(fileSize);
		}
		throw Error(
			`Failed to upload ${this.policy.key} after ${this.retryLimit} attempts`
		);
	}

	public async getFileSize(): Promise<number> {
		const res = await stat(this.filePath);
		return res.size;
	}

	public makeOptions(size: number): RequestOptions {
		const { bucket, gzip, localPath: _, ...remainingPolicy } = this.policy;
		const settings: RequestOptions = {
			url: `https://${bucket}.s3.amazonaws.com/`,
			method: 'POST',
			formData: {
				...remainingPolicy,
			},
		};
		if (gzip) {
			settings.formData['Content-Encoding'] = 'gzip';
		}
		settings.formData['Content-Length'] = size;
		settings.formData.file = createReadStream(this.filePath);
		return settings;
	}
}
