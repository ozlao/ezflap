
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzField/EzField.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzField/EzFieldVisitor.dart';

class EzFieldGenerator extends AnnotationGeneratorBase<EzField, EzFieldData, FieldElement> {
	EzFieldGenerator(ClassElement element, EzAnnotationVisitor<EzField, EzFieldData, FieldElement> visitor) : super(element, visitor);
	
	@override
	String? generateItemForInState(EzFieldData data) {
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();
		return """
			${protectedSnippet}
			${data.typeWithNullability} get ${ch}${data.derivedName} { return this._buildHost.${data.assignedName}; }
			set ${ch}${data.derivedName}(${data.typeWithNullability} value) { this._buildHost.${data.assignedName} = value; }
		""";
	}
	
	@override
	String? generateItemForInHost(EzFieldData data) {
		String ifNullableBlock = this._makeIfNullableBlock(data);

		return """
			\$RxWrapper<${data.typeWithNullability}> _field_${data.assignedName} = \$RxWrapper();
			${data.typeWithNullability} get ${data.assignedName} {
				${ifNullableBlock}
				return this._field_${data.assignedName}.getValue();
			}
			set ${data.assignedName}(${data.typeWithNullability} value) { this._field_${data.assignedName}.setValue(value); }
		""";
	}

	String _makeIfNullableBlock(EzFieldData data) {
		// prefer to return null over crashing if the model hasn't
		// been initialized. this is important if we use it as a
		// model and want it to be initialized by the sub-widget.
		// in such case we can't assign a default value to it,
		// because it will carry over to the sub-widget and could
		// overwrite their value, which we were planning to have
		// our field initialized with. this may be desirable with
		// non-null fields as well, but we have no clean way of
		// accomplishing this. we could let the user specify a
		// special default value specifically for this case in the
		// annotation, but this entire use-case may be rare enough
		// to be ok to force the user to use a nullable EzField in
		// such case.
		if (!data.isNullable) {
			return "";
		}

		return """
			if (!this._field_${data.assignedName}.wasInit()) {
				return null;
			}
		""";
	}
	
	@override
	String? generateItemForInInitState(EzFieldData data) {
		String? ret;
		
		String ch = this.getUnderscoreIfNotExtended();
		if (data.isNullable && data.defaultValueLiteral == null && !data.isLate) {
			// explicitly set null. this is needed because otherwise the
			// Rx is left uninitialized.
			ret = """
				this.${ch}${data.derivedName} = null;
			""";
		}
		else if (data.defaultValueLiteral != null) {
			ret = """
				this.${ch}${data.derivedName} = ${data.defaultValueLiteral};
			""";
		}
		
		return ret;
	}
}