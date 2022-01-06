
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/Mixin/GenericFieldVisitorMixin.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

class EzFieldDataBase extends EzAnnotationData {
	late final String assignedName;
	late final String derivedName; // derived from the variable name
	late final String typeWithNullability;
	late final String typeWithoutNullability;
	late final String? defaultValueLiteral;
	late final bool isLate;
	late final bool isNullable;
	late final bool isList;

	@override
	String toString() {
		return "EzFieldDataBase: ${assignedName} (${typeWithNullability})";
	}
}

abstract class FieldElementVisitorBase<T extends EzAnnotationBase, U extends EzFieldDataBase> extends EzAnnotationVisitor<T, U, FieldElement> with GenericFieldVisitorMixin {
	static const String _COMPONENT = "FieldElementVisitorBase";

	U? tryGetEzAnnotationDataByAssignedName(String assignedName) {
		List<U> arr = this.getEzAnnotationData();
		return arr.where((x) => x.assignedName == assignedName).firstOrNull();
	}

	@override
	visitFieldElement(FieldElement element) {
		this.process(element);
	}

	@override
	T? convertFromAnnotation(DartObject objValue, ElementAnnotation elementAnnotation) {
		DartObject? objName = objValue.getField("name");
		String? name = objName?.toStringValue();
		if (name == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "[name] not provided in ElementAnnotation ${elementAnnotation}");
			return null;
		}

		return makeAnnotationClassInstance(name, objValue, elementAnnotation);
	}

	T? makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation);

	List<String> getAssignedNames() {
		List<String> arr = [ ];
		this.forEach((U data) {
			arr.add(data.assignedName);
		});
		return arr;
	}

	List<EzFieldDataBase> getFieldsData() {
		List<EzFieldDataBase> arr = [ ];
		this.forEach((U data) {
			arr.add(data);
		});
		return arr;
	}
}