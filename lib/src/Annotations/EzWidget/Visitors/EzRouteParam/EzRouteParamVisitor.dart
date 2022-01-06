
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzRouteParam/EzRouteParam.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';

class EzRouteParamData extends EzFieldDataBase {
	@override
	String toString() {
		return "EzRouteParamData: ${assignedName} (${typeWithNullability})";
	}
}

class EzRouteParamVisitor extends FieldElementVisitorBase<EzRouteParam, EzRouteParamData> {
	static const String _COMPONENT = "EzRouteParamVisitor";

	@override
	// ignore: avoid_renaming_method_parameters
	EzRouteParamData? makeData(EzRouteParam ezField, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String type = this.getType(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		bool isList = this.getIsList(element);

		return EzRouteParamData()
			..assignedName = ezField.name
			..derivedName = derivedName
			..typeWithNullability = type
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
			..isList = isList
		;
	}

	@override
	EzRouteParam? makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzRouteParam(name!);
	}
}