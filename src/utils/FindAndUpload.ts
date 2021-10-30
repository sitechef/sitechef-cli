import { readFile } from 'fs/promises';
import glob from 'glob-promise';
import path from 'path';
import { Endpoints, getUrl } from '../config';
import { log, logError } from '../logger';
import { Request } from '../network/Request';
import { concurrentPromises } from './concurrentPromises';

export class FindAndUpload {
	public glob = '**/*.s?ss';
	public endpoint: keyof Endpoints = 'scss';

	// local subdir for starting point
	public baseDir = 'scss';
	public directoryRoot: string;

	public constructor(public themeRoot: string, public apiKey: string) {
		this.directoryRoot = path.join(this.themeRoot, this.baseDir);
	}

	public async start(): Promise<void> {
		await this.beforeStart();
		const files = await this.findFiles();
		await this.uploadFiles(files);
		log(`Uploaded files from ${this.baseDir}`);
	}

	public async findFiles(): Promise<string[]> {
		return glob.promise(this.glob, {
			cwd: this.directoryRoot,
		});
	}

	public async uploadFiles(matches: string[]): Promise<void> {
		if (matches.length === 0) {
			logError('No files found of type', this.glob);
			return;
		}
		const maxConcurrent = parseInt(`${process.env.MAX_CONCURRENT || 3}`, 10);
		await concurrentPromises(
			maxConcurrent,
			matches.map((m) => () => this.uploadFile(m))
		);
	}

	public async uploadFile(partialPath: string): Promise<void> {
		const fullPath = path.join(this.directoryRoot, partialPath);
		const contents = await readFile(fullPath);
		const req = new Request({
			url: getUrl(this.endpoint, partialPath),
			method: 'PUT',
			apiKey: this.apiKey,
			body: contents.toString(),
			json: false,
			message: `Uploading ${partialPath}`,
		});
		try {
			await req.run();
		} catch (e) {
			logError(`Failed to upload ${partialPath}. Attempting again`);
			await req.run();
		}
	}

	protected async beforeStart(): Promise<void> {}
}
