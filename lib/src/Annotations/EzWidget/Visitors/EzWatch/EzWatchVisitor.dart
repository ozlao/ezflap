
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWatch/EzWatch.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/MethodElementVisitorBase/MethodElementVisitorBase.dart';

class EzWatchData extends EzMethodDataBase {
	final String watchedExpression;

	EzWatchData({
		required this.watchedExpression,
	});

	@override
	String toString() {
		return "EzWatchData: ${watchedExpression}: ${signature}";
	}
}

class EzWatchVisitor extends MethodElementVisitorBase<EzWatch, EzWatchData> {
	static const String _COMPONENT = "EzWatchVisitor";

	@override
	visitMethodElement(MethodElement element) {
		this.process(element);
	}
	
	@override
	EzWatch? convertFromAnnotation(DartObject objValue, ElementAnnotation elementAnnotation) {
		DartObject? objWatchedExpression = objValue.getField("watchedExpression");
		String? watchedExpression = objWatchedExpression?.toStringValue();
		if (watchedExpression == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "[watchedExpression] not provided in ElementAnnotation ${elementAnnotation}");
			return null;
		}
		
		return EzWatch(watchedExpression);
	}

	@override
	// ignore: avoid_renaming_method_parameters
	EzWatchData? makeData(EzWatch ezField, MethodElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String methodName = this.getMethodName(element);
		String signature = this.getSignature(element);

		return EzWatchData(watchedExpression: ezField.watchedExpression)
			..methodName = methodName
			..signature = signature
		;
	}

	@override
	EzWatch? makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		// not used; we override convertFromAnnotation() instead because we
		// need EzWatch.watchedExpression
		return null;
	}
}