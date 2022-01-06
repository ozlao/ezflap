
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:ezflap/src/Utils/EzError/EzError.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';
import 'package:xml/xml.dart';

class SvcZmlParser extends EzServiceBase {
	static SvcZmlParser i() { return $Singleton.get(() => SvcZmlParser()); }

	SvcLogger get _svcLogger => SvcLogger.i();

	static const String _COMPONENT = "SvcZmlParser";

	static const String DEFAULT_MODEL_KEY = "model"; // "model" can be referenced from ZML
	
	static const _STRING_ATTR_CLASS = "class";

	static const _COMMENT_OUT_PREFIX = "_";
	static const _NAMED_CHILD_POSTFIX = "-";
	static const CHILD_TAG_POSITIONAL_PARAMETER_PREFIX = ":";

	static const _Z_CONSTRUCTOR_ATTR_NAME = "z-constructor";
	static const _Z_KEY_ATTR_NAME = "z-key";
	static const _Z_IF_ATTR_NAME = "z-if";
	static const _Z_SHOW_ATTR_NAME = "z-show";
	static const _Z_FOR_ATTR_NAME = "z-for";
	static const _Z_BIND_PREFIX = "z-bind";
	static const _Z_ON_PREFIX = "z-on";
	static const _Z_MODEL_PREFIX = "z-model";
	static const _Z_MODEL_ATTR_NAME = "z-model";
	static const _Z_MODEL_TYPE_LITERAL_ATTR_NAME = "z-model-type-literal";
	static const _Z_ATTR_PREFIX = "z-attr";
	static const _Z_REF_ATTR_NAME = "z-ref";
	static const _Z_REFS_ATTR_NAME = "z-refs";
	static const _Z_REFS_KEY_ATTR_NAME = "z-refs-key";
	static const _Z_BUILD_ATTR_NAME = "z-build";
	static const _Z_BUILDER_ATTR_NAME = "z-builder";
	static const _Z_NAME_ATTR_NAME = "z-name";
	static const _Z_SCOPE_ATTR_NAME = "z-scope"; // see Tag.zScope


	Tag? tryParse(String zml) {
		XmlDocument xDoc = XmlDocument.parse(zml);
		return this.makeTag(xDoc.rootElement, null);
	}

	bool isTagCommentedOut(XmlElement xElement) {
		String name = xElement.name.local;
		return name.startsWith(_COMMENT_OUT_PREFIX);
	}

	Tag? makeTag(XmlElement xElement, Tag? parentTag) {
		if (this.isTagCommentedOut(xElement)) {
			return null;
		}
		
		String name = xElement.name.local;
		bool isNamedChildTag = false;
		if (name.endsWith(_NAMED_CHILD_POSTFIX)) {
			isNamedChildTag = true;
			
			name = name.substring(0, name.length - 1);
			if (name.isEmpty) {
				this._svcLogger.logError(EzError(_COMPONENT, "The tag '<->' is not supported."));
				return null;
			}
		}

		Tag tag = Tag(
			parent: parentTag,
			name: name,
			isNamedChildTag: isNamedChildTag,
		);

		this._populateTag(tag, xElement);
		this._sanityCheckTag(tag);
		
		return tag;
	}

	void _populateTag(Tag tag, XmlElement xElement) {
		this._populateAttributes(tag, xElement);
		this._populateChildren(tag, xElement);
		this._populateText(tag, xElement);
	}
	
	void _populateChildren(Tag tag, XmlElement xElement) {
		for (XmlNode xNode in xElement.children) {
			Tag? childTag;
			if (xNode is XmlElement) {
				if (this._isBr(xNode)) {
					// special case. this is actually considered to be text. skip here.
					continue;
				}

				childTag = this.makeTag(xNode, tag);
			}
			if (childTag != null) {
				tag.addChildTag(childTag);
			}
		}
	}

	bool _isBr(XmlElement xElement) {
		return (xElement.name.local == "br");
	}
	
