import { exec } from 'child_process';
import path from 'path';
import { log, logError } from '../logger';

const defaultCommand = ['node_modules', '.bin', 'gulp'];

export const runCommand = async (
	basePath: string,
	command: string[] = defaultCommand
): Promise<void> => {
	const cmd = command[command.length - 1].replace(/\ .*$/, '');
	let fullPath = path.join.apply(this, [basePath].concat(command));
	// try and retain colours
	fullPath += ' --ansi';

	const child = exec(
		fullPath,
		{
			cwd: basePath,
		},
		(err, stdout, stderr) => {
			if (err || stderr) {
				logError(`${cmd} error: `, err || stderr);
			}
			logError(
				`${cmd} terminated unexpectedly. Are you sure that ${cmd} watch is configured correctly?`,
				stdout
			);
			process.exit(1);
		}
	);

	child.stderr?.on('data', (chunk) => {
		logError(cmd, chunk);
	});
	child?.stdout?.on('data', (chunk) => {
		log(cmd, chunk);
	});
};
