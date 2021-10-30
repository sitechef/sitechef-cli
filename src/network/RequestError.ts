export const RequestErrorType = 'RequestError';
export class RequestError extends Error {
	public type = RequestErrorType;
	public constructor(public statusCode: number, err: Error) {
		super(err.message);
		this.message = err.message;
		this.name = err.name;
		this.stack = err.stack;
	}

	public static Validate(e: Error | RequestError): e is RequestError {
		return 'type' in e && e.type === RequestErrorType;
	}
}
