
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzComputed/EzComputed.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzComputed/EzComputedVisitor.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

class EzComputedGenerator extends AnnotationGeneratorBase<EzComputed, EzComputedData, MethodElement> {
	EzComputedGenerator(ClassElement element, EzAnnotationVisitor<EzComputed, EzComputedData, MethodElement> visitor) : super(element, visitor);

	@override
	String? generateItemForInState(EzComputedData data) {
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();
		return """
			${data.signature};
			late \$ComputedHandler<${data.returnType}> _\$${data.assignedName};
			
			${protectedSnippet}
			${data.returnType} get ${ch}cachedComputed${data.assignedName.ucfirst()} => this._\$${data.assignedName}.getWithCache();
		""";
	}

	@override
	String? generateItemForInInitState(EzComputedData data) {
		return """
			this._\$${data.assignedName} = \$ComputedHandler(funcInvokeUserFunction: () => this.${data.methodName}());
			this.onDispose(() { this._\$${data.assignedName}.dispose(); });
		""";
	}

	@override
	String? generateItemForInHost(EzComputedData data) {
		String ch = this.getUnderscoreIfNotExtended();
		return """
			${data.returnType} get ${data.assignedName} => this._ezState.${ch}cachedComputed${data.assignedName.ucfirst()};
		""";
	}
}