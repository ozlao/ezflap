
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

/// Full documentation:
///  - In `@EzReactive` classes: https://www.ezflap.io/deep-dive/reactive-data-entities/reactive-data-entities.html#ezreactive
///  - In `@EzJson` classes: https://www.ezflap.io/deep-dive/json/json.html
///
/// Mark a field as a JSON value (in an `@EzJson` class) or a reactive value
/// (in an `@EzReactive` class), or both (if the class has both `@EzJson` and
/// `@EzReactive`).
class EzValue extends EzAnnotationBase {
	const EzValue();
}
