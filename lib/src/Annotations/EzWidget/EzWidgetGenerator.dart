
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWidget.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWidgetGeneratorImpl.dart';
import 'package:source_gen/source_gen.dart';

class EzWidgetGenerator extends GeneratorForAnnotation<EzWidget> {
	@override
	FutureOr<String> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
		EzWidgetGeneratorImpl impl = EzWidgetGeneratorImpl();

		// we need to call generateForAnnotatedElement() on a newly-created
		// instance because source_gen seems to re-use GeneratorForAnnotation,
		// concurrently (because we use await inside), and since our
		// EzWidgetGenerator maintains state - things get messed up if we don't
		// have one instance per each invocation of generateForAnnotatedElement().
		String s = await impl.generateForAnnotatedElement(element, annotation, buildStep);
		return s;
	}
}