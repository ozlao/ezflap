
import 'package:ezflap/src/Annotations/EzJson/Utils/EzJsonMixin.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/GenericFieldVisitor.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/AST/TypeLiteralAstNodes.dart';

class GenFromJsonMap with EzJsonMixin {
	final GenericFieldVisitor visitor;

	GenFromJsonMap(this.visitor);
	
	String generate() {
		String blocks = this._makeBlocks();
		return """
			void fromJsonMap(Map<String, dynamic> map) {
				${blocks}
			}
		""";
	}

	String _makeBlocks() {
		List<String> arr = this.visitor.getArrGenericFieldData()
			.map((GenericFieldData data) {
				String valueIdentifier = "map[\"${data.derivedName}\"]";
				TypeLiteralAstNodeType node = data.typeNode;
				String processedValue = this._makeProcessValueCode(valueIdentifier, node);
				String sThis = this.getThisCodeByField(data);

				return """
					${sThis}.${data.derivedName} = ${processedValue};
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
				return "RxList(${valueIdentifier})";
			}
			else if (node.isSet()) {
				return "${valueIdentifier}.toSet()";
			}
			else if (node.isRxSet()) {
				return "RxSet(${valueIdentifier}.toSet())";
			}
			else assert(false);
		}


		String listOrSet = (node.isListLike() ? "List" : "Set");
		TypeLiteralAstNodeType listOrSetValueType = node.arrGenericNodes[0];
		String listOrSetValueTypeName = listOrSetValueType.getFullName();
		String instantiatedListOrSetValue = this._makeProcessValueCode("_value", listOrSetValueType);
		String nullableChar = (node.isNullable ? "?" : "");
		String generatedListOrSet = """
			${valueIdentifier}${nullableChar}.map((_value) => ${instantiatedListOrSetValue}).cast<${listOrSetValueTypeName}>().to${listOrSet}()
		""";

		if (node.isRx()) {
			generatedListOrSet = "Rx${listOrSet}<${listOrSetValueTypeName}>(${generatedListOrSet})";
		}

		return generatedListOrSet;
	}

	String _makeProcessValueAsMapLikeCode(String valueIdentifier, TypeLiteralAstNodeType node) {
		assert(node.isMapLike());

		if (!node.hasGenerics()) {
			if (node.isMap()) {
				// treat the value as a Map and return it directly
				return valueIdentifier;
			}
			else if (node.isRxMap()) {
				return "RxMap(${valueIdentifier})";
			}
			else assert(false);
		}

		assert(node.arrGenericNodes.length == 2);
		TypeLiteralAstNodeType mapKeyType = node.arrGenericNodes[0];
		TypeLiteralAstNodeType mapValueType = node.arrGenericNodes[1];
		String mapKeyTypeFullName = mapKeyType.getFullName();
		String mapValueTypeFullName = mapValueType.getFullName();
		String instantiatedMapValue = this._makeProcessValueCode("_value", mapValueType);
		String nullableChar = (node.isNullable ? "?" : "");
		String generatedMap = """
			${valueIdentifier}${nullableChar}.map((_key, _value) => MapEntry(_key, ${instantiatedMapValue})).cast<String, ${mapValueTypeFullName}>()
		""";

		if (node.isRxMap()) {
			generatedMap = "RxMap<${mapKeyTypeFullName}, ${mapValueTypeFullName}>(${generatedMap})";
		}

		return generatedMap;
	}

	String _makeProcessValueAsEzJsonClassCode(String valueIdentifier, TypeLiteralAstNodeType node) {
		String instantiate = "(${node.name}()..fromJsonMap(${valueIdentifier}))";
		
		if (node.isNullable) {
			return "(${valueIdentifier} == null ? null : ${instantiate})";
		}
		else {
			return instantiate;
		}
	}
}