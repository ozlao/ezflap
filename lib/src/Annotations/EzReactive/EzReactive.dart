
import 'package:ezflap/src/Annotations/Common/EzValue/EzValue.dart';
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/reactive-data-entities/reactive-data-entities.html
///
/// Marks a class as reactive, to allow the use of [EzValue] to mark specific
/// fields as reactive.
class EzReactive extends EzAnnotationBase {
	const EzReactive();
}