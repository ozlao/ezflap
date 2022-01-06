
import 'package:ezflap/src/Annotations/EzWidget/Reflectors/EzflapWidgetsReflector.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:ezflap/src/Service/Zml/Generator/AnnotationsSummary/AnnotationsSummary.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

class _CodeSnippet {
	final String code;
	final bool isPrefixedWithIf;

	_CodeSnippet({ required this.code, this.isPrefixedWithIf = false });
}

class SvcZmlGenerator extends EzServiceBase {
	static SvcZmlGenerator i() { return $Singleton.get(() => SvcZmlGenerator()); }

	SvcLogger get _svcLogger => SvcLogger.i();
	SvcZmlTransformer get _svcZmlTransformer => SvcZmlTransformer.i();

	late AnnotationsSummary _annotationsSummary;

	static const String _COMPONENT = "SvcZmlGenerator";

	String generateBuilderContent(AstNodeWrapper wrapperNode, AnnotationsSummary annotationsSummary) {
		this._annotationsSummary = annotationsSummary;
		AstNodeConstructor rootNode = wrapperNode.rootConstructorNode;
		String fromNode = this._generateFromNode(rootNode);
		return "return ${fromNode};";
	}

	String generateBuilderZssStyleFunctions(AstNodeWrapper wrapperNode) {
		Map<int, AstNodeZssStyle> mapZssStyleNodes = wrapperNode.mapZssStyleNodes;
		String snippet = this._generateZssStyleFunctions(mapZssStyleNodes);
		return snippet;
	}

	String _generateZssStyleFunctions(Map<int, AstNodeZssStyle> mapZssStyleNodes) {
		return mapZssStyleNodes.values.map((x) => this._generateZssStyleFunction(x)).join("\n");
	}

	String _generateZssStyleFunction(AstNodeZssStyle node) {
		String styleSnippet = this._generateFromNode(node.styleNode);
		String zssStyleFuncName = this._makeZssStyleFuncName(node.styleUid);

		return """
			${node.typeNode.value} ${zssStyleFuncName}() => ${styleSnippet};
		""";
	}

	String _makeZssStyleFuncName(int uid) {
		return "_zssStyle_${uid}";
	}
	
	String _generateFromNode(AstNodeBase node) {
		// ignore: dead_code
		if (false) { }
		else if (node is AstNodeConstructor) return this._generateFromNodeConstructor(node: node, isInList: false);
		else if (node is AstNodeConstructorsList) return this._generateFromNodeConstructorsList(node);
		else if (node is AstNodeMutuallyExclusiveConstructorsList) return this._generateFromNodeMutuallyExclusiveConstructorsList(node);
		else if (node is AstNodeLiteral) return this._generateFromNodeLiteral(node);
		else if (node is AstNodeStringWithMustache) return this._generateFromNodeStringWithMustache(node);
		else if (node is AstNodeNull) return this._generateFromNodeNull(node);
		else if (node is AstNodeZssParameterValue) return this._generateFromNodeZssParameterValue(node);
		else if (node is AstNodeSlotProvider) return this._generateFromNodeSlotProvider(node);

		// when generated from this function - we are not in a list (we may
		// change it in the future and add an "isInList" parameter to this
		// function (i.e. _generateFromNode()) as well).
		else if (node is AstNodeSlotConsumer) return this._generateFromNodeSlotConsumer(node: node, isInList: false);

		String errText = "Unrecognized node [{$node}]";
		this._svcLogger.logErrorFrom(_COMPONENT, errText);
		return "/* ${errText} */";
	}

	String _generateFromNodeLiteral(AstNodeLiteral node) {
		return node.value;
	}

	String _generateFromNodeNull(AstNodeNull node) {
		return "null";
	}

	String _generateFromNodeStringWithMustache(AstNodeStringWithMustache node) {
		return this._svcZmlTransformer.convertMustacheToInterpolation(node.value, true);
	}

	String _generateFromNodeConstructorLike({ required AstNodeConstructorLike node, required bool isInList }) {
		if (node is AstNodeConstructor) {
			return this._generateFromNodeConstructor(node: node, isInList: isInList);
		}
		else if (node is AstNodeSlotConsumer) {
			return this._generateFromNodeSlotConsumer(node: node, isInList: isInList);
		}
		throw "unsupported node type: ${node.runtimeType}";
	}

