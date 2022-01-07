
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzModel/EzModel.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzModel/EzModelVisitor.dart';

class EzModelGenerator extends AnnotationGeneratorBase<EzModel, EzModelData, FieldElement> {
	EzModelGenerator(ClassElement element, EzAnnotationVisitor<EzModel, EzModelData, FieldElement> visitor) : super(element, visitor);

	@override
	String? generateItemForInState(EzModelData data) {
		String escapedAssignedName = this._getEscapedAssignedName(data);
		String modelHandlerGetter = this._makeModelHandlerGetter(data);
		String modelValueGetter = this._makeModelValueGetter(data);
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();

		return """
			${protectedSnippet}
			bool ${ch}${data.derivedName}_isProvided() => this.\$hasModelHandler("${escapedAssignedName}");

			${protectedSnippet}
			${data.typeWithNullability} get ${ch}${data.derivedName} {
				return ${modelValueGetter};
			}

			${protectedSnippet}
			bool ${ch}${data.derivedName}_isOfType<U>() {
				return (${modelHandlerGetter} is \$ModelHandler<U>);
			}

			${protectedSnippet}
			set ${ch}${data.derivedName}(${data.typeWithNullability} value) {
				this.\$getModelHandler<${data.typeWithNullability}>("${escapedAssignedName}", false).setModelValue(value);
			}
		""";
	}

	@override
	String? generateItemForInHost(EzModelData data) {
		String ch = this.getUnderscoreIfNotExtended();

		return """
			${data.typeWithNullability} get ${data.assignedName} {
				return this._ezState.${ch}${data.derivedName};
			}

			set ${data.assignedName}(${data.typeWithNullability} value) {
				this._ezState.${ch}${data.derivedName} = value;
			}
		""";
	}

	String _makeModelValueGetter(EzModelData data) {
		String modelHandlerGetter = this._makeModelHandlerGetter(data);
		return "${modelHandlerGetter}.getModelValue()";
	}

	String _makeModelHandlerGetter(EzModelData data) {
		String escapedAssignedName = this._getEscapedAssignedName(data);
		return """
			this.\$getModelHandler<${data.typeWithNullability}>("${escapedAssignedName}", false)
		""";
	}

	String _getEscapedAssignedName(EzModelData data) {
		return data.assignedName.replaceAll("\$", "\\\$");
	}
}