import { readFile } from 'fs/promises';
import path from 'path';

export interface Colour {
	id: string;
	name: string;
}
export interface Variable {
	id: string;
	name: string;
	options: Record<string, string>;
}

export interface Font {
	id: string;
	name: string;
}

export interface ThemeJson {
	meta: {
		name: string;
		description: string;
		screenshot: string;
	};
	variables: Variable[];
	fonts: Font[];
	colours: Colour[];
}

export const read = async (root: string): Promise<ThemeJson> => {
	const p = path.join(root, 'theme.json');
	const contents = await readFile(p);
	return JSON.parse(contents.toString()) as ThemeJson;
};
