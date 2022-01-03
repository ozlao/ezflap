
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Widget/Base/WidgetGeneratorBase.dart';
import 'package:source_gen/source_gen.dart';

class EzStateBaseGenerator extends WidgetGeneratorBase {
	EzStateBaseGenerator({ required ClassElement element, required ConstantReader annotation, required SplitCode splitCode }) : super(element: element, annotation: annotation, splitCode: splitCode);

	@override
	String generate() {
		String? inheritedFromBaseClass = this.getExtendBaseClass();
		bool isBaseClass = this.isTopBaseClass();

		String className = this.getClassName();
		String genericPart = this._makeGenericPart(isBaseClass);
		String extendsPart = this._makeExtendsPart(className, inheritedFromBaseClass, isBaseClass);

		String inState = this.splitCode.arrInState.join("\n");

		String buildHostVariable = this._makeBuildHostVariable();
		String buildHostVariableGetters = this._makeBuildHostVariableGetters();
		String constructorFunction = this._makeConstructorFunction();
		String setBuildHostFunction = this._makeSetBuildHostFunction();
		String internalInitStateFunction = this._makeInternalInitStateFunction();
		String internalOnReadyFunction = this._makeInternalOnReadyFunction();
		String internalBuildFunction = this._makeInternalBuildFunction();
		String refreshPropsFunction = this._makeRefreshPropsFunction();

		return """
			abstract class _EzStateBase${genericPart} extends ${extendsPart} {
				${buildHostVariable}
				
				${buildHostVariableGetters}
				
				${constructorFunction}
				
				${setBuildHostFunction}
				
				${internalInitStateFunction}
				
				${internalOnReadyFunction}
				
				${internalBuildFunction}

				${refreshPropsFunction}

				${inState}
			}
		""";
	}

	String _makeRefreshPropsFunction() {
		if (this.splitCode.arrInStateRefreshProps.isEmpty) {
			return "";
		}

		String inRefreshProps = this.splitCode.arrInStateRefreshProps.join("\n");
		String callSuper = "";
		if (this.isExtending()) {
			callSuper = "super.\$internalRefreshProps();";
		}

		return """
			void \$internalRefreshProps() {
				${callSuper}
				
				${inRefreshProps}
			}
		""";
	}

	String _makeNonVirtual() {
		return (this.isExtending() || this.isExtended() ? "" : "@nonVirtual");
	}

	String _makeBuildHostVariable() {
		String buildHostClassName = this.getBuildHostClassName();
		return """
			late ${buildHostClassName} _buildHost;
		""";
	}

	String _makeBuildHostVariableGetters() {
		String buildHostClassName = this.getBuildHostClassName();
		return """
			${buildHostClassName} \$getBuildHost() { return this._buildHost; }
			
			/// use only for testing!
			${buildHostClassName} get bh { return this.\$getBuildHost(); }
		""";
	}

	String _makeConstructorFunction() {
		String buildHostClassName = this.getBuildHostClassName();
		String maybeSetBuildHostCode = "this._buildHost = ${buildHostClassName}(this);";
		String maybeCallSuperSetBuildHostCode = "";

		if (this.isExtended()) {
			// if extended - let the child instantiate buildHost and set it
			// for us using the $setBuildHost() function.
			maybeSetBuildHostCode = "";
		}

		if (this.isExtending()) {
			// if extending - we need to call our parent's $setBuildHost().
			if (this.isExtended()) {
				// if extended - we call our parent's $setBuildHost() from
				// inside our own $setBuildHost
			}
			else {
				maybeCallSuperSetBuildHostCode = "super.\$setBuildHost(this._buildHost);";
			}
		}

		return """
			_EzStateBase() {
				${maybeSetBuildHostCode}
				${maybeCallSuperSetBuildHostCode}
			}
		""";
	}

	String _makeSetBuildHostFunction() {
		if (!this.isExtended()) {
			// if we are not extended - we initialize _buildHost ourselves, in
			// the constructor.
			return "";
		}

		String buildHostClassName = this.getBuildHostClassName();
		String nonVirtual = (this.isExtended() ? "" : "@nonVirtual");
		String setParent = (this.isExtending() ? "super.\$setBuildHost(buildHost);" : "");
		return """
			@protected
			${nonVirtual}
			void \$setBuildHost(covariant ${buildHostClassName} buildHost) {
				${setParent}
				this._buildHost = buildHost;
			}
		""";
	}

	String _makeInternalInitStateFunction() {
		String nonVirtual = this._makeNonVirtual();
		String inInitState = this.splitCode.arrInStateInitState.join("\n");
		String superInternalInitState = (this.isExtending() ? "super.\$internalInitState();" : "");
		return """
			@override
			${nonVirtual}
			void \$internalInitState() {
				${superInternalInitState}
				${inInitState}
			}
		""";
	}

	String _makeInternalOnReadyFunction() {
		String nonVirtual = this._makeNonVirtual();
		String superInternalOnReady = (this.isExtending() ? "super.\$internalOnReady();" : "");
		return """
			@override
			${nonVirtual}
			void \$internalOnReady() {
				${superInternalOnReady}
				this._buildHost._onInitState();
			}
		""";
	}

	String _makeInternalBuildFunction() {
		if (this.isExtended()) {
			// extended Widgets don't have their own $internalBuild() function;
			// instead, their BuildHost's build() function is called from the
			// inheriting BuildHosts.
			return "";
		}

		return """
			@override
			@nonVirtual
			Widget \$internalBuild(BuildContext context) {
				bool preferInitial = !this.\$isReady();
				return this._buildHost.build(context, preferInitial);
			}
		""";
	}

	String _makeGenericPart(bool isBaseClass) {
		String ezViewT = "";
		bool isExtending = this.isExtending();
		if (isExtending || isBaseClass) {
			ezViewT = "<T extends EzStatefulWidgetBase>";
		}
		return ezViewT;
	}

	String _makeExtendsPart(String className, String? inheritedFromBaseClass, bool isBaseClass) {
		String otherClassName = className.substring(0, className.length - "State".length);
		String sExtends = "EzStateBase<${otherClassName}>";

		if (this.isExtending()) {
			sExtends = "${inheritedFromBaseClass}<T>";
		}
		else {
			if (isBaseClass) {
				sExtends = "EzStateBase<T>";
			}
		}

		return sExtends;
	}
}