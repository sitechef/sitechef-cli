import { Endpoints } from '../config';
import { FindAndUpload } from '../utils/FindAndUpload';

export class UploadSCSS extends FindAndUpload {
	public glob = '**/*.s?ss';
	public baseDir = 'scss';
	public endpoint: keyof Endpoints = 'scss';
}
