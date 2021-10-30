import { Endpoints, getUrl } from '../config';
import { log } from '../logger';
import { Request } from '../network/Request';
import { FindAndUpload } from '../utils/FindAndUpload';

export class UploadTemplateFiles extends FindAndUpload {
	public glob = '**/*.html';

	public endpoint: keyof Endpoints = 'html';
	public baseDir = 'templates';

	/**
	 * Clear all previously registered html files
	 * for this project before uploading new ones
	 */
	public async beforeStart(): Promise<void> {
		const r = new Request({
			url: getUrl(this.endpoint),
			method: 'DELETE',
			apiKey: this.apiKey,
		});
		log('Removing existing template files');
		await r.run();
	}
}