	String _generateFromNodeSlotConsumer({ required AstNodeSlotConsumer node, required bool isInList }) {
		if (isInList) {
			return this._generateFromNodeSlotConsumerInList(node);
		}
		else {
			return this._generateFromNodeSlotConsumerNotInList(node);
		}
	}

	String _generateFromNodeSlotConsumerInList(AstNodeSlotConsumer node) {
		String name = "null";
		if (node.name != null) {
			name = "\"${node.name}\"";
		}

		List<String> arrParts = [ ];
		if (node.defaultChildList != null) {
			//String s = this._generateFromNodeConstructorLike(node.defaultChildList!);
			String s = this._generateFromNodeConstructorsList(node.defaultChildList!);

			arrParts.add("""
				if (!this._ezState.widget.\$hasSlotProvider(${name}))
					...${s}
			""");
		}

		String scopeParamsMap = this._makeSlotScopeParamsMapFromNodeSlotConsumer(node);
		arrParts.add("""
			if (this._ezState.widget.\$hasSlotProvider(${name}))
				...(this._ezState.widget.\$getSlotProviderWidgets(${name}, ${scopeParamsMap}))
		""");

		return arrParts.join(",");
	}

	String _generateFromNodeSlotConsumerNotInList(AstNodeSlotConsumer node) {
		String name = "null";
		if (node.name != null) {
			name = "\"${node.name}\"";
		}

		String scopeParamsMap = this._makeSlotScopeParamsMapFromNodeSlotConsumer(node);
		if (node.defaultChildList == null) {
			return """
				this._ezState.widget.\$getSlotProviderWidgets(${name}, ${scopeParamsMap}).first
			""";
		}
		else {
			String s = this._generateFromNodeConstructorsList(node.defaultChildList!);
			String defaultWidgetCode = "${s}.first";

			return """
				(
					this._ezState.widget.\$getSingleSlotProviderWidgetOrDefault(${name}, ${scopeParamsMap}, (${defaultWidgetCode}))
				) 
			""";
		}
	}

	String _makeSlotScopeParamsMapFromNodeSlotConsumer(AstNodeSlotConsumer node) {
		List<String> arrParts = [ ];

		node.mapNamedParamNodes.forEach((String key, AstNodeBase nodeParam) {
			String valueCode = this._generateFromNode(nodeParam);
			String pairCode = "\"${key}\": ${valueCode}";
			arrParts.add(pairCode);
		});

		node.mapStringNodes.forEach((String key, AstNodeStringWithMustache nodeParam) {
			String valueCode = this._generateFromNodeStringWithMustache(nodeParam);
			String pairCode = "\"${key}\": ${valueCode}";
			arrParts.add(pairCode);
		});

		String s = arrParts.join(",");

		return """
			{ ${s} }
		""";
	}

	String _generateFromNodeConstructor({ required AstNodeConstructor node, required bool isInList }) {
		_CodeSnippet codeSnippet = this._makeConstructorCode(node);

		String constructorCode = codeSnippet.code;
		bool hasIfPrefix = codeSnippet.isPrefixedWithIf;
		if (node.useInheritingWidget) {
			constructorCode = "funcMakeInheritingWidget()";
		}

		String code;
		String constructorCode2 = this._wrapWithVisibilityIfNeeded(node, constructorCode);
		if (node.hasFor()) {
			assert(isInList);

			String constructorCode3 = this._wrapWithTernaryIfNeeded(node, constructorCode2);
			code = this._wrapWithForIfNeeded(node, constructorCode3);
		}
		else {
			String maybeConditionClause = this._makeConditionClause(node: node, isInList: isInList);
			String constructorCode3 = constructorCode2;
			if (!hasIfPrefix) {
				// wrap with parentheses; this is needed in case the constructor
				// is of an ezFlap widget, and followed by "..initProps" and
				// other ".." initializers, because otherwise it doesn't work
				// properly when combined with the ternary operator used to
				// handle mutually-exclusive constructors in a single-child
				// parent.
				constructorCode3 = """
					(
						${constructorCode2}
					)
				""";
			}

			code = """
				${maybeConditionClause}
					${constructorCode3}
			""";
		}

		if (isInList) {
			String maybePrimaryConditionClause = this._makePriorityConditionClause(node);
			code = """
				${maybePrimaryConditionClause}
					${code}
			""";
		}

		return code;
	}

