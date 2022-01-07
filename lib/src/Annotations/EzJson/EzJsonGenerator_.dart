
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:ezflap/src/Annotations/EzJson/EzJson.dart';
import 'package:ezflap/src/Annotations/EzJson/GenFrom/GenFrom.dart';
import 'package:ezflap/src/Annotations/EzJson/GenFromJsonMap/GenFromJsonMap.dart';
import 'package:ezflap/src/Annotations/EzJson/GenToJsonMap/GenToJsonMap.dart';
import 'package:ezflap/src/Annotations/EzReactive/EzReactive.dart';
import 'package:ezflap/src/Annotations/EzReactive/EzReactiveGenerator_.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/GenericFieldVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:source_gen/source_gen.dart';

class EzJsonGenerator extends GeneratorForAnnotation<EzJson> {
	SvcLogger get _svcLogger => SvcLogger.i();
	late GenericFieldVisitor _visitor;
	late Element _element;

	@override
	FutureOr<String> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
		this._element = element;
		this._visitor = GenericFieldVisitor((x) => x.isMarkedAsEzValue);
		String s = this._svcLogger.invoke(() {
			element.visitChildren(this._visitor);
			return this._generate();
		});

		this._svcLogger.printLoggedErrorsIfNeeded();

		return s;
	}

	String _generate() {
		String dataProviderMixinCode = this._makeDataProviderMixinCode();
		String baseClassCode = this._makeBaseClassCode();

		String s = """
			${dataProviderMixinCode}
			${baseClassCode}
		""";

		return s;
	}

	String _makeDataProviderMixinCode() {
		if (this._doesAlsoHaveEzReactive()) {
			// using the @EzReactive mixin, so no need to create our own.
			return "";
		}

		String mixinName = this._getDataProviderMixinName();
		List<String> arr = this._visitor.getArrGenericFieldData()
			.map((GenericFieldData data) {
				if (!data.startsWithDontTouchPrefix) {
					// handle "in-place" instead of adding this to the mixin
					return "";
				}

				String type = data.typeNode.getFullName();
				String sLate = "";
				if (!data.typeNode.isNullable && !data.typeNode.isDynamic()) {
					sLate = "late";
				}

				return """
					${sLate} ${type} ${data.derivedName};
				""";
			})
			.toList()
		;

		String body = arr.join("\n");
		return """
			class ${mixinName} {
				${body}
			}
		""";
	}

	String _makeFactoryFromJsonCode() {
		String className = this._getClassName();
		return """
			static ${className} factoryFromJson(String sJson) {
				${className} instance = ${className}();
				instance.fromJson(sJson);
				return instance;
			}
		""";
	}

	String _makeFactoryFromJsonMapCode() {
		String className = this._getClassName();
		return """
			static ${className} factoryFromJsonMap(Map<String, dynamic> map) {
				${className} instance = ${className}();
				instance.fromJsonMap(map);
				return instance;
			}
		""";
	}

	String _makeBaseClassCode() {
		String className = this._getClassName();
		String dataProviderMixinName = this._getDataProviderMixinName();
		String factoryFromJsonCode = this._makeFactoryFromJsonCode();
		String factoryFromJsonMapCode = this._makeFactoryFromJsonMapCode();
		String fromJsonMapCode = this._makeFromJsonMapCode();
		String fromCode = this._makeFromCode();
		String toJsonCode = this._makeToJsonCode();
		String toJsonMapCode = this._makeToJsonMapCode();
		String fromJsonCode = this._makeFromJsonCode();
		String deepCloneCode = this._makeDeepCloneCode();

		return """
			// ignore_for_file: unused_element, duplicate_ignore
			
			abstract class _${className}Base with ${dataProviderMixinName} {
				${factoryFromJsonCode}
				${factoryFromJsonMapCode}
				${fromJsonMapCode}
				${fromCode}
				${toJsonCode}
				${toJsonMapCode}
				${fromJsonCode}
				${deepCloneCode}
			}
		""";
	}

	String _makeFromJsonMapCode() {
		return GenFromJsonMap(this._visitor).generate();
	}

	String _makeFromCode() {
		String className = this._getClassName();
		return GenFrom(this._visitor).generate(className);
	}

	String _makeToJsonCode() {
		return """
			String toJson() {
				Map<String, dynamic> map = this.toJsonMap();
				String sJson = json.encode(map);
				return sJson;
			}
		""";
	}

	String _makeToJsonMapCode() {
		return GenToJsonMap(this._visitor).generate();
	}

	String _makeFromJsonCode() {
		return """
			void fromJson(String sJson) {
				dynamic jsonBody = json.decode(sJson);
				this.fromJsonMap(jsonBody);
			}
		""";
	}

	String _makeDeepCloneCode() {
		String className = this._getClassName();
		return """
			${className} deepClone() {
				String sJson = this.toJson();
				${className} instance = ${className}();
				instance.fromJson(sJson);
				return instance;
			}
		""";
	}


	String _getClassName() {
		return this._element.name!;
	}

	bool _doesAlsoHaveEzReactive() {
		return AnnotationUtils.hasAnnotation<EzReactive>(this._element);
	}

	String _getDataProviderMixinName() {
		String className = this._getClassName();
		if (this._doesAlsoHaveEzReactive()) {
			// we will use the data provider provided by @EzReactive.
			return EzReactiveGenerator.makeEzReactiveProviderMixinNameForClass(className);
		}
		else {
			// we will use our own data provider (which is also generated by
			// EzJsonGenerator if not relying on the @EzReactive one).
			return "_\$EzDataProvider${className}Mixin";
		}
	}
}