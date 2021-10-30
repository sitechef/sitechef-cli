import { readFileSync } from 'fs';
import path from 'path';
import { logError } from '../logger';
import { MetaFile } from './write';

export const readConfigFile = (themeRoot: string): MetaFile => {
	logError('...reading configuration');
	try {
		const f = readFileSync(path.join(themeRoot, '.sitechef', '.conf'));
		return JSON.parse(f.toString()) as MetaFile;
	} catch (e) {
		logError('Failed to read sitechef config file', e);
		throw new Error('Failed to read config file');
	}
};
