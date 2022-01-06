
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Parser/Mustache/SvcMustacheParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/Children/ChildrenTransformer.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/EzflapWidgetText/EzflapWidgetTextTransformer.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/Text/TextTransformer.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/TextSpan/TextSpanTransformer.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/TransformerBase.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';


/// Transformation rules:
/// - transformation is invoked on the root tag of a ZML block (be it a Widget's
///   primary ZML, initial ZML, or a ZSS snippet.
/// - the result of the transformation is the same or a new root tag.
/// - transformers may modify tags in-place.
/// - transformers may modify the hierarchy of tags.
/// - each tag in the hierarchy (including both constructor tags and parameter
///   tags) is checked for available transformers.
/// - the transformers are consulted in the order of their registration.
/// - each transform is tested and invoked for all tags in the hierarchy before
///   moving on to the next transformer.
/// - before starting to invoke a transformer, all tags are collected in the
///   order they will be given to the transformer.
/// - therefore, it is technically possible for a transformer to be passed a
///   stale tag that is no longer in the hierarchy; this can happen if the
///   transformer removes a tag above the tag that is currently being processed.
///   it is each transformer's responsibility to deal with such situations
///   gracefully.
/// - tags are re-collected before starting with the next transformer. this
///   allows transformers to operate on the output of previous transformers.
class SvcZmlTransformer extends EzServiceBase {
	static SvcZmlTransformer i() { return $Singleton.get(() => SvcZmlTransformer()); }

	static const String _COMPONENT = "SvcZmlTransformer";

	SvcLogger get _svcLogger => SvcLogger.i();
	SvcMustacheParser get _svcMustacheParser => SvcMustacheParser.i();

	Map<String, TransformerBase> _mapTransformers = { };
	late List<Tag> _arrCollectedTags;
	bool _wasInit = false;

	void bootstrapDefaultTransformers() {
		if (this._wasInit) {
			// useful for some testing scenarios where this is called multiple times
			return;
		}
		this._wasInit = true;

		this._registerTransformer(EzflapWidgetTextTransformer());
		this._registerTransformer(ChildrenTransformer());
		this._registerTransformer(TextSpanTransformer());
		this._registerTransformer(TextTransformer());
	}

	void _registerTransformer(TransformerBase transformer) {
		String key = transformer.getIdentifier();
		if (this._mapTransformers.containsKey(key)) {
			TransformerBase existingTransformer = this._mapTransformers[key]!;
			this._svcLogger.logErrorFrom(_COMPONENT, "A transformer with key [${key}] has already been registered: ${existingTransformer}");
		}

		this._mapTransformers[key] = transformer;
	}

	void _recollectTags(Tag rootTag) {
		this._arrCollectedTags = rootTag.collectDescendantsAndSelf();
	}

	Tag transform(Tag rootTag) {
		for (TransformerBase transformer in this._mapTransformers.values) {
			this._recollectTags(rootTag);
			for (Tag tag in this._arrCollectedTags) {
				if (transformer.test(tag)) {
					transformer.transform(tag);
				}
			}
		}
		return rootTag;
	}

	String convertMustacheToInterpolation(String mustachedText, bool wrapInQuotes) {
		List<MustachedStringPart> arrSplit = this._svcMustacheParser.splitMustachedTextToParts(mustachedText);
		String processed = arrSplit
			.map((x) {
				if (x.isMustache) {
					return "\${${x.content}}";
				}
				else {
					return x.content;
				}
			})
			.join("")
		;

		if (wrapInQuotes) {
			processed = "\"\"\"${processed}\"\"\"";
		}

		return processed;
	}
}