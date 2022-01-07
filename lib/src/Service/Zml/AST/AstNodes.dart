
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';

/// The AST is used to represent Dart code snippets.
/// Obviously it's not a full-blown Dart AST, but rather a simplified version
/// with special additions to combine code snippets from the ZML into the
/// generated program (e.g. the content of "z-if" attributes).
///
/// Consider the following ZML:
///     <Container>
///         <Text>hello world</Text>
///     </Container>
///
/// The generated builder may look like this:
///
/// Widget build(BuildContext context) {
///     return
///         Container(
///             child: Text("hello world")
///         )
///     ;
/// }

abstract class AstNodeBase {

}

class AstNodeWrapper extends AstNodeBase {
	final AstNodeConstructor rootConstructorNode;
	final Map<int, AstNodeZssStyle> mapZssStyleNodes;

	AstNodeWrapper({ required this.rootConstructorNode, required this.mapZssStyleNodes });

	@override
	String toString() {
		return "AstNodeWrapper: rootConstructorNode: ${this.rootConstructorNode}, mapZssStyleNodes: ${this.mapZssStyleNodes}";
	}
}

enum EValueDataNullableSuffix {
	none, // ""
	question, // "?"
	exclamation, // "!"
}

class ValueData { // e.g. "myValue[idx]"
	final String valueLiteral; // the entire value literal. e.g. "myValue[idx1][idx2]"
	final String normalPart; // the value identifier without indexer. e.g. "myValue"
	final String? indexerPartLiteral; // e.g. "[idx1][idx2]"
	final EValueDataNullableSuffix nullableSuffix;

	ValueData({
		required this.valueLiteral,
		required this.normalPart,
		required this.indexerPartLiteral,
		required this.nullableSuffix,
	});

	String getNullableSuffixString() {
		return {
			EValueDataNullableSuffix.none: "",
			EValueDataNullableSuffix.question: "?",
			EValueDataNullableSuffix.exclamation: "!",
		}[this.nullableSuffix]!;
	}

	bool hasSuffix() {
		return (this.nullableSuffix != EValueDataNullableSuffix.none || this.indexerPartLiteral != null);
	}
}

class AstNodeModelValue extends AstNodeBase {
	final String key;
	final String fullValueLiteral;
	final String typeLiteral;

	AstNodeModelValue({
		required this.key,
		required this.fullValueLiteral,
		required this.typeLiteral,
	});
}

class AstNodeConstructorLike extends AstNodeBase {

}

class AstNodeConstructor extends AstNodeConstructorLike {
	final String name;
	final String? customConstructorName;
	final Map<String, AstNodeZssParameterValue> mapNamedParams;
	final List<AstNodeZssParameterValue> arrPositionalParams;
	final Map<String, AstNodeModelValue> mapModels;
	final Map<String, String> mapOns;
	final Map<String?, AstNodeSlotProvider> mapSlotProviders;
	final String? priorityConditionLiteral; // controls whether to even have the loop
	final String? conditionLiteral; // when in z-for - applied to each element separately
	final String? visibilityConditionLiteral;
	final ZFor? zFor;
	final bool isEzflapWidget;
	final bool useInheritingWidget;
	final String? zRef;
	final String? zRefs;
	final String? zRefsKey;
	final String? zBuild;
	final String? zBuilder;
	final String? zKey;
	final String? interpolatedText;
	final bool ezFlapWidgetConstructorAcceptsKeyParameter;

	AstNodeConstructor({
		required this.name,
		required this.customConstructorName,
		required this.mapNamedParams,
		required this.arrPositionalParams,
		required this.mapModels,
		required this.mapOns,
		required this.mapSlotProviders,
		required this.priorityConditionLiteral,
		required this.conditionLiteral,
		required this.visibilityConditionLiteral,
		required this.zFor,
		required this.isEzflapWidget,
		required this.useInheritingWidget,
		required this.zRef,
		required this.zRefs,
		required this.zRefsKey,
		required this.zBuild,
		required this.zBuilder,
		required this.zKey,
		required this.ezFlapWidgetConstructorAcceptsKeyParameter,
		required this.interpolatedText,
	});

	@override
	String toString() {
		String conditionClause = "";
		if (this.conditionLiteral != null) {
			conditionClause = "if (${this.conditionLiteral}): ";
		}
		return "AstNodeConstructor: ${conditionClause}${this.name}";
	}

	bool hasFor() {
		return (this.zFor != null);
	}

	bool isZBuild() {
		return (this.zBuild != null || this.zBuilder != null);
	}
}

class AstNodeSlotProvider extends AstNodeBase {
	final String? name;
	final String? scope;
	final AstNodeConstructorsList childList;

	AstNodeSlotProvider({ required this.name, required this.childList, required this.scope });

	@override
	String toString() {
		return "AstNodeSlotProvider: ${this.name} with scope: ${this.scope} (${this.childList})";
	}
}

class AstNodeSlotConsumer extends AstNodeConstructorLike {
	final String? name;
	final Map<String, AstNodeBase> mapNamedParamNodes; // could be AstNodeLiteral or AstNodeNull
	final Map<String, AstNodeStringWithMustache> mapStringNodes;
	final AstNodeConstructorsList? defaultChildList;

	AstNodeSlotConsumer({
		required this.name,
		required this.mapNamedParamNodes,
		required this.mapStringNodes,
		required this.defaultChildList,
	});

	@override
	String toString() {
		return "AstNodeSlotConsumer: ${this.name} (${this.defaultChildList})";
	}
}

class AstNodeValueBase extends AstNodeBase {
	final String value;

	AstNodeValueBase(this.value);
}

class AstNodeLiteral extends AstNodeValueBase {
	AstNodeLiteral(String value) : super(value);

