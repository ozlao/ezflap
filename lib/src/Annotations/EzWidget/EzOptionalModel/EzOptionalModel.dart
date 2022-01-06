
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/models/models.html#optional-model
///
/// Similar to [EzModel]. The main difference is that when using [EzOptionalModel] -
/// the host widget doesn't have to pass a model.
class EzOptionalModel extends EzAnnotationBase {
	/// The optional model's Assigned Name.
	final String? name;

	const EzOptionalModel([ this.name ]);
}