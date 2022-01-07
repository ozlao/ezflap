
import 'package:ezflap/src/Annotations/EzWidget/EzProp/EzProp.dart';
import 'package:flutter/widgets.dart';

abstract class _EzStateBase<T> { }
class EzStatefulWidgetBase { // this needs to be consistent with SvcReflector._WIDGET_BASE_CLASS
	EzStatefulWidgetBase({ Key? key });
}

class ZmlGeneratorTestSlotsExtendEzStatefulWidget extends EzStatefulWidgetBase {
	ZmlGeneratorTestSlotsExtendEzState createState() => ZmlGeneratorTestSlotsExtendEzState();
}

class ZmlGeneratorTestSlotsExtendEzState extends _EzStateBase<int> {
	@EzProp("children") late List<Widget> _$prop_children;
}



class ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget extends EzStatefulWidgetBase {
	ZmlGeneratorTestSlotsSingleChildExtendEzState createState() => ZmlGeneratorTestSlotsSingleChildExtendEzState();
}

class ZmlGeneratorTestSlotsSingleChildExtendEzState extends _EzStateBase<int> {
	@EzProp("child") late Widget _$prop_child;
}



class ZmlGeneratorTestSlotsNoChildrenExtendEzStatefulWidget extends EzStatefulWidgetBase {
	ZmlGeneratorTestSlotsNoChildrenExtendEzState createState() => ZmlGeneratorTestSlotsNoChildrenExtendEzState();
}

class ZmlGeneratorTestSlotsNoChildrenExtendEzState extends _EzStateBase<int> {
	@EzProp("pet") late String _$prop_animal; // --> this._prop_animal
}



class ZmlGeneratorTestPet extends EzStatefulWidgetBase {
	ZmlGeneratorTestPetState createState() => ZmlGeneratorTestPetState();
}

class ZmlGeneratorTestPetState extends _EzStateBase<int> {
	@EzProp("pet") late String _$prop_animal; // --> this._prop_animal
}



class ZmlGeneratorTestNoKeyInConstructorOrProp extends EzStatefulWidgetBase {
	ZmlGeneratorTestNoKeyInConstructorOrPropState createState() => ZmlGeneratorTestNoKeyInConstructorOrPropState();
}

class ZmlGeneratorTestNoKeyInConstructorOrPropState extends _EzStateBase<int> {

}



class ZmlGeneratorTestNoKeyInConstructorButKeyInProp extends EzStatefulWidgetBase {
	ZmlGeneratorTestNoKeyInConstructorButKeyInPropState createState() => ZmlGeneratorTestNoKeyInConstructorButKeyInPropState();
}

class ZmlGeneratorTestNoKeyInConstructorButKeyInPropState extends _EzStateBase<int> {
	@EzProp("key") late Key _$prop_key; // --> this._prop_key
}



class ZmlGeneratorTestKeyInConstructorButNotInProp extends EzStatefulWidgetBase {
	ZmlGeneratorTestKeyInConstructorButNotInPropState createState() => ZmlGeneratorTestKeyInConstructorButNotInPropState();

	ZmlGeneratorTestKeyInConstructorButNotInProp({ Key? key }) : super(key: key);
}

class ZmlGeneratorTestKeyInConstructorButNotInPropState extends _EzStateBase<int> {
	@EzProp("key") late Key _$prop_key; // --> this._prop_key
}



class ZmlGeneratorTestKeyInConstructorAndInProp extends EzStatefulWidgetBase {
	ZmlGeneratorTestKeyInConstructorAndInPropState createState() => ZmlGeneratorTestKeyInConstructorAndInPropState();

	ZmlGeneratorTestKeyInConstructorAndInProp({ Key? key }) : super(key: key);
}

class ZmlGeneratorTestKeyInConstructorAndInPropState extends _EzStateBase<int> {
	@EzProp("key") late Key _$prop_key; // --> this._prop_key
}
