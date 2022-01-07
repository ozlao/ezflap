
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ConstructorDescriptor.dart';

class ClassDescriptor {
	final String name;
	final Map<String, ConstructorDescriptor?> mapConstructors = { };
	final ClassElement classElement;
	final bool isEzflapWidget;
	final ClassElement? stateClassElement;

	ClassDescriptor({
		required this.name,
		required this.classElement,
		required this.isEzflapWidget,
		required this.stateClassElement,
	});

	List<ClassElement> getStateClassElementAndUp(ClassElement? Function(ClassElement) funcCustomGetParentClassElement) {
		List<ClassElement> arr = [ ];
		ClassElement? maybeEl = this.stateClassElement;
		if (maybeEl == null) {
			return arr;
		}

		ClassElement el = maybeEl;
		while (true) {
			arr.add(el);
			ClassElement? nextEl = funcCustomGetParentClassElement(el);
			nextEl ??= el.supertype?.element;
			if (nextEl == null) {
				break;
			}
			el = nextEl;
		}
		return arr;
	}
}