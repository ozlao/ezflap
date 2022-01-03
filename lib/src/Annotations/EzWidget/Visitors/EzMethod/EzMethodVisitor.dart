
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzMethod/EzMethod.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/MethodElementVisitorBase/MethodElementVisitorBase.dart';

class EzMethodData extends EzMethodDataBase {
	@override
	String toString() {
		return "EzMethodData: ${name}: ${signature}";
	}
}

class EzMethodVisitor extends MethodElementVisitorBase<EzMethod, EzMethodData> {
	static const String _COMPONENT = "EzMethodVisitor";

	EzMethodData? makeData(EzMethod ezField, MethodElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String methodName = this.getMethodName(element);
		String signature = this.getSignature(element);
		List<String> arrParamNames = this.getParamNames(element);

		return EzMethodData()
			..name = ezField.name
			..methodName = methodName
			..signature = signature
			..arrParamNames = arrParamNames
		;
	}

	@override
	EzMethod? makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzMethod(name!);
	}
}