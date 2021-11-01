import AdmZip from 'adm-zip';
import glob from 'glob-promise';
import path from 'path';
import t from 'temp';
import { getUrl } from '../config';
import { Request } from '../network/Request';
import { S3Policy, S3Upload } from './S3Upload';
import { log } from '../logger';
import { unlink } from 'fs/promises';
const temp = t.track();

export class UploadZip {
	public alwaysIgnore = [
		'.sitechef',
		'node_modules',
		'prefs.scss',
		'.git',
		'tmp',
	];

	public ignore: string[];

	public constructor(
		ignoreFiles: string[],
		public apiKey: string,
		public themeRoot: string
	) {
		this.ignore = this.setupIgnore(ignoreFiles);
	}

	public setupIgnore(files: string[]): string[] {
		return Array.from(new Set([...files, ...this.alwaysIgnore]));
	}

	public async start(cleanup = true): Promise<void> {
		const zipPath = temp.path({ suffix: '.zip' });
		log('Zipping up directory');
		const zipFile = await this.buildZip(zipPath);
		log('Directory zipped');
		const policy = await this.getPolicy();
		log('Uploading zip file to S3');
		await this.uploadZipS3(policy, zipFile);
		if (!cleanup) return;
		log('Uploaded zip file. Removing temp zip file');
		await temp.cleanup();
		try {
			await unlink(zipPath);
		} catch (e) {
			//
		}
	}

	/**
	 * Creates the zip file of the theme directory
	 * @returns promise of zip path
	 */
	public async buildZip(zipPath: string): Promise<string> {
		const zip = new AdmZip();
		const directoryPaths = await glob.promise('**/*', {
			dot: true,
			ignore: [...this.ignore, ...this.ignore.map((p) => `${p}/**`)],
			cwd: this.themeRoot,
			nodir: true,
		});
		for (const p of directoryPaths) {
			log(`Adding ${p} to zip file`);
			zip.addLocalFile(path.join(this.themeRoot, p), path.dirname(p));
		}
		return new Promise((r, rj) => {
			zip.writeZip(zipPath, (err) => {
				if (err) return rj(err);
				r(zipPath);
			});
		});
	}

	public async getPolicy(): Promise<S3Policy> {
		const r = new Request<S3Policy>({
			url: getUrl('srcZip'),
			method: 'PUT',
			apiKey: this.apiKey,
		});
		return r.run();
	}

	public async uploadZipS3(
		policy: S3Policy,
		tempFilePath: string
	): Promise<void> {
		const s3 = new S3Upload(tempFilePath, policy);
		return s3.start();
	}
}
