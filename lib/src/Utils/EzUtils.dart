
import 'package:stack_trace/stack_trace.dart';
import "package:path/path.dart";

abstract class EzUtils {
	static Uri getCallerUri() {
		return Frame.caller(1).uri;
	}

	static String getDirFromUri(Uri uri) {
		String path = uri.path;
		String dir = dirname(path);
		return dir;
	}
}