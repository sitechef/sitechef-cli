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
	public directoryRoot: string = process.cwd();

	public constructor(public themeRoot: string, public apiKey: string) {}

	protected setup(): void {
		this.directoryRoot = path.join(this.themeRoot, this.baseDir);
	}

	public async start(): Promise<void> {
		this.setup();
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
			logError(`No files found matching ${this.glob} in ${this.directoryRoot}`);
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
		const url = getUrl(this.endpoint, partialPath);
		const body = contents.toString();
		const req = new Request({
			url,
			method: 'PUT',
			apiKey: this.apiKey,
			body,
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
