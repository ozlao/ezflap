
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

class GenericMethodVisitor extends SimpleElementVisitor {
	List<MethodElement> arrMethodElements = [ ];

	@override
	visitMethodElement(MethodElement element) {
		this.arrMethodElements.add(element);
	}

	MethodElement? tryGetElementByName(String name) {
		return this.arrMethodElements.where((x) => x.name == name).firstOrNull();
	}
}