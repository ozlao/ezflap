
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:flutter/widgets.dart';

typedef TFuncSlotWidgetsBuilder = List<Widget> Function($SlotProviderScope);

class $SlotProviderScope {
	final Map<String, dynamic> mapParams;

	$SlotProviderScope(this.mapParams);

	dynamic noSuchMethod(Invocation invocation) {
		String? key = invocation.memberName.getName();
		if (key == null) {
			throw "Cannot parse invocation memberName: [${invocation.memberName}]. This might be a bug in ezFlap";
		}

		return this.mapParams[key];
	}
}

class $SlotProvider {
	final String? name;
	final TFuncSlotWidgetsBuilder funcBuild;

	$SlotProvider({ required this.name, required this.funcBuild });
}