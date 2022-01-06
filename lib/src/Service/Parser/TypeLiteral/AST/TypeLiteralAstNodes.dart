
abstract class TypeLiteralAstNodeBase {

}

class TypeLiteralAstNodeType extends TypeLiteralAstNodeBase {
	final String name;
	final bool isNullable;
	final List<TypeLiteralAstNodeType> arrGenericNodes;

	TypeLiteralAstNodeType({ required this.name, required this.isNullable, required this.arrGenericNodes });

	String getFullName() {
		String generics = "";
		if (this.hasGenerics()) {
			String s = this.arrGenericNodes.map((x) => x.getFullName()).join(", ");
			generics = "<${s}>";
		}
		String nullChar = (this.isNullable ? "?" : "");
		String s = this.name + generics + nullChar;
		return s;
	}

	@override
	String toString() {
		String fullName = this.getFullName();
		return "TypeLiteralAstNodeType: ${fullName}";
	}

	bool hasGenerics() {
		return (this.arrGenericNodes.isNotEmpty);
	}

	bool isMap() => (this.name == "Map");
	bool isRxMap() => (this.name == "RxMap");
	bool isList() => (this.name == "List");
	bool isRxList() => (this.name == "RxList");
	bool isSet() => (this.name == "Set");
	bool isRxSet() => (this.name == "RxSet");
	bool isString() => (this.name == "String");
	bool isInt() => (this.name == "int");
	bool isDouble() => (this.name == "double");
	bool isBool() => (this.name == "bool");
	bool isNum() => (this.name == "num");
	bool isDynamic() => (this.name == "dynamic");
	bool isMapLike() => (this.isMap() || this.isRxMap());
	bool isListLike() => (this.isList() || this.isRxList());
	bool isSetLike() => (this.isSet() || this.isRxSet());

	bool isRx() {
		return false
			|| this.isRxMap()
			|| this.isRxList()
			|| this.isRxSet()
		;
	}

	bool isCollection() {
		return false
			|| this.isMapLike()
			|| this.isListLike()
			|| this.isSetLike()
		;
	}

	bool isPrimitive() {
		return false
			|| this.isString()
			|| this.isInt()
			|| this.isDouble()
			|| this.isBool()
			|| this.isNum()
		;
	}
}