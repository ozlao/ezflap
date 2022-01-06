
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

class SvcEzflapTester extends EzServiceBase {
	static SvcEzflapTester i() { return $Singleton.get(() => SvcEzflapTester()); }
}