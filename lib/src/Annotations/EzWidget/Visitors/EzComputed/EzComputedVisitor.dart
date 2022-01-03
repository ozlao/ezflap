
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzComputed/EzComputed.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

class EzComputedData extends EzAnnotationData {
	final String assignedName;
	final String methodName; // derived from the variable name
	final String signature; // e.g. "int _computedAnswer()"
	final String returnType; // e.g. "int"

	EzComputedData({
		required this.assignedName,
		required this.methodName,
		required this.signature,
		required this.returnType,
	});

	@override
	String toString() {
		return "EzComputedData: ${assignedName}: ${signature}";
	}
}

class EzComputedVisitor extends EzAnnotationVisitor<EzComputed, EzComputedData, MethodElement> {
	static const String _COMPONENT = "EzComputedVisitor";

	@override
	visitMethodElement(MethodElement element) {
		this.process(element);
	}
	
	EzComputed? convertFromAnnotation(DartObject objValue, ElementAnnotation elementAnnotation) {
		DartObject? objName = objValue.getField("name");
		String? name = objName?.toStringValue();
		if (name == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "[name] not provided in ElementAnnotation ${elementAnnotation}");
			return null;
		}
		
		return EzComputed(name);
	}
	
	EzComputedData? makeData(EzComputed ezField, MethodElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String methodName = this._getMethodName(element);
		String signature = this._getSignature(element);
		String returnType = this._getReturnType(element);

		return EzComputedData(
			assignedName: ezField.name,
			methodName: methodName,
			signature: signature,
			returnType: returnType,
		);
	}

	String _getMethodName(MethodElement element) {
		String name = element.name;
		return name;
	}

	String _getSignature(MethodElement element) {
		String signature = element.toString();
		return signature;
	}
	
	String _getReturnType(MethodElement element) {
		return element.returnType.toString();
	}
}