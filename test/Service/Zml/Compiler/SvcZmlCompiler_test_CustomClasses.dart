
import 'package:ezflap/src/Annotations/EzWidget/EzProp/EzProp.dart';
import 'package:flutter/widgets.dart';

abstract class _EzStateBase<T> { }
abstract class EzStatefulWidgetBase { } // this needs to be consistent with SvcReflector._WIDGET_BASE_CLASS

class ZmlCompilerTestSlotsExtendEzStatefulWidget extends EzStatefulWidgetBase {
	ZmlCompilerTestSlotsExtendEzState createState() => ZmlCompilerTestSlotsExtendEzState();
}

class ZmlCompilerTestSlotsExtendEzState extends _EzStateBase<int> {
	@EzProp("children") late List<Widget> _$prop_children;
}
