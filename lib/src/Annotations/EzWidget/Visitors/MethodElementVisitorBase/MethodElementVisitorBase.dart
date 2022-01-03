
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:meta/meta.dart';

class EzMethodDataBase extends EzAnnotationData {
	late final String name;
	late final String methodName; // derived from the variable name
	late final String signature; // e.g. "void _boundOpenItem(int itemId)"
	late final List<String> arrParamNames;

	@override
	String toString() {
		return "EzMethodDataBase: ${name}: ${signature}";
	}
}

abstract class MethodElementVisitorBase<T extends EzAnnotationBase, U extends EzMethodDataBase> extends EzAnnotationVisitor<T, U, MethodElement> {
	static const String _COMPONENT = "MethodElementVisitorBase";

	@override
	visitMethodElement(MethodElement element) {
		this.process(element);
	}

	T? convertFromAnnotation(DartObject objValue, ElementAnnotation elementAnnotation) {
		DartObject? objName = objValue.getField("name");
		String? name = objName?.toStringValue();
		if (name == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "[name] not provided in ElementAnnotation ${elementAnnotation}");
			return null;
		}

		return makeAnnotationClassInstance(name, objValue, elementAnnotation);
	}

	T? makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation);

	@protected
	@nonVirtual
	String getMethodName(MethodElement element) {
		String name = element.name;
		return name;
	}

	@protected
	@nonVirtual
	List<String> getParamNames(MethodElement element) {
		return element.parameters.map((x) => x.name).toList(growable: false);
	}

	@protected
	@nonVirtual
	String getSignature(MethodElement element) {
		String signature = 	element.toString();
		return signature;
	}

	@protected
	@nonVirtual
	String getDerivedName(MethodElement element) {
		String name = AnnotationUtils.stripDontTouchPrefix(element.name);
		return name;
	}

	@protected
	@nonVirtual
	String getType(MethodElement element) {
		return element.type.toString();
	}

	@protected
	@nonVirtual
	String getTypeWithoutNullability(MethodElement element) {
		return element.type.getDisplayString(withNullability: false);
	}

	@protected
	@nonVirtual
	bool getIsNullable(MethodElement element) {
		return (element.type.nullabilitySuffix == NullabilitySuffix.question);
	}
}