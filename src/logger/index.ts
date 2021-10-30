export const logError = (...args: unknown[]) => {
	if (process.env.NODE_ENV === 'test') {
		return;
	}
	console.error(...args);
};

export const log = (...args: unknown[]) => {
	if (process.env.NODE_ENV === 'test') {
		return;
	}
	console.log(...args);
};
