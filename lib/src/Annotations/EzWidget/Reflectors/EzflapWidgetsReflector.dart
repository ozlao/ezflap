
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWidget.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzEmit/EzEmitVisitor.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
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
		List<ClassElement> arrStateClassElementAndUp = classDescriptor.getStateClassElementAndUp(EzflapWidgetsReflector.tryGetParentClassElementFromEzWidgetExtend);
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

	static ClassElement? tryGetParentClassElementFromEzWidgetExtend(ClassElement el) {
		ElementAnnotation? ann = AnnotationUtils.tryGetAnnotation<EzWidget>(el);
		if (ann == null) {
			return null;
		}

		//Expression? expr = AnnotationUtils.tryGetAnnotationArgumentFromAst(ann, 1);
		Expression? expr = AnnotationUtils.tryGetAnnotationArgumentFromAstByName(ann, EzWidget.EZ_WIDGET__EXTEND);
		if (expr == null) {
			return null;
		}

		if (expr is! NamedExpression) {
			return null;
		}

		Expression innerExpr = expr.expression;
		if (innerExpr is! SimpleIdentifier) {
			return null;
		}

		Element? parentElement = innerExpr.staticElement;
		if (parentElement == null) {
			return null;
		}

		if (parentElement is! ClassElement) {
			return null;
		}

		return parentElement;
	}
}