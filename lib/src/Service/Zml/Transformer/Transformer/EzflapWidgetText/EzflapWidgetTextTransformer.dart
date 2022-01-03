
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/Common/TagTextProcessor/TagTextProcessor.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/TransformerBase.dart';

/// Action:
/// - sets the Tag's interpolatedText member to the processed text (similar to
///   [TextTransformer].
///
/// Applies to:
/// - ezFlap widget tags that have text and no unnamed children.
///
/// Scope of changes:
/// - sets Tag.interpolatedText
class EzflapWidgetTextTransformer extends TransformerBase {
	@override
	String getIdentifier() => "ezflapWidgetTextTransformer";

	@override
	String getName() => "ezFlap Widget Text Transformer";

	@override
	bool test(Tag tag) {
		return true
			&& (this.isTagOfEzflapWidget(tag) || tag.isTypeBuild()) // <ZBuild> can have interpolated text
			&& tag.text.isNotEmpty
			&& tag.arrUnnamedChildren.isEmpty
		;
	}

	@override
	void transform(Tag tag) {
		String wrapped = TagTextProcessor.processTag(tag);
		tag.interpolatedText = wrapped;
	}
}