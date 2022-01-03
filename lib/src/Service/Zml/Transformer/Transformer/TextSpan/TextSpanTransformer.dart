
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/Common/TagTextProcessor/TagTextProcessor.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/TransformerBase.dart';

/// Action:
/// - transform "natural" HTML-like text to a proper positional parameter.
/// - convert mustache syntax to interpolation syntax.
/// - un-escape the text according to standard HTML rules (e.g. convert "&lt;"
///   to "<", "&amp;" to "&", etc.)
///
/// Applies to:
/// - [TextSpan] tags that have no [text] parameter.
///
/// Scope of changes:
/// - can add a [text] named parameter.
/// - can clear text (i.e. Tag.text).
class TextSpanTransformer extends TransformerBase {
	@override
	String getIdentifier() => "textSpanTransformer";

	@override
	String getName() => "TextSpan Transformer";

	@override
	bool test(Tag tag) {
		return true
			&& tag.name == "TextSpan"
			&& tag.text.isNotEmpty
			&& tag.arrUnnamedChildren.isEmpty
			&& !tag.mapNamedChildren.containsKey("text")
			&& !tag.doBindsOrStringsContainKey("text")
		;
	}

	@override
	void transform(Tag tag) {
		String wrapped = TagTextProcessor.processTag(tag);
		String paramName = "text";
		Tag newTag = Tag(
			parent: tag,
			name: paramName,
			isNamedChildTag: true,
		);
		newTag.addText(wrapped, isComment: false);
		tag.addChildTag(newTag);
		tag.clearText();
	}
}