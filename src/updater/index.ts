import path from 'path';
import { readConfigFile } from '../configFile/read';
import { saveSnapshotFile } from '../initialiser/saveSnapshotFile';
import { log } from '../logger';

export const updater = async (themeRoot: string): Promise<void> => {
	const { code: apiKey } = readConfigFile(themeRoot);

	const destination = path.join(themeRoot, '.sitechef', 'data.json');

	await saveSnapshotFile({ apiKey, destination, themeDirectory: themeRoot });
	log(`\n\nData file updated successfully`);
};
