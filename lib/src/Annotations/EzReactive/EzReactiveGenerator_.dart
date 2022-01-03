
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:ezflap/src/Annotations/EzJson/EzJson.dart';
import 'package:ezflap/src/Annotations/EzReactive/EzReactive.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/GenericFieldVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:source_gen/source_gen.dart';

class EzReactiveGenerator extends GeneratorForAnnotation<EzReactive> {
	static const String _COMPONENT = "EzReactiveGenerator";

	SvcLogger get _svcLogger => SvcLogger.i();
	late GenericFieldVisitor _visitor;
	late Element _element;

	static String makeEzReactiveProviderMixinNameForClass(String className) {
		// we prefix this name with $ because the user is not supposed to use
		// it directly (it's used automatically by EzJson)
		return "_\$EzRxProvider${className}Mixin";
	}

	@override
	FutureOr<String> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
		this._element = element;
		//this._visitor = GenericFieldVisitor((x) => this._isCandidateForRx(x));
		this._visitor = GenericFieldVisitor((x) => x.isMarkedAsEzValue);
		String s = this._svcLogger.invoke(() {
			element.visitChildren(this._visitor);
			if (!this._sanityCheck()) {
				return "// An error has occurred. Please check the log.";
			}

			return this._build();
		});

		this._svcLogger.printLoggedErrorsIfNeeded();
		
		return s;
	}

	String? _getCustomName() {
		bool hasAlsoEzJson = AnnotationUtils.hasAnnotation<EzJson>(this._element);
		if (hasAlsoEzJson) {
			String className = this._element.name!;
			return EzReactiveGenerator.makeEzReactiveProviderMixinNameForClass(className);
		}
		return null;
	}

	String _build() {
		Iterable<FieldElement> iter = this._visitor.arrFieldElements;
		String rxWrappersCode = iter.map((x) => this._makeRxWrappersPart(x)).join("\n");
		String cleanClassName = this._getClassNameWithoutUnderscores();
		String customName = this._getCustomName() ?? "_${cleanClassName}RxMixin";

		return """
			class ${customName} {
				${rxWrappersCode}
			}
		""";
	}

	String _getClassName() {
		return this._element.name!;
	}

	String _getClassNameWithoutUnderscores() {
		String name = this._getClassName();
		if (name.startsWith("_")) {
			int pos = 0;
			while (pos < name.length && name[pos] == "_") {
				pos++;
			}
			if (pos == name.length) {
				this._svcLogger.logErrorFrom(_COMPONENT, "@EzReactive() does not support classes with names that consist only of underscores.");
				return "NotSupportedByEzReactive";
			}
			return name.substring(pos);
		}
		return name;
	}

	bool _sanityCheck() {
		if (this._visitor.getArrGenericFieldData().any((x) => x.isMarkedAsEzValue && !x.startsWithDontTouchPrefix)) {
			this._svcLogger.logErrorFrom(_COMPONENT, "@EzValue members in @EzReactive classes must be prefixed with \"_\$\".");
			return false;
		}
		return true;
	}

	String _makeRxWrappersPart(FieldElement el) {
		String derivedName = this._visitor.getDerivedName(el);
		String type = this._visitor.getType(el);
		String? defaultValue = this._visitor.getDefaultValueLiteral(el);
		String maybeRxWrapperGetterLogicWithDefaultValue = this._tryMakeRxWrapperGetterLogicWithDefaultValue(defaultValue, derivedName);
		String maybeRxWrapperGetterLogicWithoutDefaultValue = this._tryMakeRxWrapperGetterLogicWithoutDefaultValue(defaultValue, derivedName);

		return """
			RxWrapper<${type}> _\$${derivedName}RxWrapper = RxWrapper<${type}>();
			${type} get ${derivedName} {
				${maybeRxWrapperGetterLogicWithDefaultValue}
				${maybeRxWrapperGetterLogicWithoutDefaultValue}
			}
			set ${derivedName}(${type} value) {
				this._\$${derivedName}RxWrapper.setValue(value);
			}
		""";
	}

	String _tryMakeRxWrapperGetterLogicWithDefaultValue(String? defaultValue, String derivedName) {
		if (defaultValue == null) {
			return "";
		}
		return """
			return this._\$${derivedName}RxWrapper.getValueAndSetDefaultIfNotInit(${defaultValue});
		""";
	}

	String _tryMakeRxWrapperGetterLogicWithoutDefaultValue(String? defaultValue, String derivedName) {
		if (defaultValue != null) {
			return "";
		}
		return """
			return this._\$${derivedName}RxWrapper.getValue();
		""";
	}
}