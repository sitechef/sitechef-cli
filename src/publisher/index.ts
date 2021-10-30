import { readConfigFile } from '../configFile/read';
import { getUrl } from '../config';
import { Request } from '../network/Request';
import { read } from '../rcFile/read';
import { read as readTheme } from './themeJson';
import { UploadSCSS } from './UploadSCSS';
import { UploadDist } from './UploadDist';
import { UploadTemplateFiles } from './UploadTemplateFiles';
import { UploadZip } from './UploadZip';
import { log } from '../logger';

export class Publisher {
	public ignoreFiles: string[];
	public apiKey: string;
	constructor(public themeRoot: string) {
		const { code: apiKey } = readConfigFile(this.themeRoot);
		this.apiKey = apiKey;
		this.ignoreFiles = this.parseIgnores();
	}

	public async start(): Promise<void> {
		await this.clearS3();
		await this.updateThemeMetadata();
		await this.uploadScssFiles();
		await this.uploadDist();
		await this.uploadTemplateFiles();
		await this.uploadZip();
	}

	public async clearS3(): Promise<void> {
		log('Clearing previous theme');
		const r = new Request({
			url: getUrl('themeMeta'),
			method: 'DELETE',
			apiKey: this.apiKey,
		});
		await r.run();
	}

	public async updateThemeMetadata(): Promise<void> {
		const { meta, variables } = await readTheme(this.themeRoot);

		const req = new Request({
			url: getUrl('themeMeta'),
			method: 'PUT',
			apiKey: this.apiKey,
			json: true,
			body: { meta, variables },
		});
		await req.run();
	}

	public async uploadScssFiles(): Promise<void> {
		const uploader = new UploadSCSS(this.themeRoot, this.apiKey);
		await uploader.start();
	}

	public async uploadDist(): Promise<void> {
		const dist = new UploadDist(this.themeRoot, this.apiKey);
		return dist.start();
	}

	public async uploadTemplateFiles(): Promise<void> {
		const templates = new UploadTemplateFiles(this.themeRoot, this.apiKey);
		return templates.start();
	}

	public async uploadZip(): Promise<void> {
		const zipper = new UploadZip(this.ignoreFiles, this.apiKey, this.themeRoot);
		return zipper.start();
	}

	public parseIgnores(): string[] {
		return read(this.themeRoot).ignore ?? [];
	}
}
