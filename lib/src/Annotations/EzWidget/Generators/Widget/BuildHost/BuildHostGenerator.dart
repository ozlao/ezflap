
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Widget/Base/WidgetGeneratorBase.dart';
import 'package:source_gen/source_gen.dart';

class BuildHostGenerator extends WidgetGeneratorBase {
	late final String _sBuilder;
	late final String? _sInitialBuilder;
	late final String _zssStyleFunctions;

	BuildHostGenerator({
		required String zssStyleFunctions,
		required String sBuilder,
		required String? sInitialBuilder,
		required ClassElement element,
		required ConstantReader annotation,
		required SplitCode splitCode,
	}) : super(element: element, annotation: annotation, splitCode: splitCode) {
		this._sBuilder = sBuilder;
		this._sInitialBuilder = sInitialBuilder;
		this._zssStyleFunctions = zssStyleFunctions;
	}

	@override
	String generate() {
		String inHost = this.splitCode.arrInBuildHost.join("\n");
		String buildOrBuildAsParent = (this.isExtended() ? this._makeBuildAsParentFunction() : this._makeBuildFunction());
		String buildSelfFunction = this._makeBuildSelfFunction();
		String sealed = (this.isExtended() ? "" : "@sealed");
		String buildHostClassName = this.getBuildHostClassName();
		String extendsPart = this._makeExtendsPart();
		String constructorFunction = this._makeConstructorFunction();
		String onInitStateFunction = this._makeOnInitStateFunction();
		String zssStyleFunctions = this._zssStyleFunctions;

		return """
			${sealed}
			class ${buildHostClassName}${extendsPart} {
				final _EzStateBase _ezState;
				
				${constructorFunction}

				${onInitStateFunction}
				
				${zssStyleFunctions}
				
				${buildOrBuildAsParent}
				
				${buildSelfFunction}
				
				${inHost}
			}
		""";
	}

	String _makeConstructorFunction() {
		String buildHostClassName = this.getBuildHostClassName();
		String s = "${buildHostClassName}(this._ezState)";

		if (this.isExtending()) {
			s += " : super(_ezState);";
		}
		else {
			s += ";";
		}

		return s;
	}

	String _makeOnInitStateFunction() {
		String initCode = this.splitCode.arrInBuildHostInitState.join("\n");
		return """
			void _onInitState() {
				${initCode}
			}
		""";
	}

	String _makeExtendsPart() {
		if (!this.isExtending()) {
			return "";
		}

		String inheritedFromBaseClass = this.getExtendBaseClass()!;
		String parentBuildClass = this.getBuildHostClassNameForStateClassName(inheritedFromBaseClass);
		return " extends ${parentBuildClass}";
	}

	String _makeBuildFunction() {
		String selfWidgetProcessorAndReturn = this._makeSelfWidgetProcessor();
		return """
			Widget build(BuildContext context, bool preferInitial) {
				//Widget selfWidget = this._buildSelf(context, preferInitial);
				Widget Function() funcMakeSelfWidget = () => this._buildSelf(context, preferInitial);
				${selfWidgetProcessorAndReturn}
			}
		""";
	}

	String _makeBuildAsParentFunction() {
		String selfWidgetProcessorAndReturn = this._makeSelfWidgetProcessor();
		return """
			//Widget buildAsParent(BuildContext context, bool preferInitial, Widget inheritingWidget) {
			Widget buildAsParent(BuildContext context, bool preferInitial, Widget Function() funcMakeInheritingWidget) {
				//Widget selfWidget = this._buildSelf(context, preferInitial, inheritingWidget);
				Widget Function() funcMakeSelfWidget = () => this._buildSelf(context, preferInitial, funcMakeInheritingWidget);
				${selfWidgetProcessorAndReturn}
			}
		""";
	}

	String _makeBuildSelfFunction() {
		String sInitialBuilderWrapperIfNeeded = this._makeInitialBuilderWrapperIfNeeded(this._sInitialBuilder);
		String sInheritingWidget = (this.isExtended() ? ", Widget Function() funcMakeInheritingWidget" : "");
		return """
			Widget _buildSelf(BuildContext context, bool preferInitial${sInheritingWidget}) {
				${sInitialBuilderWrapperIfNeeded}
				${this._sBuilder}
			}
		""";
	}

	String _makeSelfWidgetProcessor() {
		if (!this.isExtending()) {
			return """
				//return selfWidget;
				return funcMakeSelfWidget();
			""";
		}

		return """
			//return super.buildAsParent(context, preferInitial, selfWidget);
			return super.buildAsParent(context, preferInitial, funcMakeSelfWidget);
		""";
	}

	String _makeInitialBuilderWrapperIfNeeded(String? sInitialBuilder) {
		if (sInitialBuilder == null) {
			return "";
		}
		return """
			if (preferInitial) {
				${sInitialBuilder}
			}
		""";
	}
}