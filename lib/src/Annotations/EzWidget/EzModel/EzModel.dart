
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/models/models.html
///
/// Models allow bi-directional communication by letting both the host and the
/// hosted widgets update and read the same piece of data.
class EzModel extends EzAnnotationBase {
	/// The model's Assigned Name.
	final String? name;

	const EzModel([ this.name ]);
}