
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzRouteParam/EzRouteParam.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzRouteParam/EzRouteParamVisitor.dart';

class EzRouteParamGenerator extends AnnotationGeneratorBase<EzRouteParam, EzRouteParamData, FieldElement> {
	EzRouteParamGenerator(ClassElement element, EzAnnotationVisitor<EzRouteParam, EzRouteParamData, FieldElement> visitor) : super(element, visitor);

	static const String _COMPONENT = "EzRouteParamGenerator";

	@override
	String? generateItemForInState(EzRouteParamData data) {
		String getRouteSnippet = this.makeGetRouteSnippet(data);
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();
		return """
			${protectedSnippet}
			${data.typeWithNullability} get ${ch}${data.derivedName} {
				${getRouteSnippet}
			}
		""";
	}

	@override
	String? generateItemForInHost(EzRouteParamData data) {
		String ch = this.getUnderscoreIfNotExtended();
		return """
			${data.typeWithNullability} get ${data.assignedName} {
				return this._ezState.${ch}${data.derivedName};
			}
		""";
	}

	String makeGetRouteSnippet(EzRouteParamData data) {
		if (data.defaultValueLiteral == null) {
			return """
				return this.\$getRouteParam<${data.typeWithNullability}>("${data.assignedName}");
			""";
		}
		else {
			return """
				return this.\$tryGetRouteParam<${data.typeWithNullability}>("${data.assignedName}", ${data.defaultValueLiteral});
			""";
		}
	}
}