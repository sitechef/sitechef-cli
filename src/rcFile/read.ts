import { readFileSync } from 'fs';
import path from 'path';
import { logError } from '../logger';

export interface SitechefRC {
	compileCommand?: string[];
	ignore?: string[];
}

export const read = (themeRoot: string): SitechefRC => {
	const rcPath = path.join(themeRoot, '.sitechefrc');
	try {
		const data = readFileSync(rcPath);
		return JSON.parse(data.toString()) as SitechefRC;
	} catch (e) {
		logError('Could not find a valid .sitechefrc at the project root', rcPath);
		process.exit(1);
	}
};