	void _populateText(Tag tag, XmlElement xElement) {
		List<String> arrAll = [ ];
		List<String> arrAllExceptComments = [ ];
		for (XmlNode xNode in xElement.children) {
			String nodeText = "";
			if (xNode is XmlText || xNode is XmlComment) {
				nodeText = xNode.text;

				if (xNode is XmlComment) {
					nodeText = "<!--${nodeText}-->";
					arrAll.add(nodeText);
					continue;
				}
			}

			if (xNode is XmlElement && this._isBr(xNode)) {
				nodeText = "<br/>";
			}

			arrAll.add(nodeText);
			arrAllExceptComments.add(nodeText);
		}

		String allText = arrAll.join("").trim();
		String allTextExceptComments = arrAllExceptComments.join("").trim();
		tag.setText(allText, allTextExceptComments);
	}
	
	void _populateAttributes(Tag tag, XmlElement xElement) {
		for (XmlAttribute xAttr in xElement.attributes) {
			if (xAttr.name.local.startsWith(_COMMENT_OUT_PREFIX)) {
				continue;
			}
				
			false
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_CONSTRUCTOR_ATTR_NAME, (value) => tag.zCustomConstructorName = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_KEY_ATTR_NAME, (value) => tag.zKey = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _STRING_ATTR_CLASS, (value) => tag.stringAttrClass = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_IF_ATTR_NAME, (value) => tag.zIf = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_SHOW_ATTR_NAME, (value) => tag.zShow = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_REF_ATTR_NAME, (value) => tag.zRef = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_REFS_ATTR_NAME, (value) => tag.zRefs = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_REFS_KEY_ATTR_NAME, (value) => tag.zRefsKey = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_BUILD_ATTR_NAME, (value) => tag.zBuild = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_BUILDER_ATTR_NAME, (value) => tag.zBuilder = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_NAME_ATTR_NAME, (value) => tag.zName = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_SCOPE_ATTR_NAME, (value) => tag.zScope = value)
			|| this._tryPopulateAttributeExplicit(xAttr, _Z_MODEL_TYPE_LITERAL_ATTR_NAME, (value) => tag.zModelTypeLiteral = value)
			|| this._tryPopulateAttributeZBind(tag, xAttr)
			|| this._tryPopulateAttributeZFor(tag, xAttr)
			|| this._tryPopulateAttributeZOn(tag, xAttr)
			|| this._tryPopulateAttributeZModel(tag, xAttr)
			|| this._tryPopulateAttributeZAttrClass(tag, xAttr)
			|| this._tryPopulateAttributeZAttr(tag, xAttr)
			|| this._tryPopulateAttributeLiteral(tag, xAttr)
			;
		}
	}
	
	bool _tryPopulateAttributeExplicit(XmlAttribute xAttr, String expectedAttrName, void Function(String value) callback) {
		if (xAttr.name.prefix == null && xAttr.name.local == expectedAttrName) {
			callback(xAttr.value);
			return true;
		}
		return false;
	}
	
	bool _tryPopulateAttributeZFor(Tag tag, XmlAttribute xAttr) {
		if (xAttr.name.prefix == null && xAttr.name.local == _Z_FOR_ATTR_NAME) {
			ZFor? zFor = this._tryParseZFor(xAttr.value, tag);
			tag.zFor = zFor;
			return true;
		}
		return false;
	}
	
	bool _tryPopulateAttributeZAttrClass(Tag tag, XmlAttribute xAttr) {
		if (xAttr.name.prefix == _Z_ATTR_PREFIX) {
			if (xAttr.name.local == _STRING_ATTR_CLASS) {
			    tag.attrClass = xAttr.value;
				return true;
			}
		}
		return false;
	}

	bool _tryPopulateAttributeZBind(Tag tag, XmlAttribute xAttr) {
		if (xAttr.name.prefix == _Z_BIND_PREFIX) {
			tag.mapZBinds[xAttr.name.local] = xAttr.value;
			return true;
		}
		return false;
	}

	bool _tryPopulateAttributeZOn(Tag tag, XmlAttribute xAttr) {
		if (xAttr.name.prefix == _Z_ON_PREFIX) {
			tag.mapZOns[xAttr.name.local] = xAttr.value;
			return true;
		}
		return false;
	}
	
	bool _tryPopulateAttributeZModel(Tag tag, XmlAttribute xAttr) {
		String modelKey;
		if (xAttr.name.prefix == _Z_MODEL_PREFIX) {
			modelKey = xAttr.name.local;
		}
		else if (xAttr.name.prefix == null && xAttr.name.local == _Z_MODEL_ATTR_NAME) {
			modelKey = DEFAULT_MODEL_KEY;
		}
		else {
			return false;
		}
		
		tag.mapZModels[modelKey] = xAttr.value;
		return true;
	}

	bool _tryPopulateAttributeZAttr(Tag tag, XmlAttribute xAttr) {
		if (xAttr.name.prefix == _Z_ATTR_PREFIX) {
			tag.mapZAttrs[xAttr.name.local] = xAttr.value;
			return true;
		}
		return false;
	}
	
	bool _tryPopulateAttributeLiteral(Tag tag, XmlAttribute xAttr) {
		if (xAttr.name.prefix == null) {
			tag.mapStrings[xAttr.name.local] = xAttr.value;
			return true;
		}
		return false;
	}

	ZFor? _tryParseZFor(String zForExpr, Tag tag) {
		String? keyOrIdxIter;
		String? keyIter;
		String valueIter;
		String collectionExpr;

		const IN_LITERAL = " in ";
		RegExp regexpIdentifier = RegExp(r"^[a-zA-Z0-9_]+$", multiLine: false);

		while (true) {
			int posIn = zForExpr.indexOf(IN_LITERAL);
			if (posIn == -1) {
				break;
			}

			String leftSide = zForExpr.substring(0, posIn).trim();
			if (leftSide.length > 5 && leftSide.startsWith("(") && leftSide.endsWith(")")) {
				// syntax 2: "(value, key) in collection"
				// OR
				// syntax 3: "(value, key, idx) in collection"
				List<String> arr = leftSide.substring(1, leftSide.length - 1).splitAndTrim(",") ?? [ ];
				if (arr.length != 2 && arr.length != 3) {
					break;
				}

				valueIter = arr[0].trim();
				if (arr.length == 2) {
					// syntax 2: "(key, value) in collection"
					keyOrIdxIter = arr[1].trim();
				}
				else { // arr.length == 3
					// syntax 3: "(idx, key, value) in collection"
					keyIter = arr[1].trim();
					keyOrIdxIter = arr[2].trim();
				}

				for (String iter in [ valueIter, keyOrIdxIter, keyIter ].filterNull().denull()) {
					if (!regexpIdentifier.hasMatch(iter)) {
						break;
					}
				}
			}
			else {
				// syntax 1: "iter in collection"
				if (!regexpIdentifier.hasMatch(leftSide)) {
					break;
				}

				valueIter = leftSide.trim();
			}

			String rightSide = zForExpr.substring(posIn + IN_LITERAL.length).trim();
			if (rightSide.isEmpty) {
				break;
			}

			collectionExpr = rightSide;

			return ZFor(
				iterValue: valueIter,
				iterKeyOrIdx: keyOrIdxIter,
				iterKey: keyIter,
				collectionExpr: collectionExpr,
			);
		}

		this._svcLogger.logError(EzError(_COMPONENT, "Failed to parse z-for expression [${zForExpr}] for tag {$tag}"));
	}

	void _sanityCheckTag(Tag tag) {
		this._sanityCheckTagForPropIssues(tag);
		this._sanityCheckTagForSlotIssues(tag);
	}

	void _sanityCheckTagForSlotIssues(Tag tag) {
		if (!tag.isTypeSlotProvider() && !tag.isTypeSlotConsumer()) {
			return;
		}

		// if (tag.isTypeSlotProvider() && (tag.arrUnnamedChildren.isEmpty || tag.arrUnnamedChildren.length > 1)) {
		// 	this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} is a slot provider, and must have a single unnamed child tag.");
		// 	return;
		// }

		if (tag.isTypeSlotProvider() && tag.arrUnnamedChildren.isEmpty) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} is a slot provider, and must have one or more unnamed children tags.");
			return;
		}

		if (tag.isTypeSlotProvider() && tag.hasAnyParameter()) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} is a slot provider, and cannot have named or positional parameters.");
			return;
		}

		if (tag.isTypeSlotConsumer() && tag.mapZAttrs.isNotEmpty) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} is a slot consumer, and cannot have z-attr attributes.");
			return;
		}

		if (tag.zIf != null && tag.zIf!.isNotEmpty) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} is a slot provider or consumer, and cannot have [z-if].");
			return;
		}

		if (tag.zShow != null && tag.zShow!.isNotEmpty) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} is a slot provider or consumer, and cannot have [z-show].");
			return;
		}
	}

	void _sanityCheckTagForPropIssues(Tag tag) {
		if (tag.isNamedChildTag) {
			if (
				false
				|| tag.zCustomConstructorName != null
				|| tag.zKey != null
				|| tag.stringAttrClass != null
				|| tag.zIf != null
				|| tag.zShow != null
				|| tag.zFor != null
				|| tag.zRef != null
				|| tag.zRefs != null
				|| tag.zRefsKey != null
				|| tag.zBuild != null
				|| tag.zBuilder != null
				|| tag.zName != null
				|| tag.mapStrings.isNotEmpty
				|| tag.mapZBinds.isNotEmpty
				|| tag.mapZOns.isNotEmpty
				|| tag.mapZModels.isNotEmpty
				|| tag.mapNamedChildren.isNotEmpty
			) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} is a parameter tag, and must not have attributes or named props of its own");
			}
		}
	}

	String makePositionalParameterChildTagName(int idx) {
		return SvcZmlParser.CHILD_TAG_POSITIONAL_PARAMETER_PREFIX + idx.toString();
	}

	String unescapeZmlTextForDisplay(String zmlText, { bool allowTrimLeft = false, bool allowTrimRight = false }) {
		String s = zmlText;
		s = s.replaceAll("\\", "\\\\");
		s = s.replaceAll("\"", "\\\"");
		s = s.replaceAll("\$", "\\\$");
		s = s.replaceAll(RegExp(r'<!--.*?-->'), "");
		s = s.replaceAll("&lt;", "<");
		s = s.replaceAll("&gt;", ">");
		s = s.replaceAll("&amp;", "&");
		s = s.replaceAll("\r\n", "\n");
		s = s.replaceAll("\n", " ");
		s = s.replaceAll(RegExp(r'\s+'), " ");

		// we are almost done consolidating the spaces. all that is left is to
		// trim the edges. this function may be called with text snippets that
		// have mustaches before or after them. in other words, we may only
		// have a partial string here, and not the entire text. so we will only
		// trim if allowed by the caller.
		if (allowTrimLeft) {
			s = s.trimLeft();
		}
		if (allowTrimRight) {
			s = s.trimRight();
		}

		// the final text may still have spaces at the edges, if such spaces
		// are "explicitly requested" by using "&nbsp;".
		s = s.replaceAll("<br/>", "\n");
		s = s.replaceAll("\n ", "\n"); // e.g. so that "a<br> b" will give "a\nb" and not "a\n b"
		s = s.replaceAll(RegExp(r'\s*&nbsp;\s*'), "&nbsp;");
		s = s.replaceAll("&nbsp;", " ");
		return s;
	}
}