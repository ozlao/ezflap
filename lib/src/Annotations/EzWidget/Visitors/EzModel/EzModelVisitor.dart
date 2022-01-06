
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzModel/EzModel.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';

class EzModelData extends EzFieldDataBase {
	@override
	String toString() {
		return "EzModelData: ${assignedName} (${typeWithNullability})";
	}
}

class EzModelVisitor extends FieldElementVisitorBase<EzModel, EzModelData> {
	static const String _COMPONENT = "EzModelVisitor";

	@override
	// ignore: avoid_renaming_method_parameters
	EzModelData? makeData(EzModel ezModel, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String type = this.getType(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		if (defaultValueLiteral != null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "@EzModel [${derivedName}] has a default value, but @EzModel models cannot have a default value. The default value will be ignored.");
			defaultValueLiteral = null;
		}

		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		bool isList = this.getIsList(element);

		return EzModelData()
			..assignedName = ezModel.name ?? SvcZmlParser.DEFAULT_MODEL_KEY
			..derivedName = derivedName
			..typeWithNullability = type
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
		;
	}

	@override
	EzModel makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzModel(name);
	}

	@override
	EzModel? convertFromAnnotation(DartObject objValue, ElementAnnotation elementAnnotation) {
		DartObject? objName = objValue.getField("name");
		String? name = objName?.toStringValue();
		return makeAnnotationClassInstance(name, objValue, elementAnnotation);
	}
}