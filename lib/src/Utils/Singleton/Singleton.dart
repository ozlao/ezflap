
import 'package:ezflap/src/Utils/Guid/Guid.dart';

abstract class Singleton extends Guid {
	static final Map<Type, Singleton> _mapInstances = { };

	static T get<T extends Singleton>(T Function() factory) {
		if (!Singleton._mapInstances.containsKey(T)) {
			T instance = factory();
			Singleton._mapInstances[T] = instance;
			instance.$initDI();
		}
		T instance = Singleton._mapInstances[T] as T;
		return instance;
	}

	void $initDI() {

	}
}
