
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWatch/EzWatch.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzWatch/EzWatchVisitor.dart';

class EzWatchGenerator extends AnnotationGeneratorBase<EzWatch, EzWatchData, MethodElement> {
	EzWatchGenerator(ClassElement element, EzAnnotationVisitor<EzWatch, EzWatchData, MethodElement> visitor) : super(element, visitor);

	@override
	String? generateItemForInState(EzWatchData data) {
		return """
			${data.signature};
		""";
	}
	
	@override
	String? generateItemForInInitState(EzWatchData data) {
		// watchers are initialized during $internalOnReady() (i.e. when _buildHost
		// is initialized), and so we only need to dispose them if we got here when
		// the widget is ready. so far we only saw a widget get disposed before
		// being ready while testing.
		return """
			this.onDispose(() {
				if (this.\$hasReachedReadyNowOrBefore()) {
					this._buildHost._watchHandler_${data.methodName}.dispose();
				}
			});
		""";
	}

	@override
	String? generateItemForInHost(EzWatchData data) {
		return """
			late \$WatchHandler _watchHandler_${data.methodName};
		""";
	}

	@override
	String? generateItemForInHostInitState(EzWatchData data) {
		return """
			_watchHandler_${data.methodName} = \$WatchHandler(
				funcGetWatchedValueOrRxWrapperOrRx: () => ${data.watchedExpression},
				funcOnChange: (oldValue, newValue) => this._ezState.${data.methodName}(oldValue, newValue),
			);
		""";
	}
}