	@override
	String toString() {
		return "AstNodeLiteral: ${this.value}";
	}
}

class AstNodeNull extends AstNodeBase {
	@override
	String toString() {
		return "AstNodeNull";
	}
}

class AstNodeStringWithMustache extends AstNodeValueBase {
	AstNodeStringWithMustache(String value) : super(value);

	@override
	String toString() {
		return "AstNodeStringWithMustache: ${this.value}";
	}
}

class AstNodeConstructorsList extends AstNodeBase {
	final List<AstNodeConstructorLike> arrConstructorNodes;

	AstNodeConstructorsList(this.arrConstructorNodes);
}

class AstNodeMutuallyExclusiveConstructorsList extends AstNodeBase {
	final List<AstNodeConstructorLike> arrConstructorNodes;
	final bool isNullConstructorAllowed;

	AstNodeMutuallyExclusiveConstructorsList({
		required this.arrConstructorNodes,
		required this.isNullConstructorAllowed,
	});
}

/// e.g. to generate:
///   TextAlign get zssStyle_1 => TextAlign.left;
/// or:
///   Widget get zssStyle_2 => Container(child: Text("hello world"));
class AstNodeZssStyle extends AstNodeBase {
	/// e.g. the "2" in "zssStyle_2"
	final int styleUid;

	/// e.g. the "Container(child: Text("hello world"))"
	final AstNodeBase styleNode;

	/// e.g. the "Widget"
	final AstNodeLiteral typeNode;

	AstNodeZssStyle({
		required this.styleUid,
		required this.styleNode,
		required this.typeNode,
	});

	@override
	String toString() {
		return "AstNodeZssStyle: ${this.typeNode.value} get zssStyle_${this.styleUid} => ${this.styleNode}";
	}
}

class AstNodeZssCondition extends AstNodeBase {
	/// a list of the classes that need to be in actualClassesNode. e.g.:
	///   [ "class2", "class3" ]
	final List<String>? arrExpectedClasses;

	/// the literal from z-bind:attr of the tag referenced from the
	/// ApplicableZssSelectorPart instance for this condition.
	final AstNodeLiteral? actualClassesNode;

	final List<AstNodeZssConditionAttr>? arrZssConditionAttrNodes;

	AstNodeZssCondition({
		required this.arrExpectedClasses,
		required this.actualClassesNode,
		required this.arrZssConditionAttrNodes,
	});

	@override
	String toString() {
		return "AstNodeZssCondition: expected: ${this.arrExpectedClasses?.join(", ")}, actual: ${this.actualClassesNode?.value}, attrs: ${this.arrZssConditionAttrNodes?.length}";
	}
}

class AstNodeZssConditionAttr extends AstNodeBase {
	final String expectedValue;
	final AstNodeLiteral? actualValueLiteralNode;
	final AstNodeStringWithMustache? actualValueStringWithMustacheNode;

	AstNodeZssConditionAttr({
		required this.expectedValue,
		required this.actualValueLiteralNode,
		required this.actualValueStringWithMustacheNode,
	});

	@override
	String toString() {
		return "AstNodeZssConditionAttr: expected: ${this.expectedValue}, actual: ${this.actualValueLiteralNode?.value ?? this.actualValueStringWithMustacheNode?.value ?? 'N/A'}";
	}
}

class AstNodeZssSelector extends AstNodeBase {
	/// each AstNodeZssCondition is based on the application of a selector part
	/// on a respective tag. together, they constitute a full selector.
	final List<AstNodeZssCondition> arrConditionNodes;

	/// if all the conditions evaluate to true (i.e. for all of their respective
	/// tags), then return this style.
	final int zssStyleNodeRef;

	AstNodeZssSelector({ required this.arrConditionNodes, required this.zssStyleNodeRef });

	@override
	String toString() {
		return "AstNodeZssSelector: arrConditionNodes: ${this.arrConditionNodes.length}, zssStyleNodeRef: ${this.zssStyleNodeRef}";
	}

	bool hasConditions() => this.arrConditionNodes.isNotEmpty;
}

class AstNodeZssParameterValue extends AstNodeBase {
	/// - each named parameter of each tag may have a group of selectors applied
	///   to it. this group is represented by arrSelectorNodes.
	/// - this array is sorted by specificity, with the highest-priority
	///   selector being the first.
	/// - arrSelectorNodes can be null if there are no selectors that could
	///   affect the named parameter. this can only happen if there is an
	///   explicit value provided "inline" (because if there isn't, and there
	///   are no selectors, then there won't be a named parameter to begin with).
	List<AstNodeZssSelector>? arrSelectorNodes;

	/// - when arrSelectorNodes is null - this node contains the "inline" value
	///   provided directly in the ZML.
	/// - when arrSelectorNodes is not null - this node contains the default
	///   value of the named parameter, taken from the constructor's declaration.
	final AstNodeBase valueNode;

	final AstNodeLiteral? typeNode;

	AstNodeZssParameterValue({ required this.arrSelectorNodes, required this.valueNode, required this.typeNode });

	factory AstNodeZssParameterValue.simple(AstNodeBase valueNode) {
		return AstNodeZssParameterValue(
			arrSelectorNodes: null,
			valueNode: valueNode,
			typeNode: null,
		);
	}

	factory AstNodeZssParameterValue.simpleWithType(AstNodeBase valueNode, AstNodeLiteral? typeNode) {
		return AstNodeZssParameterValue(
			arrSelectorNodes: null,
			valueNode: valueNode,
			typeNode: typeNode,
		);
	}

	@override
	String toString() {
		return "AstNodeZssParameterValue: arrSelectorNodes: ${this.arrSelectorNodes?.length}, defaultValueNode: ${this.valueNode}";
	}
}
