
import 'package:ezflap/src/Annotations/EzWidget/EzProp/EzProp.dart';
import 'package:flutter/widgets.dart';

const int MY_DEF = 888;

enum EMyEnum {
	enumValue1,
	enumValue2,
	enumValue3,
}

class _SomeOtherClass<T> {

}

abstract class _ReflectorTestBase { }
abstract class _ReflectorTestBaseWithGeneric<T> { }
abstract class _EzStateBase<T> { }
abstract class EzStatefulWidgetBase { } // this needs to be consistent with SvcReflector._WIDGET_BASE_CLASS
abstract class _ReflectorMixin { }

enum EReflectorTestAux {
	enumValue1,
	enumValue2,
	enumValue3,
}

class ReflectorTestAux {
	const ReflectorTestAux();
}

class ReflectorTestStandalone {

}

class ReflectorTestStandaloneGeneric<T> {

}

class ReflectorTestExtend extends _ReflectorTestBase {

}

class ReflectorTestExtendGeneric extends _ReflectorTestBaseWithGeneric<int> {

}

abstract class ReflectorTestExtendEzStatefulWidget extends EzStatefulWidgetBase {
	ReflectorTestExtendEzState createState() => ReflectorTestExtendEzState();
}

class ReflectorTestExtendEzState extends _EzStateBase<int> {
	@EzProp("hello") String _$prop_hello = "bye";
	@EzProp("textAlign") TextAlign _$prop_textAlign = TextAlign.end;
}

class ReflectorTestMixin with _ReflectorMixin {

}

class ReflectorTestConstructors {
	final int p1;
	final String p2;

	ReflectorTestConstructors(this.p1, this.p2);

	factory ReflectorTestConstructors.con1(int p1, String p2) {
		return ReflectorTestConstructors(p1, p2);
	}

	factory ReflectorTestConstructors.con2(int p1, String p2, int p3) {
		return ReflectorTestConstructors(p1, p2);
	}

	factory ReflectorTestConstructors.con3(int? p1, String? p2) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con4(int? p1, [ String? p2 ]) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con5([ int p1 = 42, String p2 = "hello world" ]) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con6({ int p1 = 42, String p2 = "hello world" }) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con7(int p1, { String p2 = "hello world" }) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con8(int p1, { required String p2 }) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con9([ int p1 = 42 * 88 ]) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con10(ReflectorTestAux p3) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con11([ ReflectorTestAux p3 = const ReflectorTestAux() ]) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con12([ EReflectorTestAux p4 = EReflectorTestAux.enumValue2 ]) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con13(List<int> p5) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con14(List<List<int>> p6) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con15(Map<String, List<List<int>>> p6) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con16(List<Map<String, List<List<int>>>> p6) {
		return ReflectorTestConstructors(1, "hello");
	}

	factory ReflectorTestConstructors.con17([ List<Map<String, List<List<int>>>> p6 = const [ { "key": [ [ 88 ] ] } ] ]) {
		return ReflectorTestConstructors(1, "hello");
	}
}
