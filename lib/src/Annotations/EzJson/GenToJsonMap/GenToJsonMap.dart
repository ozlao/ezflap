
import 'package:ezflap/src/Annotations/EzJson/Utils/EzJsonMixin.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/GenericFieldVisitor.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/AST/TypeLiteralAstNodes.dart';

class GenToJsonMap with EzJsonMixin {
	final GenericFieldVisitor visitor;

	GenToJsonMap(this.visitor);
	
	String generate() {
		String blocks = this._makeBlocks();
		return """
			Map<String, dynamic> toJsonMap() {
				Map<String, dynamic> map = { };
				${blocks}
				return map;
			}
		""";
	}

	String _makeBlocks() {
		List<String> arr = this.visitor.getArrGenericFieldData()
			.map((GenericFieldData data) {
				String sThis = this.getThisCodeByField(data);
				String valueIdentifier = "${sThis}.${data.derivedName}";
				TypeLiteralAstNodeType node = data.typeNode;
				String processedValue = this._makeProcessValueCode(valueIdentifier, node);
				return """
					map[\"${data.derivedName}\"] = ${processedValue};
				""";
			})
			.toList()
		;

		return arr.join("\n");
	}

	/// [valueIdentifier] is the identifier of the JSON map, indexed to the
	/// value that should be processed for the receiving target, whose type is
	/// provided in [node].
	String _makeProcessValueCode(String valueIdentifier, TypeLiteralAstNodeType node) {
		if (node.isPrimitive() || node.isDynamic()) {
			return valueIdentifier;
		}
		
		if (node.isListLike() || node.isSetLike()) {
			return this._makeProcessValueAsListOrSetLikeCode(valueIdentifier, node);
		}
		else if (node.isMapLike()) {
			return this._makeProcessValueAsMapLikeCode(valueIdentifier, node);
		}
		
		// all that is left is another EzJson class
		assert(!node.hasGenerics());
		
		return this._makeProcessValueAsEzJsonClassCode(valueIdentifier, node);
	}

	String _makeProcessValueAsListOrSetLikeCode(String valueIdentifier, TypeLiteralAstNodeType node) {
		assert(node.isListLike() || node.isSetLike());

		if (!node.hasGenerics()) {
			if (node.isList()) {
				// treat the value as a List and return it directly
				return valueIdentifier;
			}
			else if (node.isRxList()) {
				// treat the value as a List and return it directly
				return valueIdentifier;
				// return "${valueIdentifier}.value";
			}
			else if (node.isSet()) {
				return "${valueIdentifier}.toList()";
			}
			else if (node.isRxSet()) {
				//return "${valueIdentifier}.value.toList()";
				// treat the value as a List and return it directly
				return "${valueIdentifier}.toList()";
			}
			else assert(false);
		}


		TypeLiteralAstNodeType listOrSetValueType = node.arrGenericNodes[0];
		String instantiatedListOrSetValue = this._makeProcessValueCode("_value", listOrSetValueType);
		String effectiveValueIdentifier = valueIdentifier;
		String nullableChar = (node.isNullable ? "?" : "");
		if (node.isRx()) {
			effectiveValueIdentifier = "${valueIdentifier}${nullableChar}.value";
			nullableChar = (listOrSetValueType.isNullable ? "?" : "");
		}

		String generatedList = """
			${effectiveValueIdentifier}${nullableChar}.map((_value) => ${instantiatedListOrSetValue}).toList()
		""";

		return generatedList;
	}

	String _makeProcessValueAsMapLikeCode(String valueIdentifier, TypeLiteralAstNodeType node) {
		assert(node.isMapLike());

		if (!node.hasGenerics()) {
			if (node.isMap()) {
				// treat the value as a Map and return it directly
				return valueIdentifier;
			}
			else if (node.isRxMap()) {
				//return "${valueIdentifier}.value";
				// treat the value as a Map and return it directly
				return valueIdentifier;
			}
			else assert(false);
		}

		assert(node.arrGenericNodes.length == 2);
		TypeLiteralAstNodeType mapKeyType = node.arrGenericNodes[0];
		TypeLiteralAstNodeType mapValueType = node.arrGenericNodes[1];
		String instantiatedMapValue = this._makeProcessValueCode("_value", mapValueType);
		String effectiveValueIdentifier = valueIdentifier;
		String nullableChar = (node.isNullable ? "?" : "");
		if (node.isRx()) {
			//effectiveValueIdentifier = "${valueIdentifier}${nullableChar}.value";
			effectiveValueIdentifier = "${valueIdentifier}";
			nullableChar = (mapValueType.isNullable ? "?" : "");
		}
		String generatedMap = """
			${effectiveValueIdentifier}${nullableChar}.map((_key, _value) => MapEntry(_key, ${instantiatedMapValue}))
		""";

		return generatedMap;
	}

	String _makeProcessValueAsEzJsonClassCode(String valueIdentifier, TypeLiteralAstNodeType node) {
		if (node.isNullable) {
			return "${valueIdentifier}?.toJsonMap()";
		}
		else {
			return "${valueIdentifier}.toJsonMap()";
		}
	}
}