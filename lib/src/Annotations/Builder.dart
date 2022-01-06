
// ignore_for_file: avoid_print

import 'package:build/build.dart';
import 'package:ezflap/src/Annotations/EzJson/EzJsonGenerator_.dart';
import 'package:ezflap/src/Annotations/EzReactive/EzReactiveGenerator_.dart';
import 'package:ezflap/src/Annotations/EzService/EzServiceGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWidgetGenerator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';

Builder annotationBuilder(BuilderOptions options) {
	return SharedPartBuilder(
		[
			EzJsonGenerator(),
			EzReactiveGenerator(),
			EzServiceGenerator(),
			EzWidgetGenerator(),
		],
		"annotation2",
		allowSyntaxErrors: true,
		formatOutput: (String code) {
			String formatted;
			try {
				formatted = DartFormatter().format(code);
			}
			catch (ex) {
				print("An exception has occurred when formatting the code: ${ex}");
				print("Skipping formatting...");
				formatted = code;
			}

			return formatted;
		},
	);
}
