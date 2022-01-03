
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzModel/EzModelVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzOptionalModel/EzOptionalModelVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzProp/EzPropVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ClassDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ConstructorDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ParameterDescriptor/ParameterDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/SvcReflector_.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zss/Matcher/ApplicableZssRule/ApplicableZssRule.dart';
import 'package:ezflap/src/Service/Zss/Matcher/ApplicableZssSelectorPart/ApplicableZssSelectorPart.dart';
import 'package:ezflap/src/Service/Zss/Matcher/ParameterApplicableZss/ParameterApplicableZss.dart';
import 'package:ezflap/src/Service/Zss/Parser/AttrCondition/ZssAttrCondition.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

class _SimpleConstructorParamInfo {
	final bool isList;
	final bool isNullable;

	_SimpleConstructorParamInfo({
		required this.isList,
		required this.isNullable,
	});
}

const String _INTEROP_CONSTRUCTOR_NAME = "\$ezFlapFactory";

class SvcZmlCompiler extends EzServiceBase {
	static SvcZmlCompiler i() { return Singleton.get(() => SvcZmlCompiler()); }

	SvcLogger get _svcLogger => SvcLogger.i();
	SvcReflector get _svcReflector => SvcReflector.i();

	static const String _COMPONENT = "SvcZmlCompiler";

	AstNodeWrapper? tryGenerateAst(Tag rootTag) {
		if (!this._verifyRootTag(rootTag)) {
			return null;
		}

		AstNodeConstructor? rootConstructorNode = this._generateConstructorNode(rootTag);
		if (rootConstructorNode == null) {
			return null;
		}

		Map<int, AstNodeZssStyle> mapZssStyleNodes = this._generateZssStyleNodes(rootTag);

		return AstNodeWrapper(
			rootConstructorNode: rootConstructorNode,
			mapZssStyleNodes: mapZssStyleNodes,
		);
	}

	bool _verifyRootTag(Tag rootTag) {
		if (rootTag.isTypeGroup()) {
			this._svcLogger.logErrorFrom(_COMPONENT, "A top-level tag in a Widget cannot be <${Tag.TAG_Z_GROUP}>");
			return false;
		}

		if (rootTag.zIf != null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "[z-if] on root tags is not allowed. Affected root tag: ${rootTag}");
			return false;
		}

