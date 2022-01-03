
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

class TemplateVisitor extends SimpleElementVisitor {
	static const String ZML_ELEMENT_NAME = "_ZML";
	static const String INITIAL_ZML_ELEMENT_NAME = "_INITIAL_ZML";
	static const String ZSS_ELEMENT_NAME = "_ZSS";

	String? zml;
	String? initialZml;
	String? zss;

	@override
	visitFieldElement(FieldElement element) {
		if (element.isConst) {
			if (element.name == ZML_ELEMENT_NAME) {
				this.zml = this._process(element);
			}
			else if (element.name == INITIAL_ZML_ELEMENT_NAME) {
				this.initialZml = this._process(element);
			}
			else if (element.name == ZSS_ELEMENT_NAME) {
				this.zss = this._process(element);
			}
		}
	}

	String? _process(FieldElement element) {
		DartObject? value = element.computeConstantValue();
		return value?.toStringValue();
	}
}