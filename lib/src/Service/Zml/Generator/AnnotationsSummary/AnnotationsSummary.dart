
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzProp/EzPropVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';

class AnnotationsSummary {
	final List<String> arrFieldAssignedNames;
	final Map<String, EzFieldDataBase> mapFieldsData; // by Assigned Name
	final List<String> arrModelAssignedNames;
	final Map<String, EzPropData> mapPropDescriptors;

	AnnotationsSummary({
		required this.arrFieldAssignedNames,
		required this.mapFieldsData,
		required this.arrModelAssignedNames,
		required this.mapPropDescriptors,
	});

	factory AnnotationsSummary.empty() {
		return AnnotationsSummary(
			arrFieldAssignedNames: [ ],
			mapFieldsData: { },
			arrModelAssignedNames: [ ],
			mapPropDescriptors: { },
		);
	}
}