
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:ezflap/src/Service/Zss/Matcher/ParameterApplicableZss/ParameterApplicableZss.dart';

class ZFor {
	final String iterValue;
	final String? iterKeyOrIdx;
	final String? iterKey; // used only with Maps when the z-for expression has three parameters (this is the second parameter)
	final String collectionExpr;

	ZFor({
		required this.iterValue,
		required this.iterKeyOrIdx,
		required this.iterKey,
		required this.collectionExpr,
	});
}


/// Represents an ZML tag.
/// Map directly to widget ZML tags.
class Tag {
	static const _TAG_Z_INHERITING_WIDGET = "ZInheritingWidget";
	static const _TAG_Z_SLOT_PROVIDER = "ZSlotProvider";
	static const _TAG_Z_SLOT_CONSUMER = "ZSlotConsumer";
	static const TAG_Z_BUILD = "ZBuild";
	static const TAG_Z_GROUP = "ZGroup";
	// static const CHILD_TAG_POSITIONAL_PARAMETER_PREFIX = ":";

	Tag? parent;

	/// e.g. "Container" in "<Container padding="edgeInsets.all(10)">"
	final String name;
	final bool isNamedChildTag;

	String? zCustomConstructorName;
	String? stringAttrClass;
	String? attrClass;
	String? zIf;
	String? zShow;
	ZFor? zFor;
	String? zRef;
	String? zRefs;
	String? zRefsKey;
	String? zBuild;
	String? zBuilder;
	String? zName;

	/// used with <ZSlotProvider> to designate the name of the scope (that is
	/// passed from the consumer)
	String? zScope;

	String text = "";
	String textWithoutXmlComments = "";

	// used with tags for ezFlap Widgets
	String? interpolatedText;

	final Map<String, String> mapStrings = { }; // unprefixed attributes whose values should be processed as string, e.g. 'title="hello world"'. supports mustache.
	final Map<String, String> mapZBinds = { }; // expressions that need to be evaluated, e.g. 'z-bind:color="localColor"'
	final Map<String, String> mapZOns = { };
	final Map<String, String> mapZModels = { };
	final Map<String, String> mapZAttrs = { }; // for custom attributes, for ZSS, e.g. 'z-attr:status="myStatus"'

	final List<Tag> arrUnnamedChildren = [ ];

	// named children are stored with their keys being the tag names, after
	// having the "-" suffix stripped. in the case of positional parameters,
	// the ":" prefix is NOT stripped (i.e. the parsing doesn't distinguish
	// between children tags that represent named and positional parameters;
	// this is to improve consistency, because actually z-binds and z-attrs
	// can also refer to either named or positional parameters. anyway we may
	// change this in the future and re-align the responsibilities of the
	// different services and classes that participate in the pipeline.
	final Map<String, Tag> mapNamedChildren = { };

	// this is used to apply ZSS. SvcZssParser is responsible for parsing the ZSS
	// XML. SvcZssMatcher is responsible for matching ZSS rules to post-transformation
	// Tags:
	// - the rules are matched by specificity (rules with higher specificity
	//   override rules with lower).
	// - overriding of rules is done per-style (i.e. at the ZSS' named child
	//   tags' scope).
	// - we collect all potentially-affected named parameters of this tag in
	//   this map, and use the named parameter's name as key.
	// - for each named parameter, we keep a list with one item per each ZSS
	//   rule that can be applied to the current tag and has the named style
	//   the current map entry is for.
	// - this list is ordered by specificity, with the highest specificity at
	//   the top.
	// - each item in this list represents a Rule, and contains a list of
	//   SelectorParts.
	// - alongside each SelectorPart, there is a reference to the Tag to which
	//   the SelectorPart applies (this is safe because the ZSS is applied to
	//   Tags AFTER transformation, so the Tag instances are stable.
	// - in addition to the list of SelectorParts, the item also contains a
	//   reference to the root tag of the named parameter in the style provided
	//   by the ZSS.
	// - this tags tree with the tags for the ZSS style is also already transformed.
	// - for named params, the key is the param name.
	// - for positional params, the key is the position index number (e.g. "2")
	final Map<String, ParameterApplicableZss> mapZssToParams = { };

	Tag({
		required this.parent,
		required this.name,
		required this.isNamedChildTag,
	});

	void addText(String text, { required bool isComment }) {
		this.text += text;
		if (!isComment) {
			this.textWithoutXmlComments += text;
		}
	}

	void setText(String text, String textWithoutXmlComments) {
		this.text = text;
		this.textWithoutXmlComments = textWithoutXmlComments;
	}

	void addChildTag(Tag tag) {
		if (tag.isNamedChildTag) {
			String name = tag.name;
			this.mapNamedChildren[name] = tag;
		}
		else {
			this.arrUnnamedChildren.add(tag);
		}
	}

	void clearText() {
		this.text = "";
		this.textWithoutXmlComments = "";
	}

	@override
	String toString() {
		return "<${name}>";
	}

	bool hasNamedParameter(String name) {
		return false
			|| this.mapNamedChildren.containsKey(name)
			|| this.mapStrings.containsKey(name)
			|| this.mapZBinds.containsKey(name)
			|| this.mapZAttrs.containsKey(name)
		;
	}

	bool hasAnyParameter() {
		return false
			|| this.mapNamedChildren.isNotEmpty
			|| this.mapStrings.isNotEmpty
			|| this.mapZBinds.isNotEmpty
			|| this.mapZAttrs.isNotEmpty
		;
	}

	bool doBindsOrStringsContainKey(String key) {
		return (this.mapZBinds.containsKey(key) || this.mapStrings.containsKey(key));
	}

	bool isTypeInheritingWidget() { return (this.name == Tag._TAG_Z_INHERITING_WIDGET); }
	bool isTypeSlotProvider() { return (this.name == Tag._TAG_Z_SLOT_PROVIDER); }
	bool isTypeSlotConsumer() { return (this.name == Tag._TAG_Z_SLOT_CONSUMER); }
	bool isTypeBuild() { return (this.name == Tag.TAG_Z_BUILD); }
	bool isTypeGroup() { return (this.name == Tag.TAG_Z_GROUP); }

	bool isTypeSpecialKeywordTag() {
		return false
			|| this.isTypeInheritingWidget()
			|| this.isTypeSlotProvider()
			|| this.isTypeSlotConsumer()
			|| this.isTypeBuild()
			|| this.isTypeGroup()
		;
	}

	List<Tag> collectDescendantsAndSelf() {
		List<Tag> arr = [ ];
		this._internalCollectDescendantsAndSelf(arr);
		return arr;
	}

	void _internalCollectDescendantsAndSelf(List<Tag> arrCollectedTags) {
		this.arrUnnamedChildren.forEach((x) => x._internalCollectDescendantsAndSelf(arrCollectedTags));
		this.mapNamedChildren.values.forEach((x) => x._internalCollectDescendantsAndSelf(arrCollectedTags));
		arrCollectedTags.add(this);
	}
}
