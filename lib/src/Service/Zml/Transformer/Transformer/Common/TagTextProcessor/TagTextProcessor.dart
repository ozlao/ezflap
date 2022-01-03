
import 'package:ezflap/src/Service/Parser/Mustache/SvcMustacheParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';

class TagTextProcessor {
	static String processTag(Tag tag) {
		SvcMustacheParser svcMustacheParser = SvcMustacheParser.i();
		SvcZmlParser svcZmlParser = SvcZmlParser.i();

		String content = tag.textWithoutXmlComments;
		List<MustachedStringPart> arrParts = svcMustacheParser.splitMustachedTextToParts(content);
		List<String> arrProcessed = [ ];

		bool isFirstText = true;
		bool isLastText = (arrParts.length == 1);
		for (MustachedStringPart part in arrParts) {
			String processed;
			if (part.isMustache) {
				processed = "\${${part.content}}";
			}
			else {
				processed = svcZmlParser.unescapeZmlTextForDisplay(part.content, allowTrimLeft: isFirstText, allowTrimRight: isLastText);
			}
			arrProcessed.add(processed);

			isFirstText = false;
			isLastText = (arrProcessed.length == arrParts.length - 1);
		}

		String processedContent = arrProcessed.join("");
		String wrapped = "\"\"\"${processedContent}\"\"\"";

		return wrapped;
	}
}