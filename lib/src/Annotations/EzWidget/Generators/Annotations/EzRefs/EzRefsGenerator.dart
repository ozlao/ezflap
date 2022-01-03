
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzRefs/EzRefs.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzRefs/EzRefsVisitor.dart';

class EzRefsGenerator extends AnnotationGeneratorBase<EzRefs, EzRefsData, FieldElement> {
	EzRefsGenerator(ClassElement element, EzAnnotationVisitor<EzRefs, EzRefsData, FieldElement> visitor) : super(element, visitor);
	
	@override
	String? generateItemForInState(EzRefsData data) {
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();

		return """
			${protectedSnippet}
			Map<${data.keyType}, ${data.valueType}> get ${ch}${data.derivedName} {
				return this._buildHost.${data.assignedName}.map((key, value) => MapEntry(key, value));
			}
		""";
	}
	
	@override
	String? generateItemForInHost(EzRefsData data) {
		return """
			RxMap<${data.keyType}, ${data.valueType}> _refs_${data.assignedName} = RxMap<${data.keyType}, ${data.valueType}>();
			RxMap<${data.keyType}, ${data.valueType}> get ${data.assignedName} {
				return this._refs_${data.assignedName};
			}
		""";
	}
}