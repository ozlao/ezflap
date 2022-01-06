
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/events/events.html
///
/// Events allow bottom-up communication with the host widget - the hosted
/// widget emits events and the host widget can listen to them.
class EzEmit extends EzAnnotationBase {
	/// The Assigned Name of the event.
	final String name;

	const EzEmit(this.name);
}