
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzProp/EzProp.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzProp/EzPropVisitor.dart';

class EzPropGenerator extends AnnotationGeneratorBase<EzProp, EzPropData, FieldElement> {
	EzPropGenerator(ClassElement element, EzAnnotationVisitor<EzProp, EzPropData, FieldElement> visitor) : super(element, visitor);

	@override
	String? generateItemForInRefreshProps(EzPropData data) {
		String rxProp = this._makeRxPropName(data);
		String updateRxProp = this._makeUpdateRxProp(data);
		return """
			if (this.${rxProp}.wasInit()) {
				${updateRxProp}
			}
		""";
	}

	@override
	String? generateItemForInState(EzPropData data) {
		String rxProp = this._makeRxPropName(data);
		String updateRxProp = this._makeUpdateRxProp(data);
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();
		return """
			\$RxWrapper<${data.typeWithNullability}> ${rxProp} = \$RxWrapper();
			${protectedSnippet}
			${data.typeWithNullability} get ${ch}${data.derivedName} {
				if (!this.${rxProp}.wasInit()) {
					${updateRxProp}
				}
				return this.${rxProp}.getValue();
			}
		""";
	}

	@override
	String? generateItemForInHost(EzPropData data) {
		String ch = this.getUnderscoreIfNotExtended();
		return """
			${data.typeWithNullability} get ${data.assignedName} { return this._ezState.${ch}${data.derivedName}; }
		""";
	}

	String _makeRxPropName(EzPropData data) {
		return "_\$rxProp_${data.assignedName}";
	}

	String _makeUpdateRxProp(EzPropData data) {
		String sDefaultValue = (data.defaultValueLiteral == null ? "" : ", ${data.defaultValueLiteral}");
		String rxProp = this._makeRxPropName(data);
		return """this.${rxProp}.setValue(this.widget.\$getProp("${data.assignedName}"${sDefaultValue}));""";
	}
}