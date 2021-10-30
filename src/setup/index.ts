import { readdir, mkdir } from 'fs/promises';
import path from 'path';
import { saveSnapshotFile } from '../initialiser/saveSnapshotFile';
import { writeConfigFile } from '../configFile/write';
import { log } from '../logger';

/**
 * Generates the core sitechef config files
 *
 * @param themeRoot
 * @param apiKey
 */
export const Setup = async (
	themeRoot: string,
	apiKey: string
): Promise<void> => {
	const sitechefDir = path.join(themeRoot, '.sitechef');

	// validate the directory
	try {
		await readdir(sitechefDir);
	} catch (e) {
		// directory doesn't exist
		await mkdir(sitechefDir);
	}

	await writeConfigFile(apiKey, sitechefDir);
	await saveSnapshotFile({
		apiKey,
		destination: path.join(sitechefDir, 'data.json'),
		themeDirectory: themeRoot,
	});
	log('Written Sitechef files. Run `sitechef serve` to execute');
};
