
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:ezflap/src/Annotations/Common/EzValue/EzValue.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:meta/meta.dart';

class GenericFieldVisitorMixin {
	static const String _COMPONENT = "GenericFieldVisitor";

	@protected
	@nonVirtual
	SvcLogger get svcLogger { return SvcLogger.i(); }

	@nonVirtual
	String getDerivedName(FieldElement element) {
		String name = element.name;
		if (AnnotationUtils.doesStartWithDontTouchPrefix(name)) {
			name = AnnotationUtils.stripDontTouchPrefix(name);
		}
		return name;
	}

	@nonVirtual
	bool doesStartWithDontTouchPrefix(FieldElement element) {
		return AnnotationUtils.doesStartWithDontTouchPrefix(element.name);
	}

	@nonVirtual
	String getType(FieldElement element) {
		return element.type.toString();
	}

	@nonVirtual
	String getTypeWithoutNullability(FieldElement element) {
		return element.type.getDisplayString(withNullability: false);
	}

	@nonVirtual
	String? getDefaultValueLiteral(FieldElement element) {
		int nameOffset = element.nameOffset;
		int nameLength = element.nameLength;

		dynamic elementImpl = element;
		int codeOffset = elementImpl.codeOffset;
		int codeLength = elementImpl.codeLength;
		if (codeOffset + codeLength <= nameOffset + nameLength) {
			// no default type provided
			return null;
		}

		var source = element.source;
		if (source == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "Failed to get source of element: ${element}");
			return null;
		}

		var contents = source.contents;
		String content = contents.data;

		int typeLength = nameOffset - codeOffset;
		String fullDefinition = content.substring(codeOffset, codeOffset + codeLength);
		String defaultValueAssignment = fullDefinition.substring(typeLength + nameLength);
		int pos = defaultValueAssignment.indexOf("=");
		if (pos == -1) {
			this.svcLogger.logErrorFrom(_COMPONENT, "Expected to find an assignment in definition [${fullDefinition}] in element: ${element}");
			return null;
		}

		String defaultValue = defaultValueAssignment.substring(pos + 1).trim();

		return defaultValue;
	}

	@nonVirtual
	bool getIsLate(FieldElement element) {
		return element.isLate;
	}

	@nonVirtual
	bool getIsNullable(FieldElement element) {
		return (element.type.nullabilitySuffix == NullabilitySuffix.question);
	}

	@nonVirtual
	bool getIsList(FieldElement element) {
		return element.type.isDartCoreList;
	}

	@nonVirtual
	bool isMarkedAsEzValue(FieldElement element) {
		return AnnotationUtils.hasAnnotation<EzValue>(element);
	}
}