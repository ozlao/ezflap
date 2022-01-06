
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericMethodVisitor/GenericMethodVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ClassDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ConstructorDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ParameterDescriptor/ParameterDescriptor.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';

class SvcReflector extends EzServiceBase {
	static SvcReflector i() { return $Singleton.get(() => SvcReflector()); }

	SvcLogger get _svcLogger => SvcLogger.i();

	static const String _COMPONENT = "SvcReflector";
	static const String _PACKAGE_FLUTTER_IDENTIFIER_PART = "package:flutter";

	// this constant must be consistent with the EzStatefulWidgetBase class name
	static const String _WIDGET_BASE_CLASS = "EzStatefulWidgetBase";

	Set<ClassElement> _hsCollectedClasses = { };
	Set<LibraryElement> _hsCollectedLibraries = { };
	Map<String, ClassElement> _mapCollectedClasses = { };
	Map<String, ClassDescriptor?> _mapClasses = { };

	ParameterDescriptor? tryDescribeNamedParameter(String className, String? constructorName, String parameterName) {
		return this._describeParameter(className, constructorName, parameterName, null, false);
	}

	ParameterDescriptor? tryDescribePositionalParameter(String className, String? constructorName, int parameterIdx) {
		return this._describeParameter(className, constructorName, null, parameterIdx, false);
	}

	ParameterDescriptor? describeNamedParameter(String className, String? constructorName, String parameterName, [ bool logErrors = true ]) {
		return this._describeParameter(className, constructorName, parameterName, null, logErrors);
	}

	ParameterDescriptor? describeNamedOrPositionalParameter(String className, String? constructorName, String parameterNameOrIdx, [ bool logErrorsForNamed = true ]) {
		int? idx = int.tryParse(parameterNameOrIdx);
		if (idx == null) {
			return this.describeNamedParameter(className, constructorName, parameterNameOrIdx, logErrorsForNamed);
		}
		else {
			return this.tryDescribePositionalParameter(className, constructorName, idx);
		}
	}

	ParameterDescriptor? describeOrderedParameter(String className, String? constructorName, int parameterIdx) {
		return this._describeParameter(className, constructorName, null, parameterIdx, true);
	}

	ParameterDescriptor? _describeParameter(String className, String? constructorName, String? parameterName, int? parameterIdx, bool logErrors) {
		ClassDescriptor? classDescriptor = this.describeClass(className);
		if (classDescriptor == null) {
			if (logErrors) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Could not find class [${className}].");
			}
			return null;
		}

		if (classDescriptor.isEzflapWidget) {
			// constructor parameters are not used with ezFlap widgets.
			return null;
		}

