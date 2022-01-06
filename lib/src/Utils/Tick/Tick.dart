
import 'dart:async';

import 'package:ezflap/src/Utils/Types/Types.dart';

/// Timer-related utilities.
class Tick {
	static const Duration _ZERO_DURATION = Duration(seconds: 0);

	/// Run [func] in the next tick (i.e. in zero milliseconds).
	/// Returns a cancellation callback to cancel the pending invocation of
	/// [func].
	static TFuncCancel nextTick(Function() func) {
		return Tick._makeTimer(Tick._ZERO_DURATION, func);
	}

	/// Run [func] in [ms] milliseconds. Returns a cancellation callback.
	static TFuncCancel runInMs(int ms, void Function() func) {
		return Tick._makeTimer(Duration(milliseconds: ms), func);
	}

	/// Returns a [Future] that resolves after [ms] milliseconds.
	static Future<void> awaitMs(int ms) {
		Future<void> future = Future.delayed(Duration(milliseconds: ms));
		return future;
	}

	/// Run [func] every [ms] milliseconds. Returns a cancellation callback.
	static TFuncCancel periodic(int ms, void Function() func) {
		Timer timer = Timer.periodic(Duration(milliseconds: ms), (Timer timer) {
			func();
		});
		return () => timer.cancel();
	}

	/// Run the asynchronous [func] every [ms] milliseconds.
	///  - If [callImmediately] is true (the default) then in addition to
	///    scheduling the periodic trigger, [func] is also called immediately,
	///    and [periodicAsync] returns when [func] finishes.
	///  - If [allowReentry] is false (the default) then while [func] is
	///    running - additional invocation will be skipped, until the first
	///    invocation that is triggered after [func] returned.
	///  - Returns a cancellation callback.
	static Future<TFuncCancel> periodicAsync(int ms, TFuncAsyncAction func, [ bool callImmediately = true, bool allowReentry = false ]) async {
		if (callImmediately) {
			await func();
		}

		int numEntries = 0;
		TFuncCancel funcCancel = Tick.periodic(ms, () async {
			if (numEntries > 0 && !allowReentry) {
				return;
			}
			numEntries++;
			try {
				await func();
			}
			catch (ex) {
				rethrow;
			}
			finally {
				numEntries--;
			}
		});

		return funcCancel;
	}

	static TFuncCancel _makeTimer(Duration duration, void Function() func) {
		Timer timer = Timer(duration, func);
		return () {
			if (timer.isActive) {
				timer.cancel();
			}
		};
	}
}