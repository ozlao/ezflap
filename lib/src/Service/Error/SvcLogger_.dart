
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Utils/EzError/EzError.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

class SvcLogger extends EzServiceBase {
	static SvcLogger i() { return Singleton.get(() => SvcLogger()); }

	List<EzError>? _arrPreviousErrors;
	List<EzError>? _arrErrors;

	T invoke<T>(T Function() func) {
		this._arrErrors = [ ];

		try {
			return func();
		}
		on EzError catch (error) {
			this.printPendingLoggedErrorsOnException();
			this.printError(error);
			rethrow;
		}
		catch (error) {
			this.printPendingLoggedErrorsOnException();
			rethrow;
		}
		finally {
			this._arrPreviousErrors = this._arrErrors;
			this._arrErrors = null;
		}
	}

	void logErrorFrom(String component, String message) {
		this.logError(EzError(component, message));
	}

	void logError(EzError error) {
		if (this._arrErrors == null) {
			throw EzError("SvcLogger", "Cannot log outside of SvcLogger.invoke(). Logged error: ${error}");
		}
		this._arrErrors!.add(error);
	}

	bool hasLoggedErrors() {
		return this._arrPreviousErrors?.isNotEmpty ?? false;
	}

	List<EzError> getLoggedErrors() {
		return this._arrPreviousErrors ?? [ ];
	}

	void printPendingLoggedErrorsOnException() {
		if (this._arrErrors != null) {
			this._arrErrors!.forEach((x) => this.printError(x));
		}
	}

	void printLoggedErrorsIfNeeded() {
		if (this.hasLoggedErrors()) {
			this.getLoggedErrors().forEach((x) => this.printError(x));
		}
	}

	void printError(EzError error) {
		print("Error: ${error}");
	}
}