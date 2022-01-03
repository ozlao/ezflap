
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzMethod/EzMethod.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzMethod/EzMethodVisitor.dart';

class EzMethodGenerator extends AnnotationGeneratorBase<EzMethod, EzMethodData, MethodElement> {
	EzMethodGenerator(ClassElement element, EzAnnotationVisitor<EzMethod, EzMethodData, MethodElement> visitor) : super(element, visitor);

	@override
	String? generateItemForInState(EzMethodData data) {
		return """
			${data.signature};
		""";
	}

	@override
	String? generateItemForInHost(EzMethodData data) {
		String signature = data.signature;
		int posName = signature.indexOf("${data.methodName}(");
		assert(posName != -1);

		int nameLength = data.methodName.length;
		String paramNames = data.arrParamNames.join(", ");
		String processedSignature = signature.substring(0, posName);
		processedSignature += data.name;
		processedSignature += signature.substring(posName + nameLength);
		return """
			${processedSignature} => this._ezState.${data.methodName}(${paramNames});
		""";
	}
}