
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzComputed/EzComputedGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzEmit/EzEmitGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzField/EzFieldGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzMethod/EzMethodGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzModel/EzModelGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzOptionalModel/EzOptionalModelGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzProp/EzPropGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzRef/EzRefGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzRefs/EzRefsGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzRouteParam/EzRouteParamGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/EzWatch/EzWatchGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Widget/BuildHost/BuildHostGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Widget/EzStateBase/EzStateBaseGenerator.dart';
import 'package:ezflap/src/Annotations/EzWidget/Processors/Template/TemplateProcessor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzComputed/EzComputedVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzEmit/EzEmitVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzField/EzFieldVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzMethod/EzMethodVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzModel/EzModelVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzOptionalModel/EzOptionalModelVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzProp/EzPropVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzRef/EzRefVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzRefs/EzRefsVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzRouteParam/EzRouteParamVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzWatch/EzWatchVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';
import 'package:ezflap/src/Annotations/EzWithDI/EzWithDIGenerator_.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Reflector/SvcReflector_.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:ezflap/src/Service/Zml/Generator/AnnotationsSummary/AnnotationsSummary.dart';
import 'package:ezflap/src/Service/Zml/Generator/SvcZmlGenerator_.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Utils/EzError/EzError.dart';
import 'package:source_gen/source_gen.dart';

class EzWidgetGeneratorImpl {
	static const String _COMPONENT = "EzWidgetGenerator";

	SvcLogger get _svcLogger => SvcLogger.i();
	SvcZmlGenerator get _svcZmlGenerator => SvcZmlGenerator.i();
	SvcZmlTransformer get _svcZmlTransformer => SvcZmlTransformer.i();
	SvcReflector get _svcReflector => SvcReflector.i();

	late ConstantReader _annotation;
	late ClassElement _element;
	late TemplateProcessor _templateProcessor;

	late EzFieldVisitor _ezFieldVisitor;
	late EzModelVisitor _ezModelVisitor;
	late EzPropVisitor _ezPropVisitor;
	late EzOptionalModelVisitor _ezOptionalModelVisitor;
	
	late String _primaryBuilder;
	String? _initialBuilder;
	late String _zssStyleFunctions;

	FutureOr<String> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
		this._element = element as ClassElement;
		this._annotation = annotation;
		this._svcZmlTransformer.bootstrapDefaultTransformers();

		LibraryElement inputLibraryElement = await buildStep.inputLibrary;
		this._svcReflector.repopulate(inputLibraryElement);
		String s = this._svcLogger.invoke(() {
			this._templateProcessor = TemplateProcessor(this._element, this._annotation);

			SplitCode splitCode = this._combine([
				this._getEzDICode(),
				this._getEzDIProvidersCode(),
				this._getEzFieldCode(),
				this._getEzMethodCode(),
				this._getEzEmitCode(),
				this._getEzComputedCode(),
				this._getEzWatchCode(),
				this._getEzPropCode(),
				this._getEzModelCode(),
				this._getEzOptionalModelCode(),
				this._getEzRefCode(),
				this._getEzRefsCode(),
				this._getEzRouteParamCode(),
			]);

			AnnotationsSummary annotationsSummary = this._makeAnnotationsSummary();
			this._preparePrimaryBuilderCode(annotationsSummary);
			this._prepareInitialBuilderCodeIfNeeded(annotationsSummary);

			return this._build(
				zssStyleFunctions: this._zssStyleFunctions,
				primaryBuilder: this._primaryBuilder,
				initialBuilder: this._initialBuilder,
				splitCode: splitCode,
			);
		});

		if (this._svcLogger.hasLoggedErrors()) {
			this._svcLogger.printLoggedErrorsIfNeeded();
		}

