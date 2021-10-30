import { writeFile } from 'fs/promises';
import { getUrl } from '../config';
import { Request } from '../network/Request';
import { RequestError } from '../network/RequestError';
import { Snapshot } from '../snapshot';
import { createPrefs } from './createPrefs';

interface Options {
	apiKey: string;
	destination: string;
	themeDirectory: string;
}
export const saveSnapshotFile = async ({
	apiKey,
	destination,
	themeDirectory,
}: Options): Promise<string> => {
	const rq = new Request<string>({
		apiKey,
		url: getUrl('dataFile'),
		message: 'Finding json snapshot file',
	});

	let url: string;
	try {
		url = await rq.run();
	} catch (e: unknown) {
		const err = e as Error;
		if (RequestError.Validate(err)) {
			if (err.statusCode === 404) {
				err.message =
					'No JSON snapshot found for the connected site -- please create one first';
			}
			throw err;
		}
		throw err;
	}
	const snapshotReq = new Request<Snapshot>({
		url,
		message: 'Downloading snapshot file (sometimes large!)',
	});

	const snapshot = await snapshotReq.run();

	await writeFile(destination, JSON.stringify(snapshot));

	await createPrefs(snapshot, themeDirectory);
	return destination;
};