		return true;
	}
	
	Map<int, AstNodeZssStyle> _generateZssStyleNodes(Tag rootTag) {
		Map<int, AstNodeZssStyle> mapStyleNodes = { };

		List<Tag> arrTags = rootTag.collectDescendantsAndSelf();
		for (Tag tag in arrTags) {
			for (MapEntry<String, ParameterApplicableZss> kvp in tag.mapZssToParams.entries) {
				for (ApplicableZssRule rule in kvp.value.arrApplicableRules) {
					int uid = rule.styleRootTag.uid;
					if (mapStyleNodes.containsKey(uid)) {
						//this._svcLogger.logErrorFrom(_COMPONENT, "ZSS styling tag: ${rule.styleRootTag} does not have a unique uid. This looks like an ezFlap bug.");
						// this style has already been created. we can get here if the same style is applied to multiple tags.
						// note that we assume that all such tags are of the type; this is important, because the same style
						// tag may generate different code, depending on whether it's applied for a parameter that is a List
						// or not. this is probably a very, very edgy case, because two different tags would need to have the
						// same parameter name, accepting the same style, but with one of them being a list. in the future we
						// may add detection for this case, or force to include the name (i.e. class) of the tags to which
						// the rule can apply.
						// UPDATE: we now force a tag name in the last selector part so this is no longer an issue.
						continue;
					}


					// we need rule.styleRootTag.tag.parent to point at the tag for which the style will be applied, so that
					// _tryMakeNodeFromParameterTag(), or more precisely _isConstructorParamOfTypeList() - will be able to
					// check if the parameter is a List or not.
					assert(rule.styleRootTag.tag.parent == null);
					rule.styleRootTag.tag.parent = tag;
					AstNodeBase? styleNode = this._tryMakeNodeFromParameterTag(rule.styleRootTag.tag);
					rule.styleRootTag.tag.parent = null;


					if (styleNode == null) {
						this._svcLogger.logErrorFrom(_COMPONENT, "Failed to create AST node from ZSS styling tag: ${rule.styleRootTag}");
						continue;
					}

					AstNodeLiteral? typeNode = this._getTypeLiteral(tag, kvp.key);
					if (typeNode == null) {
						this._svcLogger.logErrorFrom(_COMPONENT, "Failed to create AST node from ZSS styling tag's type: tag: ${tag}, param: ${kvp.key}, styling tag: ${rule.styleRootTag}");
						continue;
					}

					AstNodeZssStyle zssStyleNode = AstNodeZssStyle(
						styleUid: rule.styleRootTag.uid,
						styleNode: styleNode,
						typeNode: typeNode,
					);
					mapStyleNodes[uid] = zssStyleNode;
				}
			}
		}

		return mapStyleNodes;
	}

	AstNodeLiteral? _getTypeLiteral(Tag tagOfConstructor, String parameterName, { bool logErrorsIfNotFound = true }) {
		String className = tagOfConstructor.name;
		String? constructorName = tagOfConstructor.zCustomConstructorName;
		ClassDescriptor? classDescriptor = this._svcReflector.describeClass(className);
		if (classDescriptor == null) {
			return null;
		}

		if (classDescriptor.isEzflapWidget) {
			// it's an ezFlap widget. get by prop.
			EzPropVisitor ezPropVisitor = this._getOrMakeEzPropVisitorForClassDescriptor(classDescriptor);
			EzPropData? ezPropData = ezPropVisitor.tryGetEzPropData(parameterName);
			if (ezPropData == null) {
				return null;
			}

			return AstNodeLiteral(ezPropData.typeWithNullability);
		}
		else {
			ParameterDescriptor? desc = this._svcReflector.describeNamedOrPositionalParameter(className, constructorName, parameterName, logErrorsIfNotFound);
			if (desc == null) {
				return null;
			}

			return AstNodeLiteral(desc.typeLiteral);
		}
	}

	String? _makeConditionExpressionIfNeeded(List<String> arrClauses) {
		if (arrClauses.isEmpty) {
			return null;
		}
		String middle = arrClauses.join(") && (");
		String full = "((${middle}))";
		return full;
	}
	
	AstNodeConstructor? _generateConstructorNode(Tag tag, [ List<String> arrAdditionalZIfClauses = const [ ], List<String> arrAdditionalZShowClauses = const [ ] ]) {
		if (tag.isNamedChildTag) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Expected a Widget tag; got ${tag}.");
			return null;
		}

		Map<String, AstNodeZssParameterValue> mapNamedParams = this._makeNamedParamsNodes(tag);
		List<AstNodeZssParameterValue>? arrPositionalParams = this._makePositionalParamNodes(tag);
		if (arrPositionalParams == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "One or more positional parameters are missing in ${tag}.");
			return null;
		}

		Map<String, AstNodeModelValue> mapModels = this._makeModelsMap(tag);
		Map<String, String> mapOns = this._makeOnsMap(tag);
		Map<String?, AstNodeSlotProvider> mapSlotProviders = this._makeSlotProviders(tag);
		String? priorityConditionLiteral = this._makeConditionExpressionIfNeeded(arrAdditionalZIfClauses);
		String? zShow = this._calculateZShowAttribute(tag, arrAdditionalZShowClauses);
		String? effectiveCustomConstructorName = this._getEffectiveCustomConstructorName(tag);
		if (!this._verifyBuildBuilderStateOrLogError(tag)) {
			return null;
		}
		if (!this._verifyNoDuplicatesOrLogError(tag, mapNamedParams)) {
			return null;
		}

		bool isEzflapWidget = !tag.isTypeSpecialKeywordTag() && this._isEzflapWidget(tag);
		AstNodeConstructor astNodeConstructor = AstNodeConstructor(
			name: tag.name,
			customConstructorName: effectiveCustomConstructorName,
			mapNamedParams: mapNamedParams,
			arrPositionalParams: arrPositionalParams,
			mapModels: mapModels,
			mapOns: mapOns,
			mapSlotProviders: mapSlotProviders,
			priorityConditionLiteral: priorityConditionLiteral,
			conditionLiteral: tag.zIf,
			visibilityConditionLiteral: zShow,
			zFor: tag.zFor,
			isEzflapWidget: isEzflapWidget,
			useInheritingWidget: tag.isTypeInheritingWidget(),
			zRef: tag.zRef,
			zRefs: tag.zRefs,
			zRefsKey: tag.zRefsKey,
			zBuild: tag.zBuild,
			zBuilder: tag.zBuilder,
			zKey: tag.zKey,
			interpolatedText: tag.interpolatedText,
		);
		
		this._applyZssStylesToTag(tag, astNodeConstructor);
		
		return astNodeConstructor;
	}
	
	String? _getEffectiveCustomConstructorName(Tag tag) {
		String? customConstructorName = tag.zCustomConstructorName;
		if (tag.isTypeSpecialKeywordTag()) {
			return customConstructorName;
		}

		ClassDescriptor? classDescriptor = this._svcReflector.describeClass(tag.name);
		if (classDescriptor == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Cannot find the class corresponding to tag [${tag}]. Did you remember to import its library?");
			return customConstructorName;
		}

		if (!classDescriptor.isEzflapWidget) {
			return customConstructorName;
		}

		ConstructorDescriptor? constructorDesc = this._svcReflector.describeConstructor(classDescriptor, _INTEROP_CONSTRUCTOR_NAME);
		return constructorDesc?.name ?? customConstructorName;
	}

	Map<String?, AstNodeSlotProvider> _makeSlotProviders(Tag tagParent) {
		bool isEzflapWidgetOrZBuild = tagParent.isTypeBuild();
		if (tagParent.isTypeSpecialKeywordTag() && !isEzflapWidgetOrZBuild) {
			// we don't have slot providers in ezflap tags (i.e. ZGroup, etc..),
			// except for ZBuild (because it might be an ezFlap widget).
			return { };
		}

		if (!isEzflapWidgetOrZBuild) {
			// not a ZBuild. check if it's an ezFlap widget
			ClassDescriptor? classDescriptor = this._svcReflector.describeClass(tagParent.name);
			if (classDescriptor == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Cannot find the class corresponding to tag [${tagParent}]. Did you remember to import its library?");
				return { };
			}

			isEzflapWidgetOrZBuild = classDescriptor.isEzflapWidget;
		}

		Map<String?, AstNodeSlotProvider> map = { };
		for (Tag tag in tagParent.arrUnnamedChildren) {
			if (tag.isTypeSlotProvider()) {
				if (!isEzflapWidgetOrZBuild) {
					this._svcLogger.logErrorFrom(_COMPONENT, "Tag [${tagParent}] is not an ezFlap widget and so cannot have ZSlotProvider tags.");
					continue;
				}

				AstNodeSlotProvider? node = this._generateProviderSlotNode(tag);
				if (node == null) {
					continue;
				}
				map[tag.zName] = node;
			}
		}

		if (isEzflapWidgetOrZBuild) {
			AstNodeSlotProvider? slotProviderNode = this._generateImplicitDefaultSlotProviderNode(tagParent);
			if (slotProviderNode != null) {
				map[null] = slotProviderNode;
			}
		}

		return map;
	}

	String? _calculateZShowAttribute(Tag tag, List<String> arrAdditionalZShowClauses) {
		String? zShow = tag.zShow;
		String? additionalVisibilityConditionLiteral = this._makeConditionExpressionIfNeeded(arrAdditionalZShowClauses);
		if (additionalVisibilityConditionLiteral != null) {
			if (zShow == null) {
				zShow = additionalVisibilityConditionLiteral;
			}
			else {
				zShow = "((${additionalVisibilityConditionLiteral}) && (${zShow}))";
			}
		}
		return zShow;
	}

	bool _verifyNoDuplicatesOrLogError(Tag tag, Map<String, AstNodeZssParameterValue> mapNamesParams) {
		if (mapNamesParams.containsKey("key") && tag.zKey != null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} has both a [key] named parameter and a [z-key] attribute. They are mutually-exclusive.");
			return false;
		}

		return true;
	}

	bool _verifyBuildBuilderStateOrLogError(Tag tag) {
		bool hasBuildAttrs = (tag.zBuild != null || tag.zBuilder != null);

		if (tag.isTypeBuild() && !hasBuildAttrs) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} must have either a [z-build] or a [z-builder] attribute.");
			return false;
		}

		if (!tag.isTypeBuild() && hasBuildAttrs) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} does not support the [z-build] and [z-builder] attribute (only <${Tag.TAG_Z_BUILD}> supports them).");
			return false;
		}

		if (tag.zBuild != null && tag.zBuilder != null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} has both [z-build] and [z-builder] attributes. [z-build] and [z-builder] are mutually-exclusive.");
			return false;
		}

		return true;
	}

	bool _isEzflapWidget(Tag tag) {
		ClassDescriptor? classDescriptor = this._tryGetClassDescriptor(tag.name);
		if (classDescriptor == null) {
			return false;
		}
		return classDescriptor.isEzflapWidget;
	}

	Map<String, AstNodeZssParameterValue> _makeNamedParamsNodes(Tag tag) {
		Map<String, AstNodeZssParameterValue> map = { };
		this._applyNamedParametersFromChildren(map, tag);
		this._applyNamedParametersFromAttributes(map, tag);
		return map;
	}

	ClassDescriptor? _tryGetClassDescriptor(String className) {
		ClassDescriptor? classDescriptor = this._svcReflector.describeClass(className);
		if (classDescriptor == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Class descriptor not found for class: [${className}]");
			return null;
		}

		return classDescriptor;
	}

	_SimpleConstructorParamInfo? _getSimpleConstructorParamInfo(Tag tagOfNamedChild) {
		Tag tagClass = tagOfNamedChild.parent!;
		String className = tagClass.name;
		String? customConstructorName = tagClass.zCustomConstructorName;
		String parameterName = tagOfNamedChild.name;

		ClassDescriptor? classDescriptor = this._tryGetClassDescriptor(className);
		if (classDescriptor == null) {
			return null;
		}

		bool isList;
		bool isNullable;
		if (classDescriptor.isEzflapWidget) {
			// handle as ezflap widget
			EzPropVisitor ezPropVisitor = this._getOrMakeEzPropVisitorForClassDescriptor(classDescriptor);

			EzPropData? ezPropData = ezPropVisitor.tryGetEzPropData(parameterName);
			if (ezPropData == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Cannot find prop [${parameterName}] on ezFlap widget [${className}].");
				return null;
			}

			isList = ezPropData.isList;
			isNullable = ezPropData.isNullable;
		}
		else {
			int? paramIdx = this._tryGetPositionalParameterPositionFromName(parameterName);

			// handle as a native class
			ParameterDescriptor? parameterDescriptor;
			if (paramIdx == null) {
				parameterDescriptor = this._svcReflector.describeNamedParameter(className, customConstructorName, parameterName);
			}
			else {
				parameterDescriptor = this._svcReflector.tryDescribePositionalParameter(className, customConstructorName, paramIdx);
			}

			if (parameterDescriptor == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Parameter descriptor not found for class: [${className}], parameter: [${parameterName}]");
				return null;
			}

			isList = parameterDescriptor.isList;
			isNullable = parameterDescriptor.isNullable;
		}

		return _SimpleConstructorParamInfo(
			isList: isList,
			isNullable: isNullable,
		);
	}

	void _applyNamedParametersFromChildren(Map<String, AstNodeZssParameterValue> map, Tag tagToProcess) {
		var arr = tagToProcess.mapNamedChildren.values;
		for (Tag tag in arr) {
			if (!tag.isNamedChildTag) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Expected tag ${tag} to be a named prop tag (this may be an ezFlap bug)");
				continue;
			}

			if (!this._doesTagLookLikeNamedParameter(tag.name)) {
				continue;
			}

			AstNodeBase? node = this._tryMakeNodeFromParameterTag(tag);
			if (node == null) {
				continue;
			}

			String propName = tag.name;
			map[propName] = AstNodeZssParameterValue.simple(node);
		}
	}

	/// - [tag] is the Tag for which parameters need to be added according to
	///   the ZSS rules applied to it.
	/// - [node] is the [AstNodeConstructor] that had been generated for [tag].
	///   it is already populated with the named and positional parameters.
	///   this function will also add the ZSS styles to it (for all of the
	///   styling parameters that do not yet exist in the node; because if a
	///   parameter is in the node, then it was explicitly supplied in the ZML,
	///   and thus should override whatever comes from the ZSS).
	void _applyZssStylesToTag(Tag tag, AstNodeConstructor node) {
		if (tag.mapZssToParams.isEmpty) {
			// no ZSS rules (i.e. selectors) apply to this tag
			return;
		}
		
		for (MapEntry<String, ParameterApplicableZss> kvp in tag.mapZssToParams.entries) {
			String paramNameOrIdx = kvp.key;
			if (this._doesConstructorNodeHaveNamedOrPositionalParam(node, paramNameOrIdx)) {
				// this parameter already exists (from the ZML), so skip.
				continue;
			}

			// add!
			ParameterApplicableZss parameterApplicableZss = kvp.value;
			List<ApplicableZssRule> arrSortedApplicableRules = parameterApplicableZss.arrApplicableRules.sortByNumeric((x) => x.specificity, true);

			List<AstNodeZssSelector>? arrSelectorNodes;
			if (arrSortedApplicableRules.isNotEmpty) {
				arrSelectorNodes = arrSortedApplicableRules.mapToList((ApplicableZssRule applicableZssRule) {
					List<AstNodeZssCondition> arrConditionNodes = applicableZssRule.arrApplicableSelectorParts.mapToList((ApplicableZssSelectorPart applicableSelectorPart) {
						List<String>? arrExpectedClasses;
						AstNodeLiteral? actualClassesNode;
						ZssSelectorPart selectorPart = applicableSelectorPart.selectorPart;
						Tag appliedForTag = applicableSelectorPart.appliedForTag;
						if (selectorPart.setClasses != null) {
							arrExpectedClasses = selectorPart.setClasses!.toList(growable: false);
							String? attrClass = appliedForTag.attrClass;
							if (attrClass == null) {
								this._logBugErrorForTagAndStylingTag("Found a null attrClass in tag for which ZSS styling with dynamic-classes is applied.", tag, applicableSelectorPart.appliedForTag);
							}
							else {
								actualClassesNode = AstNodeLiteral(attrClass);
							}
						}

						List<AstNodeZssConditionAttr>? arrConditionAttrNodes;
						if (selectorPart.mapAttrConditions != null) {
							arrConditionAttrNodes = selectorPart.mapAttrConditions!.values
								.mapToList((ZssAttrCondition? zssAttrCondition) {
									if (zssAttrCondition == null) {
										// should not get here because attribute-existence-based are determined
										// in build time.
										this._logBugErrorForTagAndStylingTag("Found an unexpected attribute-existence-based condition.", tag, appliedForTag);
										return null;
									}

									// find the z-attr for this attribute. it must exist, because
									// otherwise this condition would not be added by SvcZssMatcher.
									String attrName = zssAttrCondition.name;
									bool hasAsZAttr = appliedForTag.mapZAttrs.containsKey(attrName);
									bool hasAsUnprefixed = appliedForTag.mapStrings.containsKey(attrName);
									if (!hasAsZAttr && !hasAsUnprefixed) {
										this._logBugErrorForTagAndStylingTag("Could not find an expected z-attr/unprefixed attribute [${attrName}].", tag, appliedForTag);
										return null;
									}

									AstNodeLiteral? actualValueLiteralNode;
									AstNodeStringWithMustache? actualValueStringWithMustacheNode;

									if (hasAsZAttr) {
										String? zAttrValue = appliedForTag.mapZAttrs[attrName];
										if (zAttrValue != null) {
											actualValueLiteralNode = AstNodeLiteral(zAttrValue);
										}
									}
									else if (hasAsUnprefixed) {
										String? unprefixedAttributeValue = appliedForTag.mapStrings[attrName];
										if (unprefixedAttributeValue != null) {
											actualValueStringWithMustacheNode = AstNodeStringWithMustache(unprefixedAttributeValue);
										}
									}
									
									AstNodeZssConditionAttr zssConditionNode = AstNodeZssConditionAttr(
										expectedValue: zssAttrCondition.value,
										actualValueLiteralNode: actualValueLiteralNode,
										actualValueStringWithMustacheNode: actualValueStringWithMustacheNode,
									);
									return zssConditionNode;
								})
								.filterNull()
								.denull()
								.toList(growable: false)
							;

							if (arrConditionAttrNodes.isEmpty) {
								// shouldn't happen, but might in case of a bug
								// (for which an error would be logged in the
								// code above).
								arrConditionAttrNodes = null;
							}
						}
						
						AstNodeZssCondition condition = AstNodeZssCondition(
							arrExpectedClasses: arrExpectedClasses,
							actualClassesNode: actualClassesNode,
							arrZssConditionAttrNodes: arrConditionAttrNodes,
						);
						return condition;
					});

					AstNodeZssSelector selectorNode = AstNodeZssSelector(
						arrConditionNodes: arrConditionNodes,
						zssStyleNodeRef: applicableZssRule.styleRootTag.uid,
					);
					return selectorNode;
				});
			}
			
			if (arrSelectorNodes == null) {
				continue;
			}
			
			// we prepared all selectors, and now we need to get the default
			// value for the constructor's parameter (or, in the case of an
			// ezFlap widget - for the referenced @EzProp).
			String? defaultValueLiteral = this._tryGetDefaultValueOfConstructorParameter(tag, paramNameOrIdx);
			this._applyAstNodeZssParameterValueToAstNodeConstructor(
				constructorNode: node,
				paramNameOrIdx: paramNameOrIdx,
				arrSelectorNodes: arrSelectorNodes,
				defaultValueLiteral: defaultValueLiteral
			);
		}
	}

	void _applyAstNodeZssParameterValueToAstNodeConstructor({
		required AstNodeConstructor constructorNode,
		required String paramNameOrIdx,
		required List<AstNodeZssSelector> arrSelectorNodes,
		required String? defaultValueLiteral
	}) {
		AstNodeBase defaultValueNode;
		if (defaultValueLiteral == null) {
			defaultValueNode = AstNodeNull();
		}
		else {
			defaultValueNode = AstNodeLiteral(defaultValueLiteral);
		}
		
		AstNodeZssParameterValue paramNode = AstNodeZssParameterValue(
			arrSelectorNodes: arrSelectorNodes,
			valueNode: defaultValueNode,
			typeNode: null,
		);
		
		int? idx = int.tryParse(paramNameOrIdx);
		if (idx == null) {
			if (constructorNode.mapNamedParams.containsKey(paramNameOrIdx)) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Constructor AST node already has named parameter [${paramNameOrIdx}]. Constructor AST node: ${constructorNode}. This looks like an ezFlap bug.");
				return;
			}

			constructorNode.mapNamedParams[paramNameOrIdx] = paramNode;
		}
		else {
			int len = constructorNode.arrPositionalParams.length;
			if (len != idx) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Constructor AST node's arrPositionalParams has length [${len}] but a length of [${idx}] was expected. This looks like an ezFlap bug.");
				return;
			}

			constructorNode.arrPositionalParams.add(paramNode);
		}
	}

	/// - null is actually a valid return value, so the caller has no way of
	///   knowing whether the default value was found. however, if not found,
	///   then this function logs an error.
	/// - this function behaves differently depending on whether the tag
	///   represents an ezFlap widget or not.
	///   - if an ezFlap widget - the default value is taken from the relevant
	///     @EzProp.
	///   - otherwise - the default value is retrieved with reflection.
	String? _tryGetDefaultValueOfConstructorParameter(Tag tag, String paramNameOrIdx) {
		String className = tag.name;
		String? constructorName = tag.zCustomConstructorName;
		ClassDescriptor? classDescriptor = this._svcReflector.describeClass(className);
		if (classDescriptor == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Could not find a class corresponding to tag: ${tag}");
			return null;
		}
		
		if (classDescriptor.isEzflapWidget) {
			// get from @EzProps
			EzPropVisitor ezPropVisitor = this._getOrMakeEzPropVisitorForClassDescriptor(classDescriptor);
			EzPropData? ezPropData = ezPropVisitor.tryGetEzPropData(paramNameOrIdx);
			if (ezPropData == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Could not find an @EzProp corresponding to [${paramNameOrIdx}] in tag: ${tag}");
				return null;
			}
			
			return ezPropData.defaultValueLiteral;
		}
		else {
			// get with reflection
			ParameterDescriptor? parameterDescriptor = this._svcReflector.describeNamedOrPositionalParameter(className, constructorName, paramNameOrIdx);
			if (parameterDescriptor == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Could not find a parameter corresponding to [${paramNameOrIdx}] in tag: ${tag}");
				return null;
			}
			
			return parameterDescriptor.defaultValueLiteral;
		}
	}
	
	Map<ClassDescriptor, EzPropVisitor> _mapEzPropVisitorsForClassDescriptors = { };
	EzPropVisitor _getOrMakeEzPropVisitorForClassDescriptor(ClassDescriptor classDescriptor) {
		assert(classDescriptor.isEzflapWidget);
		if (this._mapEzPropVisitorsForClassDescriptors.containsKey(classDescriptor)) {
			return this._mapEzPropVisitorsForClassDescriptors[classDescriptor]!;
		}
		
		EzPropVisitor ezPropVisitor = EzPropVisitor();

		assert(classDescriptor.stateClassElement != null);
		ezPropVisitor.visitAll(classDescriptor.getStateClassElementAndUp());

		this._mapEzPropVisitorsForClassDescriptors[classDescriptor] = ezPropVisitor;
		
		return ezPropVisitor;
	}
	
	void _logBugErrorForTagAndStylingTag(String message, Tag tag, Tag appliedToTag) {
		this._svcLogger.logErrorFrom(_COMPONENT, "${message} This looks like an ezFlap bug. The tag referenced by the conditional ZSS style is: ${appliedToTag}.");
	}

	bool _doesConstructorNodeHaveNamedOrPositionalParam(AstNodeConstructor node, String paramName) {
		int? idx = int.tryParse(paramName);
		if (idx == null) {
			return node.mapNamedParams.containsKey(paramName);
		}
		else {
			return (node.arrPositionalParams.length > idx);
		}
	}

	bool _doesTagLookLikeNamedParameter(String name) {
		return !this._doesTagLookLikePositionalParameter(name);
	}

	bool _doesTagLookLikePositionalParameter(String name) {
		int? pos = this._tryGetPositionalParameterPositionFromName(name);
		return (pos != null);
	}
	
	int? _tryGetPositionalParameterPositionFromName(String name) {
		String effectiveName = name;
		if (name.startsWith(SvcZmlParser.CHILD_TAG_POSITIONAL_PARAMETER_PREFIX)) {
			effectiveName = name.substring(1, name.length);
		}

		int? pos = int.tryParse(effectiveName);
		return pos;
	}

	AstNodeBase? _tryMakeNodeFromParameterTag(Tag tag) {
		AstNodeBase? node;
		if (tag.arrUnnamedChildren.isEmpty) {
			// use text (or null)
			// we use literal because it allows stuff like "Colors.red" to
			// be applied via ZSS (i.e. and not only with z-literal
			// attributes. so to pass strings, the user will need to
			// manually add surrounding quotes.
			String literal = tag.text;
			if (literal.isEmpty) {
				literal = "null";
			}

			return AstNodeLiteral(literal);
		}

		// use children
		List<AstNodeConstructorLike> arrConstructors = this._flattenTagsIntoConstructors(tag.arrUnnamedChildren);
		if (arrConstructors.isEmpty) {
			return null;
		}

		_SimpleConstructorParamInfo? paramInfo = this._getSimpleConstructorParamInfo(tag);
		if (paramInfo == null) {
			// couldn't figure it out
			this._svcLogger.logErrorFrom(_COMPONENT, "Could not figure out if the constructor parameter for tag ${tag} is a List or not.");
			return null;
		}

		if (paramInfo.isList) {
			node = this._makeAstNodeConstructorsList(arrConstructors);
			return node;
		}

		node = arrConstructors[0];

		// if the tag has a condition then we treat it as a mutually-exclusive list (otherwise we can't use the condition).
		bool hasCondition = (tag.arrUnnamedChildren[0].zIf != null);
		if (!hasCondition && arrConstructors.length == 1) {
			// just a single, fixed node
			return node;
		}

		// a bunch of mutually-exclusive nodes
		Tag? firstWithZFor = tag.arrUnnamedChildren.firstOrNull((x) => x.zFor != null);
		if (firstWithZFor != null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} of parent ${tag.parent} is a single child (i.e. it's not in a list) and therefore cannot be looped. Remove the [z-for], or place it inside a multi-children container (e.g. Column).");
			return null;
		}

		node = AstNodeMutuallyExclusiveConstructorsList(
			arrConstructorNodes: arrConstructors,
			isNullConstructorAllowed: paramInfo.isNullable,
		);

		return node;
	}

	AstNodeConstructorsList? _tryMakeConstructorsListFromUnnamedChildrenTags(List<Tag> arrTags) {
		if (arrTags.isEmpty) {
			return null;
		}
		List<AstNodeConstructorLike> arrConstructors = this._flattenTagsIntoConstructors(arrTags);
		return this._makeAstNodeConstructorsList(arrConstructors);
	}
	
	void _applyPositionalParametersFromChildren(Map<int, AstNodeZssParameterValue> map, Tag tagToProcess) {
		var arr = tagToProcess.mapNamedChildren.values;
		for (Tag tag in arr) {
			if (!tag.isNamedChildTag) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Expected tag ${tag} to be a named prop tag (this may be an ezFlap bug)");
				continue;
			}

			if (!this._doesTagLookLikePositionalParameter(tag.name)) {
				continue;
			}

			int? maybePropPosition = this._tryGetPositionalParameterPositionFromName(tag.name);
			if (maybePropPosition == null) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Expected positional prop tag ${tag} to have a numeric name (i.e. start with \":\", followed by the zero-based position, and then by \"-\"), but got: [${tag.name}].");
				continue;
			}
			
			AstNodeBase? node = this._tryMakeNodeFromParameterTag(tag);
			if (node == null) {
				continue;
			}
			
			map[maybePropPosition] = AstNodeZssParameterValue.simple(node);
		}
	}
	
	List<AstNodeConstructorLike> _flattenTagsIntoConstructors(List<Tag> arrTags, [ List<String> arrAdditionalZIfClauses = const [ ], List<String> arrAdditionalZShowClauses = const [ ] ]) {
		List<AstNodeConstructorLike?> arrRet = [ ];
		for (Tag tag in arrTags) {
			if (tag.isTypeGroup()) {
				arrRet.addAll(this._flattenGroupTagIntoConstructors(tag, arrAdditionalZIfClauses, arrAdditionalZShowClauses));
			}
			else if (tag.isTypeSlotConsumer()) {
				arrRet.add(this._generateConsumerSlotNode(tag));
			}
			else {
				arrRet.add(this._generateConstructorNode(tag, arrAdditionalZIfClauses, arrAdditionalZShowClauses));
			}
		}
		
		return arrRet.filterNull().denull().toList(growable: false);
	}
	
	List<AstNodeConstructorLike> _flattenGroupTagIntoConstructors(Tag groupTag, [ List<String> arrAdditionalZIfClauses = const [ ], List<String> arrAdditionalZShowClauses = const [ ] ]) {
		if (groupTag.arrUnnamedChildren.isEmpty) {
			return [ ];
		}

		if (groupTag.zIf != null) {
			arrAdditionalZIfClauses = [ ...arrAdditionalZIfClauses, groupTag.zIf! ];
		}
		if (groupTag.zShow != null) {
			arrAdditionalZShowClauses = [ ...arrAdditionalZShowClauses, groupTag.zShow! ];
		}

		return this._flattenTagsIntoConstructors(groupTag.arrUnnamedChildren, arrAdditionalZIfClauses, arrAdditionalZShowClauses);
	}

	AstNodeSlotProvider? _generateProviderSlotNode(Tag tagSlot) {
		assert(tagSlot.isTypeSlotProvider());
		AstNodeConstructorsList? constructorsList = this._tryMakeConstructorsListFromUnnamedChildrenTags(tagSlot.arrUnnamedChildren);
		if (constructorsList == null) {
			return null;
		}
		return AstNodeSlotProvider(name: tagSlot.zName, scope: tagSlot.zScope, childList: constructorsList);
	}

	AstNodeSlotConsumer? _generateConsumerSlotNode(Tag tagSlot) {
		assert(tagSlot.isTypeSlotConsumer());
		AstNodeConstructorsList? constructorsList = this._tryMakeConstructorsListFromUnnamedChildrenTags(tagSlot.arrUnnamedChildren);

		Map<String, AstNodeZssParameterValue> map = this._makeNamedParamsNodes(tagSlot);
		Map<String, AstNodeBase> mapNamedParamNodes = map.map((key, node) => MapEntry(key, node.valueNode));

		Map<String, AstNodeStringWithMustache> mapStringNodes = tagSlot.mapStrings.map((key, s) => MapEntry(key, AstNodeStringWithMustache(s)));

		return AstNodeSlotConsumer(
			name: tagSlot.zName,
			mapNamedParamNodes: mapNamedParamNodes,
			mapStringNodes: mapStringNodes,
			defaultChildList: constructorsList,
		);
	}

	AstNodeSlotProvider? _generateImplicitDefaultSlotProviderNode(Tag tag) {
		List<Tag> arrNonExplicitSlotProviderTags = tag.arrUnnamedChildren.where((x) => !x.isTypeSlotProvider()).toList();

		if (arrNonExplicitSlotProviderTags.isEmpty) {
			return null;
		}

		AstNodeConstructorsList? constructorsList = this._tryMakeConstructorsListFromUnnamedChildrenTags(arrNonExplicitSlotProviderTags);
		if (constructorsList == null) {
			return null;
		}

		// implicit slot providers don't (can't..) define a scope name
		return AstNodeSlotProvider(name: null, scope: null, childList: constructorsList);
	}

	void _applyNamedParametersFromAttributes(Map<String, AstNodeZssParameterValue> map, Tag tagToProcess) {
		map.addAll(tagToProcess.mapZBinds
			.whereKey((x) => this._doesTagLookLikeNamedParameter(x))
			.map((String key, String value) {
				AstNodeLiteral? nodeType = this._getTypeLiteral(tagToProcess, key, logErrorsIfNotFound: false);
				AstNodeLiteral nodeValue = AstNodeLiteral(value);
				AstNodeZssParameterValue nodeZssParam = AstNodeZssParameterValue.simpleWithType(nodeValue, nodeType);
				MapEntry<String, AstNodeZssParameterValue> mapEntry = MapEntry(key, nodeZssParam);
				return mapEntry;
			})
		);

		map.addAll(tagToProcess.mapStrings
			.whereKey((x) => this._doesTagLookLikeNamedParameter(x))
			.whereKey((x) => this._doesNamedParamExistInClass(tagToProcess, x)) // if no such named param - assume that the string is provided for ZSS
			.map((String key, String value) => MapEntry(key, AstNodeZssParameterValue.simple(AstNodeStringWithMustache(value))))
		);
	}
	
	void _applyPositionalParametersFromStrings(Map<int, AstNodeZssParameterValue> map, Tag tagToProcess) {
		map.addAll(tagToProcess.mapZBinds
			.whereKey((x) => this._doesTagLookLikePositionalParameter(x))
			.map((String key, String value) => MapEntry(this._tryGetPositionalParameterPositionFromName(key)!, AstNodeZssParameterValue.simple(AstNodeLiteral(value))))
		);
		map.addAll(tagToProcess.mapStrings
			.whereKey((x) => this._doesTagLookLikePositionalParameter(x))
			.map((String key, String value) => MapEntry(this._tryGetPositionalParameterPositionFromName(key)!, AstNodeZssParameterValue.simple(AstNodeStringWithMustache(value))))
		);
	}

	bool _doesNamedParamExistInClass(Tag tag, String paramName) {
		return (this._getTypeLiteral(tag, paramName, logErrorsIfNotFound: false) != null);
	}

	AstNodeConstructorsList _makeAstNodeConstructorsList(List<AstNodeConstructorLike> arrConstructors) {
		return AstNodeConstructorsList(arrConstructors);
	}

	List<AstNodeZssParameterValue>? _makePositionalParamNodes(Tag tag) {
		List<AstNodeZssParameterValue> arrPositionalNodes = [ ];
		Map<int, AstNodeZssParameterValue> map = { };
		this._applyPositionalParametersFromChildren(map, tag);
		this._applyPositionalParametersFromStrings(map, tag);


		Map<int, AstNodeZssParameterValue> mapSorted = map.sortByNumericByEntries((x) => x.key);
		int expectedNextPosition = 0;
		for (MapEntry<int, AstNodeZssParameterValue> kvp in mapSorted.entries) {
			int nextPosition = kvp.key;
			if (nextPosition != expectedNextPosition) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Could not find positional parameter [${expectedNextPosition}] for tag ${tag}.");
				return null;
			}

			arrPositionalNodes.add(kvp.value);
			expectedNextPosition++;
		}
		
		return arrPositionalNodes;
	}

	Map<String, AstNodeModelValue> _makeModelsMap(Tag tag) {
		Map<String, AstNodeModelValue> map = { };

		for (MapEntry<String, String> kvp in tag.mapZModels.entries) {
			AstNodeModelValue value;
			String modelValue = kvp.value;
			value = this._makeSimpleModelValueNode(kvp.key, modelValue, tag);
			map[kvp.key] = value;
		}

		return map;
	}

	String _getModelTypeLiteral(String key, Tag tag) {
		ClassDescriptor? desc = this._tryGetClassDescriptor(tag.name);
		if (desc == null) {
			return "dynamic"; // shouldn't get here (an error was already thrown)
		}

		if (!desc.isEzflapWidget || desc.stateClassElement == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} has z-model but is not an ezFlap Widget (or its state class cannot be found)");
			return "dynamic";
		}

		EzModelVisitor ezModelVisitor = EzModelVisitor();
		ezModelVisitor.visitAll(desc.getStateClassElementAndUp());

		EzOptionalModelVisitor ezOptionalModelVisitor = EzOptionalModelVisitor();
		ezOptionalModelVisitor.visitAll(desc.getStateClassElementAndUp());

		/// see explanation in doc of Tag.zModelTypeLiteral
		String? typeLiteral = tag.zModelTypeLiteral;
		if (typeLiteral == null) {
			EzModelData? modelData = ezModelVisitor.tryGetEzAnnotationDataByAssignedName(key);
			if (modelData != null) {
				typeLiteral = modelData.typeWithNullability;
			}

			if (modelData == null) {
				EzOptionalModelData? optionalModelData = ezOptionalModelVisitor.tryGetEzAnnotationDataByAssignedName(key);
				if (optionalModelData != null) {
					typeLiteral = optionalModelData.typeWithNullability;
				}
			}
		}

		if (typeLiteral == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, """\n
				Could not figure out the type of EzModel or EzOptionalModel [${key}] on tag ${tag}.
				Defaulting to [dynamic]. This may be due to a bug in the Dart analyzer package.
				Use [z-model-type-literal] next to the [z-model] to tell ezFlap the type of the model
				(i.e. the type used in the @EzModel or @EzOptionalModel declaration in the hosted widget).
				For example:
					z-model-type-literal="int?"
				Currently, ezFlap doesn't support different types for different models on the widget.
				If there are multiple models, and if the widget in question is inherited - consider to
				remove the inheritance (inheritance is a likely cause to this situation).
			""");
			return "dynamic";
		}

		return typeLiteral;
	}

	AstNodeModelValue _makeSimpleModelValueNode(String key, String valueLiteral, Tag tag) {
		String typeLiteral = this._getModelTypeLiteral(key, tag);
		return AstNodeModelValue(
			key: key,
			fullValueLiteral: valueLiteral,
			typeLiteral: typeLiteral,
		);
	}

	Map<String, String> _makeOnsMap(Tag tag) {
		return tag.mapZOns;
	}
}