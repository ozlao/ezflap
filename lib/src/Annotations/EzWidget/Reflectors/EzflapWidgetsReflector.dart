
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzEmit/EzEmitVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ClassDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/SvcReflector_.dart';

class EzflapWidgetDescriptor {
	final String widgetClassName;
	late final Map<String, String> mapEzEmitFunctionParenthesesParts;

	EzflapWidgetDescriptor({ required this.widgetClassName }) {
		this.mapEzEmitFunctionParenthesesParts = { };
	}
}

class EzflapWidgetsReflector {
	static const String _COMPONENT = "UsedWidgetsVisitor";

	SvcLogger get _svcLogger { return SvcLogger.i(); }
	SvcReflector get _svcReflector => SvcReflector.i();

	EzflapWidgetDescriptor? getUsedWidgetDataForWidgetClass(String className) {
		ClassDescriptor? classDescriptor = this._svcReflector.describeClass(className);
		if (classDescriptor == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Could not find Widget class [${className}].");
			return null;
		}
		
		if (!classDescriptor.isEzflapWidget) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Referenced Widget class [${className}] is not an ezFlap widget.");
			return null;
		}

		if (classDescriptor.stateClassElement == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Could not figure find state class for Widget [${className}].");
			return null;
		}

		EzEmitVisitor ezEmitVisitor = EzEmitVisitor();
		List<ClassElement> arrStateClassElementAndUp = classDescriptor.getStateClassElementAndUp();
		//classDescriptor.stateClassElement!.visitChildren(ezEmitVisitor);
		for (ClassElement el in arrStateClassElementAndUp) {
			el.visitChildren(ezEmitVisitor);
		}

		EzflapWidgetDescriptor ezflapWidgetDescriptor = EzflapWidgetDescriptor(widgetClassName: classDescriptor.name);
		List<EzEmitData> arr = ezEmitVisitor.getEzAnnotationData();
		for (EzEmitData ezEmitData in arr) {
			ezflapWidgetDescriptor.mapEzEmitFunctionParenthesesParts[ezEmitData.assignedName] = ezEmitData.functionParenthesesPart;
		}

		return ezflapWidgetDescriptor;
	}
}