		return s;
	}

	SplitCode _combine(List<SplitCode> arrSplitCodes) {
		List<String> arrInState = [ ];
		List<String> arrInInitState = [ ];
		List<String> arrInHost = [ ];
		List<String> arrInRefreshProps = [ ];
		List<String> arrInHostInitState = [ ];

		for (SplitCode splitCode in arrSplitCodes) {
			arrInState.addAll(splitCode.arrInState);
			arrInInitState.addAll(splitCode.arrInStateInitState);
			arrInHost.addAll(splitCode.arrInBuildHost);
			arrInRefreshProps.addAll(splitCode.arrInStateRefreshProps);
			arrInHostInitState.addAll(splitCode.arrInBuildHostInitState);
		}

		return SplitCode(
			arrInState: arrInState,
			arrInStateInitState: arrInInitState,
			arrInHost: arrInHost,
			arrInStateRefreshProps: arrInRefreshProps,
			arrInHostInitState: arrInHostInitState,
		);
	}
	
	SplitCode _getEzDICode() {
		return SplitCode(arrInState: [ EzWithDIGenerator.generateForEzDIs(this._element, supportOverrides: true) ]);
	}

	SplitCode _getEzDIProvidersCode() {
		return SplitCode(arrInState: [ EzWithDIGenerator.generateForEzDIProviders(this._element) ]);
	}

	SplitCode _getEzFieldCode() {
		this._ezFieldVisitor = EzFieldVisitor();
		return EzFieldGenerator(this._element, this._ezFieldVisitor).generate();
	}

	SplitCode _getEzMethodCode() {
		return EzMethodGenerator(this._element, EzMethodVisitor()).generate();
	}

	SplitCode _getEzEmitCode() {
		return EzEmitGenerator(this._element, EzEmitVisitor()).generate();
	}

	SplitCode _getEzComputedCode() {
		return EzComputedGenerator(this._element, EzComputedVisitor()).generate();
	}

	SplitCode _getEzWatchCode() {
		return EzWatchGenerator(this._element, EzWatchVisitor()).generate();
	}

	SplitCode _getEzPropCode() {
		this._ezPropVisitor = EzPropVisitor();
		return EzPropGenerator(this._element, this._ezPropVisitor).generate();
	}

	SplitCode _getEzModelCode() {
		this._ezModelVisitor = EzModelVisitor();
		return EzModelGenerator(this._element, this._ezModelVisitor).generate();
	}

	SplitCode _getEzOptionalModelCode() {
		this._ezOptionalModelVisitor = EzOptionalModelVisitor();
		return EzOptionalModelGenerator(this._element, this._ezOptionalModelVisitor).generate();
	}

	SplitCode _getEzRefCode() {
		return EzRefGenerator(this._element, EzRefVisitor()).generate();
	}

	SplitCode _getEzRefsCode() {
		return EzRefsGenerator(this._element, EzRefsVisitor()).generate();
	}

	SplitCode _getEzRouteParamCode() {
		return EzRouteParamGenerator(this._element, EzRouteParamVisitor()).generate();
	}

	void _preparePrimaryBuilderCode(AnnotationsSummary annotationsSummary) {
		AstNodeWrapper? astNode = this._templateProcessor.processPrimary();
		if (astNode == null) {
			throw EzError(_COMPONENT, "ZML compilation failed.");
		}
		this._primaryBuilder = this._svcZmlGenerator.generateBuilderContent(astNode, annotationsSummary);
		this._zssStyleFunctions = this._svcZmlGenerator.generateBuilderZssStyleFunctions(astNode);
	}

	void _prepareInitialBuilderCodeIfNeeded(AnnotationsSummary annotationsSummary) {
		AstNodeWrapper? astNode = this._templateProcessor.processInitial();
		if (astNode == null) {
			return;
		}
		this._initialBuilder = this._svcZmlGenerator.generateBuilderContent(astNode, annotationsSummary);
	}

	AnnotationsSummary _makeAnnotationsSummary() {
		return AnnotationsSummary(
			arrFieldAssignedNames: this._ezFieldVisitor.getAssignedNames(),
			mapFieldsData: this._ezFieldVisitor.getFieldsData().asMap().map((int key, EzFieldDataBase value) => MapEntry(value.assignedName, value)),
			arrModelAssignedNames: [ ...this._ezModelVisitor.getAssignedNames(), ...this._ezOptionalModelVisitor.getAssignedNames() ],
			mapPropDescriptors: this._ezPropVisitor.getEzPropDataMap(),
		);
	}

	String _build({
		required String zssStyleFunctions,
		required String primaryBuilder,
		String? initialBuilder,
		required SplitCode splitCode,
	}) {
		String sEzStateBase = EzStateBaseGenerator(element: this._element, annotation: this._annotation, splitCode: splitCode).generate();

		BuildHostGenerator buildHostGenerator = BuildHostGenerator(
			element: this._element,
			annotation: this._annotation,
			zssStyleFunctions: this._zssStyleFunctions,
			sBuilder: primaryBuilder,
			sInitialBuilder: initialBuilder,
			splitCode: splitCode,
		);
		String sBuildHost = buildHostGenerator.generate();

		return """
			// ignore_for_file: invalid_use_of_internal_member, camel_case_types, unused_element, prefer_function_declarations_over_variables, avoid_types_as_parameter_names, dead_code, unnecessary_overrides, prefer_const_literals_to_create_immutables, unnecessary_string_escapes, unnecessary_string_interpolations, prefer_adjacent_string_concatenation, unnecessary_cast
			${sEzStateBase}
			${sBuildHost}
		""";
	}
}