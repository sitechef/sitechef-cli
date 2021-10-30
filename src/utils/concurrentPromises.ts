// Adapted from https://gist.github.com/jcouyang/632709f30e12a7879a73e9e132c0d56b
export const concurrentPromises = <T>(
	maxConcurrent: number,
	list: Array<() => Promise<T>>
): Promise<T[]> => {
	let tail = list.splice(maxConcurrent);
	let head = list;
	let resolved: Array<Promise<T>> = [];
	let processed = 0;
	return new Promise((resolve) => {
		head.forEach((x) => {
			let res = x();
			resolved.push(res);
			res.then((y) => {
				runNext();
				return y;
			});
		});
		function runNext() {
			if (processed == tail.length) {
				resolve(Promise.all(resolved));
			} else {
				resolved.push(
					tail[processed]().then((x) => {
						runNext();
						return x;
					})
				);
				processed++;
			}
		}
	});
};
