
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
/// - [Text] tags that have no positional parameters.
///
/// Scope of changes:
/// - can add a positional parameter.
/// - can clear text (i.e. Tag.text).
class TextTransformer extends TransformerBase {
	@override
	String getIdentifier() => "textTransformer";

	@override
	String getName() => "Text Transformer";

	@override
	bool test(Tag tag) {
		return true
			&& tag.name == "Text"
			&& tag.text.isNotEmpty
			&& tag.arrUnnamedChildren.isEmpty
			&& !tag.mapNamedChildren.containsKey(this.svcZmlParser.makePositionalParameterChildTagName(0))
			&& !tag.doBindsOrStringsContainKey("0")
		;
	}

	@override
	void transform(Tag tag) {
		String wrapped = TagTextProcessor.processTag(tag);

		String paramName = this.svcZmlParser.makePositionalParameterChildTagName(0);
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