
import 'dart:async';

import 'package:ezflap/src/Utils/Types/Types.dart';

class Tick {
	static Duration _zeroDuration = new Duration(seconds: 0);

	static TFuncCancel nextTick(Function() func) {
		return Tick._makeTimer(Tick._zeroDuration, func);
	}

	static TFuncCancel runInMs(int ms, void Function() func) {
		return Tick._makeTimer(Duration(milliseconds: ms), func);
	}

	static TFuncCancel _makeTimer(Duration duration, void Function() func) {
		Timer timer = Timer(duration, func);
		return () {
			if (timer.isActive) {
				timer.cancel();
			}
		};
	}

	static Future<void> awaitMs(int ms) {
		Future<void> future = Future.delayed(Duration(milliseconds: ms));
		return future;
	}

	static TFuncUnsubscribe periodic(int ms, void Function() func) {
		Timer timer = Timer.periodic(Duration(milliseconds: ms), (Timer timer) {
			func();
		});
		return () => timer.cancel();
	}

	static Future<TFuncUnsubscribe> intervalAsync(int milliseconds, TFuncAsyncAction func, [ bool callImmediately = true, bool allowReentry = false ]) async {
		if (callImmediately) {
			await func();
		}

		int numEntries = 0;
		TFuncUnsubscribe funcUnsubscribe = Tick.periodic(milliseconds, () async {
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

		return funcUnsubscribe;
	}
}