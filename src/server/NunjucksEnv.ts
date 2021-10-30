import moment from 'moment';
import nunjucks from 'nunjucks';

/**
 * Creates a random integer between 0 and val
 * @param val
 */
export const rnd = (val: number): number => {
	if (!val) return val;
	return Math.floor(Math.random() * val);
};

export const nl2br = (val: string): string => {
	if (val === undefined || val === null) return '';
	if (typeof val !== 'string') return val;
	return val.replace(/\n/g, '<br/>');
};

export const json_encode = (val: unknown): string => {
	if (!val) return JSON.stringify(val);
	return JSON.stringify(val).replace(/\//g, '\\/');
};

export const striptags = (val: string): string => {
	if (typeof val !== 'string') return val;
	return val.replace(/\<[^\>]+\>/g, '');
};

export const format_date = (
	val: string,
	format: string,
	inputFormat: moment.MomentFormatSpecification = 'YYY-MM-DD HH:mm:ss'
) => {
	if (typeof val !== 'string') return val;
	const m = moment(val, inputFormat);
	return m.format(format);
};

export const filters = {
	rnd,
	nl2br,
	json_encode,
	striptags,
	format_date,
};

export const make = (rootDir: string) => {
	const env = nunjucks.configure(rootDir, {
		autoescape: true,
		watch: true,
	});
	Object.entries(filters).forEach(([key, fn]) => {
		env.addFilter(key, fn);
	});
	return env;
};
