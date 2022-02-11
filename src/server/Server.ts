import * as http from 'http';
import proxy from 'express-http-proxy';
import mergeDeep from 'merge-deep';
import express, { Express, NextFunction, Request, Response } from 'express';
import cors from 'cors';
import { readFileSync } from 'fs';
import path from 'path';
import { AbridgedSiteChefCategory, RootContents, Snapshot } from '../snapshot';
import { runCommand } from './runCommand';
import { RenderFn, template } from './template';
import { read, SitechefRC } from '../rcFile/read';
import { log, logError } from '../logger';

type FoundData = {
	data: RootContents;
	status?: number;
	templateName: string;
	isJson: boolean;
};

type CustomFoundData = FoundData & { merge?: boolean };

type CustomDataFile = Record<string, FoundData>;

type PagesById = Record<string, AbridgedSiteChefCategory>;

interface Settings {
	themeRoot?: string;
	port?: number;
	environment?: 'development' | 'production';
	forwardingUrl?: string;
	ignoreSitechefRc?: boolean;
}
export class Server {
	public server: http.Server;
	public themeRoot: string;
	public port: number;
	public data: Snapshot;
	public customData: CustomDataFile;
	public environment: 'development' | 'production';
	public forwardingUrl: string | undefined;
	public pagesById: PagesById;
	public renderFn: RenderFn | undefined;
	public ignoreSitechefRc: boolean;

	public rcContents: SitechefRC;

	public app: Express;

	public constructor({
		themeRoot = process.cwd(),
		port = 3999,
		environment = 'development',
		ignoreSitechefRc = false,
		forwardingUrl,
	}: Settings) {
		this.themeRoot = themeRoot;
		this.ignoreSitechefRc = ignoreSitechefRc;
		this.port = port;
		this.environment = environment;
		this.forwardingUrl = forwardingUrl;
		this.rcContents = this.readSitechefRC();
		this.data = this.loadDataFile();
		this.customData = this.loadCustomDataFile();
		this.pagesById = this.filterPagesById();
		this.runCmd();
		this.app = this.generateApp();
		this.server = this.serve();
	}

	public readSitechefRC(): SitechefRC {
		if (this.ignoreSitechefRc) {
			return {};
		}
		return read(this.themeRoot);
	}

	public loadDataFile(): Snapshot {
		const p = path.join(this.themeRoot, '.sitechef', 'data.json');
		const d = readFileSync(p);
		return JSON.parse(d.toString()) as Snapshot;
	}

	public loadCustomDataFile(): CustomDataFile {
		const p = path.join(this.themeRoot, 'sitechefMockAPI.json');
		try {
			const c = readFileSync(p);
			return JSON.parse(c.toString()) as CustomDataFile;
		} catch (e: unknown) {
			return {};
		}
	}

	public filterPagesById(): PagesById {
		const nonAPIPages = Object.entries(this.data).filter(([key]) => {
			if (key.match(/^.api/)) return false;
			if (key.match(/p\/\d+(\.json)?$/)) return false;
			return true;
		});
		return nonAPIPages.reduce<PagesById>((memo, [_, value]) => {
			if (!value.content) return memo;
			memo[value.content.id] = value.content;
			return memo;
		}, {} as PagesById);
	}

	public runCmd() {
		if (this.ignoreSitechefRc) return;
		if (!this.rcContents.compileCommand) {
			logError('No `compileCommand` found in the .sitechefrc file');
			return;
		}
		runCommand(this.themeRoot, this.rcContents.compileCommand);
	}

	public generateApp(): Express {
		this.app = express();
		this.app.use(cors());

		this.app.use(
			'/assets/dist',
			express.static(path.join(this.themeRoot, 'dist'))
		);
		this.app.use('/tmp', express.static(path.join(this.themeRoot, 'tmp')));
		this.renderFn = template(path.join(this.themeRoot, 'templates'));

		this.app.all('*', this.respond.bind(this));

		if (this.forwardingUrl) {
			log(`Forwarding unhandled requests to ${this.forwardingUrl}`);
			this.app.all(
				'/*',
				proxy(this.forwardingUrl, {
					timeout: 30 * 1000,
				})
			);
		}
		this.app.use(this.handleErrors);
		return this.app;
	}

	public respond(req: Request, res: Response, next: NextFunction) {
		const result = this.getData(req);
		if (!result) {
			return next();
		}
		const { data, templateName, status = 200 } = result;
		if (req.xhr || req.headers.accept?.includes('json') || result.isJson) {
			return res.status(status).json(data);
		}

		const setup = {
			...data,
			get_page: (id: string) => {
				if (!id) return false;
				return this.pagesById[id];
			},
		};
		if (!this.renderFn) throw Error('Should have render function by request');

		this.renderFn(templateName, setup)
			.then((r) => {
				res.status(status).send(r);
			})
			.catch((e) => next(e));
	}

	public handleErrors(
		err: unknown,
		_: Request,
		res: Response,
		next: NextFunction
	) {
		if (!err) {
			return next();
		}
		res.status(500).send(
			`<h1>Error</h1>
			<h2>${(err as Error).message}</h2>
			<code>
				${(err as Error).stack?.split('<br/>')}
			</code>`
		);
	}

	public cleanUrl(req: Request): { url: string; isJson: boolean } {
		let isJson =
			!!req.headers.accept &&
			req.headers.accept.toLowerCase() === 'application/json';
		// lowercase, remove trailing slash
		const lwr = req.url.toLowerCase().replace(/([a-z0-9])\/$/, '$1');
		if (lwr.endsWith('.json')) {
			isJson = true;
			const shortUrl = lwr.replace('.json', '');
			return {
				url: shortUrl,
				isJson,
			};
		}
		if (this.data[lwr]) {
			return {
				url: lwr,
				isJson,
			};
		}
		const path = req.path.toLowerCase();
		if (this.data[path]) {
			return {
				url: path,
				isJson,
			};
		}
		if (path.endsWith('.json')) {
			const shortPath = path.replace('.json', '');
			if (this.data[shortPath]) {
				return {
					url: shortPath,
					isJson: true,
				};
			}
		}
		return {
			url: req.url,
			isJson,
		};
	}

	public getData(req: Request): FoundData | undefined {
		const { url, isJson } = this.cleanUrl(req);
		const customData = this.getCustomData(req);
		const coreData = this.data[url] ?? this.data['/'];
		if (!coreData && !customData) {
			return undefined;
		}
		coreData.environment = this.environment;
		if (customData) {
			const { data, status = 200 } = customData;
			const templateName = this.getTemplateName(req, customData);
			if (!customData.merge) {
				return {
					isJson,
					status,
					templateName,
					data,
				};
			}
			return {
				isJson,
				status,
				templateName,
				data: mergeDeep(coreData, customData.data),
			};
		}
		return {
			isJson,
			templateName: 'index.html',
			data: coreData,
			status: 200,
		};
	}

	public getCustomData(req: Request): CustomFoundData | false {
		if (req.url === '/_coming_soon') {
			return {
				templateName: 'comingSoon.html',
				status: 200,
				data: {} as any,
				isJson: false,
			};
		}
		const mockString = `${req.method}=${req.url}`;
		if (!this.customData[mockString]) return false;

		return this.customData[mockString];
	}

	public getTemplateName(_: Request, d: FoundData | false): string {
		if (!d) return 'index.html';
		return d.templateName;
	}

	public serve(): http.Server {
		return this.app.listen(this.port, () => {
			log(`Serving Sitechef Theme on port ${this.port}`);
			log(`View at http://localhost:${this.port}`);
		});
	}
}
