
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:ezflap/src/Annotations/EzService/EzService.dart';
import 'package:ezflap/src/Annotations/EzWithDI/EzWithDIGenerator_.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:source_gen/source_gen.dart';

class EzServiceGenerator extends GeneratorForAnnotation<EzService> {
	static const String _COMPONENT = "EzServiceGenerator";

	late Element _element;

	SvcLogger get _svcLogger => SvcLogger.i();

	@override
	FutureOr<String> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
		this._element = element;

		String s = this._svcLogger.invoke(() {
			String baseClassName = this._getBaseClassName(element);
			String forEzDIs = EzWithDIGenerator.generateForEzDIs(element, supportOverrides: true);
			String forEzDIProviders = EzWithDIGenerator.generateForEzDIProviders(element);
			String className = this._getClassName();

			return """
				abstract class _EzServiceBase extends ${baseClassName} {
					static ${className} i() { return \$Singleton.get(() => ${className}()); }
					${forEzDIs}
					${forEzDIProviders}
				}
			""";
		});

		this._svcLogger.printLoggedErrorsIfNeeded();
		
		return s;
	}

	String _getClassName() {
		return this._element.name!;
	}

	String _getBaseClassName(Element element) {
		ElementAnnotation? elementAnnotation = AnnotationUtils.tryGetAnnotation<EzService>(element);
		assert(elementAnnotation != null, "could not find [EzService] annotation (should not be technically possible!)");

		String? overrideBaseClassTypeLiteral = AnnotationUtils.tryGetAnnotationArgumentLiteralFromAst(elementAnnotation!, 0);
		if (overrideBaseClassTypeLiteral == "null") {
			// not used
			overrideBaseClassTypeLiteral = null;
		}
		else if (overrideBaseClassTypeLiteral != null && overrideBaseClassTypeLiteral.length > 2) {
			String ch1 = overrideBaseClassTypeLiteral[0];
			String ch2 = overrideBaseClassTypeLiteral[overrideBaseClassTypeLiteral.length - 1];
			if (ch1 == ch2 && (ch1 == '"' || ch1 == "'")) {
				// parent class provided as literal.
				// we will improve this in the future, if the Dart issues doesn't
				// get resolved... (i.e. we'll switch to using computeConstantValue()
				// instead of this hacky parsing).
				overrideBaseClassTypeLiteral = overrideBaseClassTypeLiteral.substring(1, overrideBaseClassTypeLiteral.length - 1);
			}
		}

		String baseClassName = overrideBaseClassTypeLiteral ?? "EzServiceBase";
		return baseClassName;
	}
}