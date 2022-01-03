
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

	List<ClassElement> getStateClassElementAndUp() {
		List<ClassElement> arr = [ ];
		ClassElement? el = this.stateClassElement;
		while (el != null) {
			arr.add(el);
			el = el.supertype?.element;
		}
		return arr;
	}
}