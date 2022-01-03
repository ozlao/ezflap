
import 'package:analyzer/dart/element/element.dart';

class ParameterDescriptor {
	final String? name;
	final int? idx;
	final bool isRequired;
	final String? defaultValueLiteral;
	final ParameterElement parameterElement;
	final bool isList;
	final bool isNullable;
	final String typeLiteral;

	ParameterDescriptor({
		required this.name,
		required this.idx,
		required this.isRequired,
		required this.defaultValueLiteral,
		required this.parameterElement,
		required this.isList,
		required this.isNullable,
		required this.typeLiteral,
	});

	bool isNamed() {
		return (this.idx == null);
	}

	String getKey() {
		if (this.isNamed()) {
			return this.name!;
		}
		else {
			return this.idx!.toString();
		}
	}
}