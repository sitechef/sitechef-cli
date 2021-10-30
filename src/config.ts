declare global {
	interface process {
		env: {
			LOCAL_SERVER?: string;
			MAX_CONCURRENT?: number;
		};
	}
}
/**
 * Defaults for interacting with the theme api
 *
 * Generates object with themesHost and endpoint as keys
 */
export type Endpoints = {
	srcZip: string;
	dataFile: string;
	themeMeta: string;
	htmlZip: string;
	html: string;
	scss: string;
	dist: string;
};

interface Config {
	themesHost: string;
	endpoints: Endpoints;
}

export const config: Config = {
	themesHost: process.env.LOCAL_SERVER ?? 'https://themes.sitechef.co.uk',
	endpoints: {
		srcZip: 'srczip',
		scss: 'scss',
		dataFile: 'datafile',
		themeMeta: 'theme',
		htmlZip: 'html.zip',
		html: 'html',
		dist: 'dist',
	},
};

export const getUrl = (endpoint: keyof Endpoints, path?: string): string => {
	if (!config.endpoints[endpoint]) throw Error(`Unknown endpoing ${endpoint}`);
	return `${config.themesHost}/${config.endpoints[endpoint]}${
		path ? `/${path}` : ''
	}`;
};
