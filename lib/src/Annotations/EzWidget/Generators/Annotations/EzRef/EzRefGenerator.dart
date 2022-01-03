
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzRef/EzRef.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzRef/EzRefVisitor.dart';

class EzRefGenerator extends AnnotationGeneratorBase<EzRef, EzRefData, FieldElement> {
	EzRefGenerator(ClassElement element, EzAnnotationVisitor<EzRef, EzRefData, FieldElement> visitor) : super(element, visitor);
	
	@override
	String? generateItemForInState(EzRefData data) {
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();

		return """
			${protectedSnippet}
			${data.typeWithoutNullability}? get ${ch}${data.derivedName} {
				return this._buildHost.${data.assignedName};
			}
		""";
	}
	
	@override
	String? generateItemForInHost(EzRefData data) {
		return """
			RxWrapper<${data.typeWithoutNullability}?> _ref_${data.assignedName} = RxWrapper.withValue(null);
			${data.typeWithoutNullability}? get ${data.assignedName} {
				return this._ref_${data.assignedName}.getValue();
			}
		""";
	}
}