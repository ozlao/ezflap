
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ParameterDescriptor/ParameterDescriptor.dart';

class ConstructorDescriptor {
	static const String DEFAULT_CONSTRUCTOR_KEY = "(default)";

	final String? name;
	final Map<String, ParameterDescriptor?> mapParameters = { };
	final ConstructorElement constructorElement;

	ConstructorDescriptor({ required this.name, required this.constructorElement });

	bool isDefaultConstructor() {
		return (this.name == null);
	}

	String getKey() {
		return (this.isDefaultConstructor() ? DEFAULT_CONSTRUCTOR_KEY : this.name!);
	}

	ParameterDescriptor? tryGetNamedParameter(String name) {
		return this.mapParameters[name];
	}

	ParameterDescriptor? tryGetOrderedParameter(int idx) {
		return this.mapParameters[idx.toString()];
	}

	static String makeKey(String? name) {
		return name ?? DEFAULT_CONSTRUCTOR_KEY;
	}
}