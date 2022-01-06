
/// Utility class for automatically assigning a globally unique identifier for
/// instances of classes that extend it.
/// Useful for debugging.
class Guid {
	static int _nextGuid = 1;
	final int _guid = Guid._makeGloballyUniqueGuid();

	/// Get this instance's guid as integer.
	int get guid {
		return this._guid;
	}

	/// Get this instance's guid as integer.
	int getGuid() {
		return this._guid;
	}

	/// Get this instance's guid as String.
	String getGuidAsString() {
		return this._guid.toString();
	}

	static int _makeGloballyUniqueGuid() {
		int guid = Guid._nextGuid;
		Guid._nextGuid++;
		return guid;
	}
}