	_CodeSnippet _makeConstructorCode(AstNodeConstructor node) {
		_CodeSnippet constructorCodeBody = this._makeConstructorCodeBody(node);
		String namedParamsMapForEzflapWidget = this._makeNamedParamsMapForEzflapWidget(node);
		String slotProvidersForEzflapWidget = this._makeSlotProvidersForEzflapWidget(node);
		String interpolatedTextForEzflapWidget = this._makeInterpolatedTextForEzflapWidget(node);
		String modelsMap = this._makeModelsMap(node);
		String onsMap = this._makeOnsMap(node);
		String initLifecycleHandlers = this._makeInitLifecycleHandlers(node);

		return _CodeSnippet(
			code: """
				${constructorCodeBody.code}
				${namedParamsMapForEzflapWidget}
				${slotProvidersForEzflapWidget}
				${interpolatedTextForEzflapWidget}
				${modelsMap}
				${onsMap}
				${initLifecycleHandlers}
			""",
			isPrefixedWithIf: constructorCodeBody.isPrefixedWithIf
		);
	}

	_CodeSnippet _makeConstructorCodeBody(AstNodeConstructor node) {
		if (node.isZBuild()) {
			if (node.zBuilder != null) {
				return _CodeSnippet(
					// we add "!" in the invocation because the zBuilder is not
					// a local variable and so Dart still worries it might be
					// null when accessed the second time...
					// we cast to [dynamic] first because the builder *might*
					// be non-nullable (e.g. if it is returned from an
					// EzComputed or an EzMethod).
					code: """
						if ((${node.zBuilder} as dynamic) != null)
							(${node.zBuilder} as dynamic)!(context)
					""",
					isPrefixedWithIf: true
				);
			}
		}

		return _CodeSnippet(
			code: this._makeConstructorCodeBodyString(node),
			isPrefixedWithIf: false
		);
	}

	String _makeConstructorCodeBodyString(AstNodeConstructor node) {
		if (node.isZBuild()) {
			if (node.zBuild != null) {
				return "${node.zBuild}";
			}

			assert(node.zBuilder == null, "shouldn't get here; [node.zBuilder] should have been handled by _makeConstructorCodeBody()");
		}

		String constructor = node.name;
		if (node.customConstructorName != null) {
			constructor += ".${node.customConstructorName}";
		}

		String orderedParams = this._makeOrderedParams(node);
		String namedParams = this._makeNamedParams(node);

		if (node.isEzflapWidget) {
			return """
				this._ezState.\$instantiateOrMock("${node.name}", () => ${constructor}())
			""";
		}

		return """
			${constructor}(${orderedParams}
				${namedParams}
			)
		""";
	}

	String _makeInitLifecycleHandlers(AstNodeConstructor node) {
		if (node.zRef == null && node.zRefs == null) {
			return "";
		}

		String s = "";

		if (!node.isEzflapWidget) {
			// we only provide props to ezFlap widgets
			// HOWEVER, [z-build] and [z-builder] might evaluate to an ezFlap
			// widget
			if (!node.isZBuild()) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Can only have z-ref and z-refs attributes on ezFlap widgets, but found one on ${node}");
				return "";
			}
		}

		if (node.zRef != null) {
			s = """
				..\$initLifecycleHandlers(
					(ref) => _ref_${node.zRef}.setValue(ref as dynamic),
					(ref) => _ref_${node.zRef}.setValue(null)
				)
			""";
		}
		else if (node.zRefs != null) {
			s = """
				..\$initLifecycleHandlers(
					(ref) => _refs_${node.zRefs}[${node.zRefsKey}] = ref as dynamic,
					(ref) => _refs_${node.zRefs}.remove(${node.zRefsKey})
				)
			""";
		}

