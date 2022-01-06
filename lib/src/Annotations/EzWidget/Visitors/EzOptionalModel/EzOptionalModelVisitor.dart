
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzOptionalModel/EzOptionalModel.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';

class EzOptionalModelData extends EzFieldDataBase {
	@override
	String toString() {
		return "EzOptionalModelData: ${assignedName} (${typeWithNullability})";
	}
}

class EzOptionalModelVisitor extends FieldElementVisitorBase<EzOptionalModel, EzOptionalModelData> {
	@override
	// ignore: avoid_renaming_method_parameters
	EzOptionalModelData? makeData(EzOptionalModel ezModel, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String type = this.getType(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		bool isList = this.getIsList(element);

		return EzOptionalModelData()
			..assignedName = ezModel.name ?? SvcZmlParser.DEFAULT_MODEL_KEY
			..derivedName = derivedName
			..typeWithNullability = type
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
			..isList = isList
		;
	}

	@override
	EzOptionalModel makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzOptionalModel(name);
	}

	@override
	EzOptionalModel? convertFromAnnotation(DartObject objValue, ElementAnnotation elementAnnotation) {
		DartObject? objName = objValue.getField("name");
		String? name = objName?.toStringValue();
		return makeAnnotationClassInstance(name, objValue, elementAnnotation);
	}
}