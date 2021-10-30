import { make } from './NunjucksEnv';

export type RenderFn = (
	template: string,
	data: object | undefined
) => Promise<string>;
export const template = (rootDir: string): RenderFn => {
	const env = make(rootDir);

	return (template: string, data: object | undefined): Promise<string> => {
		return new Promise((res, rej) => {
			try {
				env.render(template, data, (err: any | null, result: string | null) => {
					if (err) {
						rej(err);
						return;
					}
					if (result) {
						res(result);
					}
					rej('no result');
				});
			} catch (e: unknown) {
				const err = e as Error;
				const errorMessage = `
				<h1>Error Rendering Templates</h1>
				<h4>${err.message}</h4>
				<code>${err.stack?.replace('\n', '<br/>')}</code>`;
				res(errorMessage);
			}
		});
	};
};
