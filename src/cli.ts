import fs from 'fs';
import minimist from 'minimist';
import { Publisher } from './publisher';
import { Server } from './server/Server';
import { Setup } from './setup';
import { updater } from './updater';

declare global {
	var SITECHEF_VERSION: string;
}

export const run = () => {
	const packageData = JSON.parse(
		fs.readFileSync(__dirname + '/../package.json').toString()
	);
	global.SITECHEF_VERSION = packageData.version;

	const baseInstructions = `
    SiteChef Command Line Utility Version ${packageData.version}
	`;

	const instructions = `
		${baseInstructions}
    
    Usage:
    
      sitechef init <apikey> [<directory name>]
    
           Downloads all the theme information from the server
           using the ApiKey generated at admin.sitechef.co.uk
           If no directory name specified it will generate 
           from the theme name
    
      sitechef setup <apikey>
    
           Writes the sitechef config file and downloads the latest json
           snapshot writing data to the current directory.
           Used when setting up a cloned git repo.
    
      sitechef serve [-p <port>] [-e <development|production>] [-f <proxy hostname>]
    
           Serves the template at http://localhost:3999/ 
           -p specify override port eg 9000  
           -e override environment for templating eg 'production' 
           -f forward unhandled requests to this hostname eg 'http://localhost:3030' 
    
           To mock up custom pages 
           (ie for email template development or mock apis)
           create a \`sitechefMockAPI.json\` file in the root of your project
           with the following structure:
           {
             "<METHOD>=/override/url/": {"
               "templateName": "<your_override_template.html>",
               "status": "<status code to return>",
               "merge": "<bool:whether to merge this data with default page data>",
               "data": {...} // any data to serve "
             }, ... 
           }
    
      sitechef publish
           
           Publishes your theme back to SiteChef
    
      sitechef update
    
           Updates your local data file from the latest
           data on the website.
           N.B. Remember to run 'Generate JSON Snapshot' first
                (found in the Theme Manager at admin.sitechef.co.uk)
    
	`;
	const argv = minimist(process.argv.slice(2));

	const sendInstructions = () => {
		console.log(instructions);
		process.exit(0);
	};

	if (!argv._.length) {
		sendInstructions();
		return;
	}
	const action = argv._[0];
	const cwd = process.cwd();

	switch (action) {
		case 'init':
			console.error('init not implemented yet');
			process.exit(1);
			return;
		case 'setup': {
			if (argv._.length < 2) {
				return sendInstructions();
			}
			const apiKey = argv._[1];
			console.log(baseInstructions);
			console.log('\n\nWriting core sitechef files...');
			Setup(cwd, apiKey).catch((e) => {
				console.error(e);
			});
			return;
		}
		case 'serve': {
			const port = argv.p ?? undefined;
			const environment = argv.e ?? undefined;
			const forwardingUrl = argv.f ?? undefined;
			new Server({
				environment,
				forwardingUrl,
				port,
				themeRoot: cwd,
			});
			return;
		}

		case 'update-data':
		case 'data-update':
		case 'update': {
			updater(cwd).catch((e) => {
				throw e;
			});
			return;
		}
		case 'publish': {
			console.log('Starting publish of current theme file');
			const p = new Publisher(cwd);
			p.start()
				.then(() => {
					console.log('Publish complete');
				})
				.catch((e) => console.error('Publish Failed', e));
			return;
		}
	}
	console.error(`Unknown command ${action}`);
	console.log(instructions);
	return;
};

export default run;
