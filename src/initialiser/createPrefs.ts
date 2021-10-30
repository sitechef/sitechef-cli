import { writeFile } from 'fs/promises';
import path from 'path';
import { Snapshot } from '../snapshot';

export const createPrefs = async (
	snapshot: Snapshot,
	themeDir: string
): Promise<void> => {
	const imagePathUri = ['siteLogo', 'siteLogo_2x', 'favicon'];
	const scssFile = Object.entries(snapshot['/'].preferences).reduce(
		(o, [key, value]) => {
			if (typeof value === 'string') {
				let content = value.replace(/[\n\']+\g/, '');
				if (imagePathUri.includes(key)) {
					content = `${snapshot['/'].imageRoot}images${content}`;
				}
				return `${o}$${key}:'${value}';\n`;
			}
			return o;
		},
		''
	);
	await writeFile(path.join(themeDir, 'prefs.scss'), scssFile);
};
