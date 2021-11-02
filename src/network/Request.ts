import fetch, { Response } from 'node-fetch';
import { Spinner } from 'cli-spinner';
import { RequestError } from './RequestError';
import { log, logError } from '../logger';

interface Settings<T> {
	method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
	url: string;
	apiKey?: string;
	body?: T;
	json?: boolean;
	require200?: boolean;
	message?: string;
	spinner?: boolean;
}

export class Request<Result, Body = never> {
	protected spinner: Spinner;
	constructor(public settings: Settings<Body>) {
		this.spinner = new Spinner(
			`requesting ${
				settings.message ?? settings.url + '-' + settings.method
			}... %s`
		);
	}

	public async run(): Promise<Result> {
		const {
			url,
			method = 'GET',
			require200 = true,
			json = true,
			spinner = false,
		} = this.settings;
		if (spinner) {
			this.spinner.start();
		} else {
			log(`Request: ${this.settings.message ?? this.settings.url}`);
		}
		let res: Response;
		try {
			res = await fetch(url, {
				headers: this.makeHeaders(),
				method,
				body: this.getBody(),
			});
		} catch (e: unknown) {
			throw new RequestError(0, e as Error);
		} finally {
			if (this.settings.spinner) {
				this.spinner.stop();
				console.log('\n');
			}
		}
		if (require200 && res.status !== 200) {
			logError(await res.text());
			throw new RequestError(
				res.status,
				Error(`Unexpected status when downloading ${url}: ${res.status}`)
			);
		}
		if (json) {
			const result = (await res.json()) as Result;
			return result;
		}
		const blob = await res.blob();
		return blob as unknown as Result;
	}

	public getBody(): string | undefined {
		const { body, json = true } = this.settings;
		if (!body) return undefined;
		if (json) return JSON.stringify(body);
		return body as any as string;
	}

	public makeHeaders(): Record<string, string> {
		if (!this.settings.apiKey) return {};
		const headers: Record<string, string> = {
			'X-Api-Auth': this.settings.apiKey,
			'X-Sitechef-Version': global.SITECHEF_VERSION,
		};
		if (this.settings.json) {
			headers['Accept'] = 'application/json';
			headers['Content-Type'] = 'application/json';
		}
		return headers;
	}
}
