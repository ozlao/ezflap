
class EzError {
	final String component;
	final String message;

	EzError(this.component, this.message);

	@override
	String toString() {
		return "EzError [${this.component}]: ${this.message}";
	}
}