		LibraryElement libraryElement = classDescriptor.classElement.library;
		ConstructorDescriptor? constructorDescriptor = this.describeConstructor(classDescriptor, constructorName);
		if (constructorDescriptor == null) {
			if (logErrors) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Could not find constructor [${constructorName}] in class [${className}] in library ${libraryElement}.");
			}
			return null;
		}

		ParameterDescriptor? parameterDescriptor = this._tryGetParameter(constructorDescriptor, parameterName, parameterIdx);
		if (parameterDescriptor == null) {
			if (logErrors) {
				this._svcLogger.logErrorFrom(_COMPONENT, "Could not find parameter [${parameterName}] in constructor [${constructorName}] in class [${className}] in library ${libraryElement}.");
			}
			return null;
		}

		return parameterDescriptor;
	}

	void _touchClassElementToInvokeAnalysis(ClassElement classElement) {
		// the below seems to cause the analysis of ClassElement to actually
		// happen. before it - no constructors, members, etc. are listed. after
		// it - they are.
		classElement.unnamedConstructor;
	}

	ParameterDescriptor? _tryGetParameter(ConstructorDescriptor constructorDescriptor, String? parameterName, int? parameterIdx) {
		String key = parameterName ?? parameterIdx!.toString();
		if (constructorDescriptor.mapParameters.containsKey(key)) {
			return constructorDescriptor.mapParameters[key];
		}

		ParameterElement? parameterElement;
		List<ParameterElement> arrParameterElements = constructorDescriptor.constructorElement.parameters;
		if (parameterIdx == null) {
			// named
			parameterElement = constructorDescriptor.constructorElement.parameters.firstOrNull((x) => x.name == key);
		}
		else {
			// ordered
			if (parameterIdx < arrParameterElements.length) {
				parameterElement = arrParameterElements[parameterIdx];
				if (!parameterElement.isPositional) {
					// not positional after all...
					parameterElement = null;
				}
			}
		}

		ParameterDescriptor? parameterDescriptor;
		if (parameterElement != null) {
			String? defaultValueLiteral = this._getDefaultValueLiteral(parameterElement);
			bool isList = parameterElement.type.isDartCoreList;
			bool isNullable = (parameterElement.type.nullabilitySuffix != NullabilitySuffix.none);
			String typeLiteral = parameterElement.type.toString();
			parameterDescriptor = ParameterDescriptor(
				name: parameterElement.name,
				idx: parameterIdx,
				isRequired: !parameterElement.isOptional,
				defaultValueLiteral: defaultValueLiteral,
				parameterElement: parameterElement,
				isList: isList,
				isNullable: isNullable,
				typeLiteral: typeLiteral,
			);
		}

		constructorDescriptor.mapParameters[key] = parameterDescriptor;

		return parameterDescriptor;
	}

	String? _getDefaultValueLiteral(ParameterElement parameterElement) {
		// we use dynamic because constantInitializer is available in the Impl
		// class but not in the interface.
		dynamic dynParameterElement = parameterElement;
		dynamic dynConstantInitializer = dynParameterElement.constantInitializer;
		return dynConstantInitializer?.toString();
	}

	ConstructorDescriptor? describeConstructor(ClassDescriptor classDescriptor, String? constructorName) {
		String key = ConstructorDescriptor.makeKey(constructorName);
		if (classDescriptor.mapConstructors.containsKey(key)) {
			return classDescriptor.mapConstructors[key];
		}

		ConstructorElement? constructorElement;
		if (constructorName == null) {
			constructorElement = classDescriptor.classElement.unnamedConstructor;
		}
		else {
			constructorElement = classDescriptor.classElement.constructors.firstOrNull((x) => x.name == constructorName);
		}

		ConstructorDescriptor? constructorDescriptor = null;
		if (constructorElement != null) {
			constructorDescriptor = ConstructorDescriptor(
				name: constructorName,
				constructorElement: constructorElement,
			);
		}

		classDescriptor.mapConstructors[key] = constructorDescriptor;

		return constructorDescriptor;
	}

	ClassDescriptor? describeClass(String className) {
		if (this._mapClasses.containsKey(className)) {
			return this._mapClasses[className];
		}

		ClassDescriptor? classDescriptor = null;
		ClassElement? classElement = this._mapCollectedClasses[className];
		if (classElement != null) {
			bool isEzflapWidget = this._isClassEzflapWidget(classElement);
			ClassElement? stateClassElement;
			if (isEzflapWidget) {
				stateClassElement = this._getStateClassOfWidgetClass(classElement);
			}

			classDescriptor = ClassDescriptor(
				name: className,
				classElement: classElement,
				isEzflapWidget: isEzflapWidget,
				stateClassElement: stateClassElement,
			);
		}

		if (classDescriptor != null) {
			this._touchClassElementToInvokeAnalysis(classDescriptor.classElement);
		}

		this._mapClasses[className] = classDescriptor;

		return classDescriptor;
	}

	ClassElement? _getStateClassOfWidgetClass(ClassElement widgetClassElement) {
		GenericMethodVisitor genericMethodVisitor = GenericMethodVisitor();
		widgetClassElement.visitChildren(genericMethodVisitor);
		MethodElement? elCreateState = genericMethodVisitor.tryGetElementByName("createState");
		if (elCreateState == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Could not find createState method in element ${widgetClassElement}");
			return null;
		}

		Element? elState = elCreateState.returnType.element;
		if (elState == null || elState.name == "\$EzStateBase") {
			this._svcLogger.logErrorFrom(_COMPONENT, "Could not find return type element of createState method in element ${widgetClassElement}, in method ${elCreateState}. Be sure to set it to \"${widgetClassElement.name}State\"");
			return null;
		}

		if (elState is! ClassElement) {
			return null;
		}

		return elState;
	}

	bool _isClassEzflapWidget(ClassElement classElement) {
		InterfaceType? supertype = classElement.supertype;
		if (supertype == null) {
			return false;
		}

		String primaryType = supertype.element.name; // this won't include generics
		return (primaryType == _WIDGET_BASE_CLASS);
	}

	// this function should be used only in tests; outside of tests - need to
	// use repopulate() instead.
	void repopulateAsNeededForTesting(LibraryElement inputLibraryElement) {
		// we intentionally don't clear this._hsCollectedClasses so as to not
		// re-load classes if not necessary

		// we always need to repopulate because otherwise changes don't take
		// effect (e.g. if a user changed an EzProp on some widget, etc.)
		int lenBefore = this._hsCollectedClasses.length;
		inputLibraryElement.importedLibraries.forEach((x) => this._collectClasses(x));
		int lenAfter = this._hsCollectedClasses.length;
		if (lenAfter > lenBefore) {
			// added classes. re-process
			this._mapCollectedClasses = this._processCollectedClassesIntoMap();
			this._mapClasses = { };
		}
	}
	
	void repopulate(LibraryElement inputLibraryElement) {
		// UPDATE: we NEED to re-load, e.g. if the user changes an EzProp on
		//         some widget.
		this._hsCollectedClasses = { };

		// we always need to repopulate because otherwise changes don't take
		// effect (e.g. if a user changed an EzProp on some widget, etc.)
		inputLibraryElement.importedLibraries.forEach((x) => this._collectClasses(x));
		this._mapCollectedClasses = this._processCollectedClassesIntoMap();
		this._mapClasses = { };
	}

	void _collectClassesFromLibrary(LibraryElement libraryElement) {
		libraryElement.units.forEach((unitElement) {
			this._hsCollectedClasses.addAll(unitElement.classes.where((x) => !x.name.startsWith("_")));
		});
	}

	void _collectLibrariesFromLibrary(LibraryElement libraryElement) {
		List<LibraryElement> arrPotentials = [
			...libraryElement.exportedLibraries,
		];
		for (LibraryElement el in arrPotentials) {
			if (!this._hsCollectedLibraries.contains(el)) {
				this._hsCollectedLibraries.add(el);
				this._collectLibrariesFromLibrary(el);
			}
		}
	}

	void _collectClasses(LibraryElement inputLibraryElement) {
		this._hsCollectedLibraries = { inputLibraryElement };
		this._collectLibrariesFromLibrary(inputLibraryElement);
		for (LibraryElement el in this._hsCollectedLibraries) {
			this._collectClassesFromLibrary(el);
		}
	}

	Map<String, ClassElement> _processCollectedClassesIntoMap() {
		List<ClassElement> arrCollectedClasses = this._hsCollectedClasses.toList();
		Map<String, List<ClassElement>> mapClassesByNames = { };
		for (ClassElement el in arrCollectedClasses) {
			String name = el.name;
			if (!mapClassesByNames.containsKey(name)) {
				mapClassesByNames[name] = [ ];
			}
			mapClassesByNames[name]!.add(el);
		}

		// these can be used for debugging
		List<List<ClassElement>> arrArrDumped = [ ];
		List<List<ClassElement>> arrArrMulti = [ ];

		List<ClassElement> arrSelected = [ ];
		for (MapEntry<String, List<ClassElement>> kvp in mapClassesByNames.entries) {
			List<ClassElement> arrDumped = [ ];
			List<ClassElement> arrMaybeMulti = [ ];
			List<ClassElement> arrClassesWithSameName = kvp.value;

			if (arrClassesWithSameName.length == 1) {
				arrSelected.add(arrClassesWithSameName[0]);
			}
			else if (arrClassesWithSameName.length > 1) {
				for (ClassElement el in kvp.value) {
					String identifier = el.library.identifier;
					if (identifier.contains(_PACKAGE_FLUTTER_IDENTIFIER_PART)) {
						arrMaybeMulti.add(el);
					}
					else {
						arrDumped.add(el);
					}
				}

				if (arrMaybeMulti.length == 1) {
					arrSelected.add(arrMaybeMulti[0]);
				}
				else if (arrMaybeMulti.length > 1) {
					arrArrMulti.add(arrMaybeMulti);
					print("Warning: multiple Flutter classes with the same name found: ${arrMaybeMulti}");
				}

				if (arrDumped.isNotEmpty) {
					arrArrDumped.add(arrDumped);
				}
			}
		}

		return arrSelected.toMap(
			funcKey: (x) => x.name,
			funcValue: (x) => x,
		);
	}
}