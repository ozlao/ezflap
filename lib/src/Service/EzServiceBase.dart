
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

abstract class EzServiceBase extends Singleton {
	void $initDI([ Map<String, dynamic>? mapOverrides ]) {
		// we need this so that all generated services can call super.$initDI()
	}
}