		return s;
	}

	String _generateFromNodeConstructorsList(AstNodeConstructorsList node) {
		List<String> arrConstructorsCode = node.arrConstructorNodes.mapToList((x) => this._generateFromNodeConstructorLike(node: x, isInList: true));
		String constructors = arrConstructorsCode.join(", ");
		String code = "[ ${constructors} ]";
		return code;
	}

	String _generateFromNodeMutuallyExclusiveConstructorsList(AstNodeMutuallyExclusiveConstructorsList node) {
		List<String> arrConstructorsCode = node.arrConstructorNodes.mapToList((x) => this._generateFromNodeConstructorLike(node: x, isInList: false));
		String constructors = arrConstructorsCode.join(" : ");
		String fallbackConstructorCode = (node.isNullConstructorAllowed ? "null" : "Container()");
		String code = "${constructors} : ${fallbackConstructorCode}";
		return code;
	}

	String _makeOrderedParams(AstNodeConstructor node) {
		if (node.isEzflapWidget) {
			return "";
		}
			
		String orderedParams = node.arrPositionalParams.mapToList((x) => this._generateFromNode(x)).join(", ");
		if (orderedParams.isNotEmpty) {
			orderedParams += ",";
		}
		return orderedParams;
	}

	String _makeNamedParams(AstNodeConstructor node) {
		if (node.isEzflapWidget) {
			return "";
		}
		
		List<String> arrParts = [ ];
		node.mapNamedParams.forEach((String key, AstNodeBase nodeParam) {
			String valueCode = this._generateFromNode(nodeParam);
			String pairCode = "${key}: ${valueCode}";
			arrParts.add(pairCode);
		});

		arrParts.add(this._makeZKeyParameter(node, surroundKeyNameWithQuotes: false));

		String code = arrParts.where((x) => x.isNotEmpty).join(",");
		return code;
	}

	String _makeZKeyParameter(AstNodeConstructor node, { required bool surroundKeyNameWithQuotes }) {
		if (node.zKey == null) {
			return "";
		}
		String ch = (surroundKeyNameWithQuotes ? "\"" : "");
		return "${ch}key${ch}: Key(\"${node.zKey}\")";
	}

	String _makeNamedParamsMapForEzflapWidget(AstNodeConstructor node) {
		if (!node.isEzflapWidget) {
			// we only provide props to ezFlap widgets
			// HOWEVER, [z-build] and [z-builder] might evaluate to ezFlap
			// widgets, so if the user provided [z-bind] or other stuff on them
			// - we should pass it on.
			if (!node.isZBuild()) {
				return "";
			}
		}

		List<String> arrPartsGrouped = [ ];
		List<String> arrPartsIndividuals = [ ];
		node.mapNamedParams.forEach((String key, AstNodeBase nodeParam) {
			String valueCode = this._generateFromNode(nodeParam);
			String pairCode = "\"${key}\": ${valueCode}";
			AstNodeLiteral? nodeType = this._tryGetTypeNodeFromParamNode(nodeParam);
			if (nodeType == null) {
				// add in "generic" $initProps
				arrPartsGrouped.add(pairCode);
			}
			else {
				// we know the expected type, so we will force it, using
				// initProp(). this is needed to allow the user to provide
				// z-binds like "70" into a prop of type [double] (otherwise
				// Dart assumes it's an int).
				String type = this._generateFromNodeLiteral(nodeType);
				arrPartsIndividuals.add("""
					..initProp<${type}>("${key}", ${valueCode})
				""");
			}
		});

		arrPartsGrouped.add(this._makeZKeyParameter(node, surroundKeyNameWithQuotes: true));

		List<String> arrEffectiveGrouped = arrPartsGrouped.where((x) => x.isNotEmpty).toList();

		String finalCode = "";
		if (arrEffectiveGrouped.isNotEmpty) {
			String code = arrEffectiveGrouped.join(",");
			finalCode = "..\$initProps({ ${code} })";
		}

		if (arrPartsIndividuals.isNotEmpty) {
			String individualProps = arrPartsIndividuals.join("\n");
			finalCode += individualProps;
		}

		return finalCode;
	}

	AstNodeLiteral? _tryGetTypeNodeFromParamNode(AstNodeBase nodeParam) {
		if (nodeParam is! AstNodeZssParameterValue) {
			return null;
		}

		return nodeParam.typeNode;
	}

	String _makeSlotProvidersForEzflapWidget(AstNodeConstructor node) {
		if (node.mapSlotProviders.isEmpty) {
			return "";
		}

		if (!node.isEzflapWidget) {
			// we only provide props to ezFlap widgets
			// HOWEVER, [z-build] and [z-builder] might evaluate to an ezFlap
			// widget
			if (!node.isZBuild()) {
				return "";
			}
		}

		List<String> arrParts = [ ];
		node.mapSlotProviders.forEach((String? key, AstNodeSlotProvider nodeSlotProvider) {
			String valueCode = this._generateFromNode(nodeSlotProvider);

			String sKey = "null";
			if (key != null) {
				sKey = "\"${key}\"";
			}
			String pairCode = "${sKey}: ${valueCode}";
			arrParts.add(pairCode);
		});

		String code = arrParts.join(",");
		String code2 = "..\$initSlotProviders({ ${code} })";

		return code2;
	}

	String _makeInterpolatedTextForEzflapWidget(AstNodeConstructor node) {
		if (node.interpolatedText == null || node.interpolatedText!.isEmpty) {
			return "";
		}

		if (!node.isEzflapWidget) {
			// we only provide props to ezFlap widgets
			// HOWEVER, [z-build] and [z-builder] might evaluate to an ezFlap
			// widget
			if (!node.isZBuild()) {
				return "";
			}
		}

		return """
			..\$setInterpolatedText(${node.interpolatedText})
		""";
	}

	String _makeModelsMap(AstNodeConstructor node) {
		if (node.mapModels.isEmpty) {
			return "";
		}

		if (!node.isEzflapWidget) {
			// note: here we also fail if the node is a ZBuild; ZBuilds don't
			//       support z-model because we need to know the z-model's type,
			//       and it's not available with ZBuild (it can't be determined
			//       in compile time).
			// TODO: reconsider this after refactoring the z-model mechanism to use functions.
			this._svcLogger.logErrorFrom(_COMPONENT, "Can only have z-model attributes on ezFlap widgets, but found one on ${node}");
			return "";
		}

		List<String> arrModelHandlerParts = [ ];
		Map<String, String> map = {
			...(node.mapModels.map((key, modelValue) => MapEntry(key, this._makeModelHandlerSnippet(modelValue, node, false)))),
		};

		map.forEach((String key, String modelValueSnippet) {
			String escapedKey = key.replaceAll("\$", "\\\$");

			String pairCode = "\"${escapedKey}\": ${modelValueSnippet}";

			arrModelHandlerParts.add(pairCode);
		});

		String codeModelHandlers = arrModelHandlerParts.join(",");
		String code = "..\$initModelHandlers({ ${codeModelHandlers} })";

		return code;
	}

	String _makeOnsMap(AstNodeConstructor node) {
		if (node.mapOns.isEmpty) {
			return "";
		}
		
		if (!node.isEzflapWidget) {
			// note: this is not supported for <ZBuild> because we can't get
			//       the referenced @EzEmit in compile time.
			this._svcLogger.logErrorFrom(_COMPONENT, "Can only have z-on attributes on ezFlap widgets, but found one on ${node}");
			return "";
		}
		
		List<String> arrParts = [ ];
		node.mapOns.forEach((String key, String value) {
			String valueCode = this._makeOnValueCode(node, key, value);
			String pairCode = "\"${key}\": ${valueCode}";
			arrParts.add(pairCode);
		});

		String code = arrParts.join(",");
		String code2 = "..\$initEmitHandlers({ ${code} })";
		
		return code2;
	}

	String _makeOnValueCode(AstNodeConstructor node, String key, String value) {
		/// z-on has two variations:
		///
		/// 1. without parentheses. e.g. [z-on:click="onClick"].
		///    in this case, the onClick EzMethod will be invoked, and is
		///    expected to have exactly the same parameters as the emitter.
		///
		/// 2. with parentheses. e.g. [z-on:click="onClickedItem(item)"].
		///    in this case, the parameters passed from the emitter are
		///    ignored.

		if (value.contains("(")) {
			// has parameters. we need to get the emitter's signature.
			// first - we find the Widget referenced by the current node.
			EzflapWidgetsReflector ezflapWidgetsReflector = EzflapWidgetsReflector();
			EzflapWidgetDescriptor? ezflapWidgetDescriptor = ezflapWidgetsReflector.getUsedWidgetDataForWidgetClass(node.name);
			if (ezflapWidgetDescriptor == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Could not find reference for widget ${node}. Did you remember to import it??");
				return "() => { }";
			}

			String? functionParenthesesPart = ezflapWidgetDescriptor.mapEzEmitFunctionParenthesesParts[key];
			if (functionParenthesesPart == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, """\n
					Could not find corresponding EzEmit with name [${key}] in ${node}.
					
					** THIS COULD SOMETIMES HAPPEN IN THE FIRST BUILD **
					** IF IT DOES NOT REPRODUCE WHEN THE BUILD WATCHER RE-BUILDS - THEN IT CAN BE SAFELY IGNORE **
					
					Make sure that the return type of the 'createState' function in ${node.name} is '${node.name}State'.
					If everything is correct, then this may be a bug in the Dart analyzer package.
					You can switch to the alternative [z-on] syntax, where the handler method is specified without parentheses.
					For example, instead of:
						z-on:change="onChanged()"
					Do:
						z-on:change="onChanged"
					If you need the parentheses syntax (e.g. to pass loop-dependent data to the handler) then,
					in case the problematic widget is extending another widget - try to eliminate the inheritance
					relationship (inheritance is known to cause this issue in some cases; this will be investigated
					and probably handled better in a future ezFlap version).
				""");
				return "() => { }";
			}

			return """
				${functionParenthesesPart} => ${value}
			""";
		}
		else {
			// no parameters
			return value;
		}
	}

	String _makeModelHandlerSnippet(AstNodeModelValue modelValue, AstNodeConstructor node, bool useDummyModelIfNotProvidedByHostWidget) {
		String fullValueLiteral = modelValue.fullValueLiteral;
		int len = fullValueLiteral.length;
		if (fullValueLiteral.endsWith("!")) {
			// exclude the '!' in the setter (because having it is invalid syntax)
			len--;
		}

		String typeLiteral = modelValue.typeLiteral;
		if (typeLiteral == "dynamic") {
			// try to figure out the type from an EzField
			EzFieldDataBase? fieldData = this._tryGetFieldDataByAssignedName(fullValueLiteral);
			if (fieldData != null) {
				typeLiteral = fieldData.typeWithNullability;
			}
		}

		String setModelValueLiteral = fullValueLiteral.substring(0, len);
		return """
			\$ModelHandler<${typeLiteral}>(
				funcGetModelValue: () => ${fullValueLiteral},
				funcSetModelValue: (${typeLiteral} _\$value) {
					${setModelValueLiteral} = _\$value;
				}
			)
		""";
	}

	EzFieldDataBase? _tryGetFieldDataByAssignedName(String assignedName) {
		return this._annotationsSummary.mapFieldsData[assignedName];
	}

	String _makePriorityConditionClause(AstNodeConstructor node) {
		if (node.priorityConditionLiteral == null) {
			return "";
		}
		return "if (${node.priorityConditionLiteral})";
	}

	String _makeConditionClause({ required AstNodeConstructor node, required bool isInList }) {
		if (node.conditionLiteral == null) {
			return "";
		}
		if (isInList) {
			return "if (${node.conditionLiteral})";
		}
		else {
			return "(${node.conditionLiteral}) ? ";
		}
	}

	String _makeConditionClauseTernary(AstNodeConstructor node) {
		if (node.conditionLiteral == null) {
			return "";
		}
		return "(${node.conditionLiteral})";
	}

	String _wrapWithVisibilityIfNeeded(AstNodeConstructor node, String constructorCode) {
		if (node.visibilityConditionLiteral == null) {
			return constructorCode;
		}

		return """
			Visibility(
				child: ${constructorCode},
				maintainState: true,
				visible: ${node.visibilityConditionLiteral},
			)
		""";
	}
	
	String _wrapWithTernaryIfNeeded(AstNodeConstructor node, String constructorCode) {
		if (node.conditionLiteral == null) {
			return constructorCode;
		}
		
		return """
			((${node.conditionLiteral}) ? (${constructorCode}) : null)
		""";
	}

	String _wrapWithForIfNeeded(AstNodeConstructor node, String constructorCode) {
		assert(node.zFor != null);
		ZFor zFor = node.zFor!;
		String collectionExpr = zFor.collectionExpr;

		String iterKeyOrIdx = zFor.iterKeyOrIdx ?? "_\$1";
		String? iterKey = zFor.iterKey;

		if (zFor.iterKey == null) {
			// only two parameters were provided to z-for, so treat iterKeyOrIdx
			// as the key. i.e.:
			//  z-for="(key, value) in collection"
			//  OR
			//  z-for="value in collection"
			iterKey = iterKeyOrIdx; // i.e. the [key] if in "two parameters mode" and "_$" if we are not.
			iterKeyOrIdx = "_\$2";
		}

		String iterValue = zFor.iterValue;
		return """
			...\$EzStateBase.\$autoMapper(${collectionExpr}, (${iterValue}, ${iterKey}, ${iterKeyOrIdx}) => ${constructorCode})
		""";
	}

	String _generateFromNodeSlotProvider(AstNodeSlotProvider node) {
		String name = "null";
		if (node.name != null) {
			name = "\"${node.name}\"";
		}

		String constructorsListCode = this._generateFromNodeConstructorsList(node.childList);
		String scopeName = node.scope ?? "_";
		return """
			\$SlotProvider(
				name: ${name},
				funcBuild: (dynamic ${scopeName}) {
					return ${constructorsListCode};
				}
			)
		""";
	}

	String _generateFromNodeZssParameterValue(AstNodeZssParameterValue node) {
		if (node.arrSelectorNodes == null || node.arrSelectorNodes!.isEmpty) {
			return this._generateFromNode(node.valueNode);
		}

		bool alreadyFoundOneWithoutConditions = false;
		List<String> arrParts = [ ];
		for (AstNodeZssSelector nodeZssSelector in node.arrSelectorNodes!) {
			if (nodeZssSelector.hasConditions()) {
				assert(!alreadyFoundOneWithoutConditions, "only the last selector in AstNodeZssParameterValue.arrSelectorNodes is allowed to be unconditional.");
				arrParts.add(this._generateFromNodeZssSelectorAsCondition(nodeZssSelector));
			}
			else {
				alreadyFoundOneWithoutConditions = true;
				arrParts.add(this._generateFromNodeZssSelectorAsUnconditional(nodeZssSelector));
			}
		}

		if (!alreadyFoundOneWithoutConditions) {
			// no certain selector, so we will use the provided default value
			arrParts.add(this._generateFromNode(node.valueNode));
		}

		String code = arrParts.join(" ");
		return code;
	}
	
	String _generateFromNodeZssSelectorAsCondition(AstNodeZssSelector node) {
		assert(node.hasConditions());

		String condition = node.arrConditionNodes.map((x) => this._generateFromNodeZssCondition(x)).join(" && ");
		String zssStyleFuncCall = this._makeZssStyleFuncCall(node);
		return """
			${condition} ? ${zssStyleFuncCall} :
		""";
	}

	String _generateFromNodeZssSelectorAsUnconditional(AstNodeZssSelector node) {
		assert(!node.hasConditions());
		return this._makeZssStyleFuncCall(node);
	}

	String _generateFromNodeZssCondition(AstNodeZssCondition node) {
		String? conditionForClasses = this._generateFromNodeZssConditionForClassesIfNeeded(node);
		String? conditionForAttrs = this._generateFromNodeZssConditionForAttrsIfNeeded(node);
		assert(conditionForClasses != null || conditionForAttrs != null);

		List<String> arrCondition = [ conditionForClasses, conditionForAttrs ].filterNull().denull().toList(growable: false);
		String code = "(" + arrCondition.join(" && ") + ")";
		return code;
	}

	String? _generateFromNodeZssConditionForAttrsIfNeeded(AstNodeZssCondition node) {
		if (node.arrZssConditionAttrNodes == null) {
			return null;
		}

		assert(node.arrZssConditionAttrNodes!.isNotEmpty);

		String code = node.arrZssConditionAttrNodes!.map((x) => this._generateFromNodeZssConditionAttr(x)).join(" && ");
		return "(${code})";
	}

	String _generateFromNodeZssConditionAttr(AstNodeZssConditionAttr node) {
		AstNodeBase? valueNode = node.actualValueLiteralNode ?? node.actualValueStringWithMustacheNode;
		if (valueNode == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "invalid AstNodeZssConditionAttr: ${node} (this is probably an ezFlap bug)");
			return "";
		}

		String literal = this._generateFromNode(valueNode);
		return """
			\$EzStateBase.\$testAttr(${node.expectedValue}, ${literal})
		""";
	}

	String? _generateFromNodeZssConditionForClassesIfNeeded(AstNodeZssCondition node) {
		if (node.arrExpectedClasses == null) {
			return null;
		}

		assert(node.arrExpectedClasses!.isNotEmpty);
		assert(node.actualClassesNode != null);

		String actualSetSnippet = node.actualClassesNode!.value;
		String expectedSetContentSnippet = "\"" + node.arrExpectedClasses!.join("\", \"") + "\"";

		return """
			${actualSetSnippet}.containsAll({ ${expectedSetContentSnippet} })
		""";
	}

	String _makeZssStyleFuncCall(AstNodeZssSelector node) {
		String zssStyleFuncName = this._makeZssStyleFuncName(node.zssStyleNodeRef);
		return """
			${zssStyleFuncName}()
		""";
	}
}