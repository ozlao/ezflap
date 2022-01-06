
import 'package:analyzer/dart/element/type.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/AST/TypeLiteralAstNodes.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

class SvcTypeLiteralParser extends EzServiceBase {
	static SvcTypeLiteralParser i() { return $Singleton.get(() => SvcTypeLiteralParser()); }

	static const String _COMPONENT = "SvcTypeLiteralParser";

	TypeLiteralAstNodeType parseDartType(DartType type) {
		String typeLiteral = type.getDisplayString(withNullability: true);
		TypeLiteralAstNodeType typeLiteralAstNodeType = this.parseTypeLiteral(typeLiteral);
		return typeLiteralAstNodeType;
	}

	TypeLiteralAstNodeType parseTypeLiteral(String typeLiteral) {
		String normalizedTypeLiteral = typeLiteral.trim();
		bool isNullable = this._isNullable(typeLiteral);
		String withoutNullability = this._removeNullability(normalizedTypeLiteral);
		String name = this._getTypeName(withoutNullability);
		List<TypeLiteralAstNodeType> arrGenericNodes = [ ];

		if (this._hasGenerics(withoutNullability)) {
			arrGenericNodes = this._splitIntoGenerics(withoutNullability);
		}

		return TypeLiteralAstNodeType(name: name, arrGenericNodes: arrGenericNodes, isNullable: isNullable);
	}

	List<TypeLiteralAstNodeType> _splitIntoGenerics(String typeLiteral) {
		String genericsLiteral = this._getGenericsLiteral(typeLiteral);
		List<String> arrParts = this._splitByTopLevelCommas(genericsLiteral).mapToList((x) => x.trim());
		return arrParts.mapToList((x) => this.parseTypeLiteral(x));
	}

	List<String> _splitByTopLevelCommas(String value) {
		int numActiveTriangles = 0;
		String cur = "";
		List<String> arr = [ ];
		for (int i = 0; i < value.length; i++) {
			String ch = value[i];
			if (ch == "<" || ch == ">") {
				if (ch == "<") {
					numActiveTriangles++;
				}
				else if (ch == ">") {
					numActiveTriangles--;
				}

				cur += ch;
				continue;
			}

			if (numActiveTriangles > 0) {
				cur += ch;
				continue;
			}

			if (ch == ",") {
				arr.add(cur);
				cur = "";
				continue;
			}

			cur += ch;
		}

		arr.add(cur);

		return arr;
	}

	String _getGenericsLiteral(String typeLiteral) {
		int from = typeLiteral.indexOf("<");
		int to = typeLiteral.lastIndexOf(">");
		return typeLiteral.substring(from + 1, to).trim();
	}

	bool _hasGenerics(String typeLiteral) {
		return typeLiteral.contains("<");
	}

	String _getTypeName(String typeLiteral) {
		int pos = typeLiteral.indexOf("<");
		if (pos == -1) {
			return typeLiteral;
		}
		return typeLiteral.substring(0, pos);
	}

	bool _isNullable(String typeLiteral) {
		return typeLiteral.endsWith("?");
	}

	String _removeNullability(String typeLiteral) {
		int end = typeLiteral.length;
		if (this._isNullable(typeLiteral)) {
			end--;
		}
		return typeLiteral.substring(0, end);
	}
}