
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWidget.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

abstract class WidgetGeneratorBase {
	@protected
	final ClassElement element;

	@protected
	final ConstantReader annotation;

	@protected
	final SplitCode splitCode;

	WidgetGeneratorBase({ required this.element, required this.annotation, required this.splitCode });

	String generate();

	@protected
	String? getExtendBaseClass() {
		ConstantReader extendBaseClassReader = this.annotation.read(EzWidget.EZ_WIDGET__EXTEND);
		if (extendBaseClassReader.isType) {
			DartType type = extendBaseClassReader.typeValue;
			String? typeName = type.element?.name;
			return typeName;
		}
		return null;
	}

	@protected
	bool isTopBaseClass() {
		String? inheritedFromBaseClass = this.getExtendBaseClass();
		bool ret = (this.isExtended() && inheritedFromBaseClass == null);
		return ret;
	}
	
	@protected
	bool isExtended() {
		return this.element.isAbstract;
	}

	@protected
	bool isExtending() {
		String? inheritedFromBaseClass = this.getExtendBaseClass();
		return (inheritedFromBaseClass != null);
	}

	@protected
	String getClassName() {
		return this.element.name;
	}

	@protected
	String getBuildHostClassName() {
		if (!this.isExtended()) {
			return "_\$BuildHost";
		}

		String className = this.getClassName();
		return this.getBuildHostClassNameForStateClassName(className);
	}

	@protected
	String getBuildHostClassNameForStateClassName(String stateClassName) {
		return "\$BuildHost_${stateClassName}";
	}
}