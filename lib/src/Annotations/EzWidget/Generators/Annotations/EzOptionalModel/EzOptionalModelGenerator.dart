
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzOptionalModel/EzOptionalModel.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzOptionalModel/EzOptionalModelVisitor.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

class EzOptionalModelGenerator extends AnnotationGeneratorBase<EzOptionalModel, EzOptionalModelData, FieldElement> {
	EzOptionalModelGenerator(ClassElement element, EzAnnotationVisitor<EzOptionalModel, EzOptionalModelData, FieldElement> visitor) : super(element, visitor);

	@override
	String? generateItemForInState(EzOptionalModelData data) {
		String capitalizedAssignedName = data.assignedName.ucfirst();
		String escapedAssignedName = this._getEscapedAssignedName(data);
		String modelHandlerGetter = this._makeModelHandlerGetter(data);
		String modelValueGetter = this._makeModelValueGetter(data);
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();

		return """
			${protectedSnippet}
			bool ${ch}has${capitalizedAssignedName}() => this.\$hasModelHandler("${escapedAssignedName}");

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
				this.\$getModelHandler<${data.typeWithNullability}>("${escapedAssignedName}", true).setModelValue(value);
			}
		""";
	}

	@override
	String? generateItemForInInitState(EzOptionalModelData data) {
		String ch = this.getUnderscoreIfNotExtended();
		String defaultValueLiteral = data.defaultValueLiteral ?? "null";
		String escapedAssignedName = this._getEscapedAssignedName(data);
		return """
			if (!this.\$hasModelHandler("${escapedAssignedName}")) {
				this.${ch}${data.derivedName} = ${defaultValueLiteral};
			}
		""";
	}

	@override
	String? generateItemForInHost(EzOptionalModelData data) {
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

	String _makeModelValueGetter(EzOptionalModelData data) {
		String modelHandlerGetter = this._makeModelHandlerGetter(data);
		return "${modelHandlerGetter}.getModelValue()";
	}

	String _makeModelHandlerGetter(EzOptionalModelData data) {
		String escapedAssignedName = this._getEscapedAssignedName(data);
		return """
			this.\$getModelHandler<${data.typeWithNullability}>("${escapedAssignedName}", true)
		""";
	}

	String _getEscapedAssignedName(EzOptionalModelData data) {
		return data.assignedName.replaceAll("\$", "\\\$");
	}
}