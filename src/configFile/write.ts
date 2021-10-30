import { writeFile } from 'fs/promises';
import path from 'path';

export interface MetaFile {
	code: string;
	createdAt: Date;
	lastPublished: boolean;
}

export const writeConfigFile = async (
	apiKey: string,
	sitechefDir: string
): Promise<string> => {
	const data: MetaFile = {
		code: apiKey,
		createdAt: new Date(),
		lastPublished: false,
	};

	const dest = path.join(sitechefDir, '.conf');
	await writeFile(dest, JSON.stringify(data));
	return dest;
};
