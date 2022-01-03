
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

class MustachedStringPart {
	final bool isMustache;
	final String content;

	MustachedStringPart(this.isMustache, this.content);
}

class SvcMustacheParser extends EzServiceBase {
	static SvcMustacheParser i() { return Singleton.get(() => SvcMustacheParser()); }

	SvcLogger get _svcLogger => SvcLogger.i();

	static const String _COMPONENT = "SvcMustacheParser";

	static const String MUSTACHE_START_MARKER = "{{";
	static const String MUSTACHE_END_MARKER = "}}";

	List<MustachedStringPart> splitMustachedTextToParts(String mustachedText) {
		// String processed = "";
		int pos = 0;
		int lastTookEndPos = 0;
		List<MustachedStringPart> arrParts = [ ];
		while (true) {
			int nextPos = mustachedText.indexOf(MUSTACHE_START_MARKER, pos);
			if (nextPos == -1) {
				break;
			}

			if (nextPos > 0) {
				if (mustachedText[nextPos - 1] == "\\") {
					// skip this one
					arrParts.add(MustachedStringPart(false, mustachedText.substring(lastTookEndPos, nextPos - 1)));

					// to skip the backslash in the generated text, we use
					// [nextPos] rather than [nextPos - 1]
					lastTookEndPos = nextPos;

					pos = nextPos + 1;

					continue;
				}
			}

			int endPos = mustachedText.indexOf(MUSTACHE_END_MARKER, nextPos);
			if (endPos == -1) {
				break;
			}

			if (nextPos > lastTookEndPos) {
				arrParts.add(MustachedStringPart(false, mustachedText.substring(lastTookEndPos, nextPos)));
			}
			lastTookEndPos = endPos + 2;


			arrParts.add(MustachedStringPart(true, mustachedText.substring(nextPos + 2, endPos)));

			pos = endPos + 2;
		}

		arrParts.add(MustachedStringPart(false, mustachedText.substring(lastTookEndPos)));

		return arrParts;
	}

	bool doesStringHaveMustache(String s) {
		return this.splitMustachedTextToParts(s).any((x) => x.isMustache);
	}
}