
class Guid {
	static int _nextGuid = 1;
	final int _guid = Guid._makeGloballyUniqueGuid();

	int get guid {
		return this._guid;
	}

	int getGuid() {
		return this._guid;
	}

	String getGuidAsString() {
		return this._guid.toString();
	}

	static int _makeGloballyUniqueGuid() {
		int guid = Guid._nextGuid;
		Guid._nextGuid++;
		return guid;
	}
}