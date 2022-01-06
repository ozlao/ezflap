
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';
import 'package:meta/meta.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/di/di.html#services
///
/// All services (i.e. classes that are annotated with [EzService]) extend
/// the generated `_EzServiceBase` class.
/// `_EzServiceBase` always extends [EzServiceBase] directly or indirectly.
/// By default, it extends [EzServiceBase] directly.
/// However, if the `overrideBaseClassType` parameter is passed to the
/// [EzService] annotation - then `_EzServiceBase` will extends the type passed
/// with `overrideBaseClassType`.
/// In such case, the "custom" class passed in `overrideBaseClassType` must
/// extend [EzServiceBase] (directly or indirectly).
abstract class EzServiceBase extends $Singleton {
	@internal
	void $initDI([ Map<String, dynamic>? mapOverrides ]) {
		// we need this so that all generated services can call super.$initDI()
	}
}