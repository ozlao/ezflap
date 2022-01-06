
import 'package:ezflap/src/Service/EzflapTester/Wrapper/WidgetWrapper.dart';
import 'package:ezflap/src/Utils/Tick/Tick.dart';
import 'package:ezflap/src/View/EzState/EzStateBase.dart';
import 'package:ezflap/src/View/EzState/ModelHandler/ModelHandler.dart';
import 'package:ezflap/src/View/EzStatefulWidget/SlotProvider/SlotProvider.dart';
import 'package:flutter/widgets.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:meta/meta.dart';

typedef _TFuncNotifyInitState = void Function($EzStateBase);
typedef _TFuncNotifyDispose = void Function($EzStateBase);

typedef TFuncEzStatefulWidgetFactory = EzStatefulWidgetBase Function(BuildContext);

// the name of this class must be consistent with SvcReflector._WIDGET_BASE_CLASS
/// Full documentation: https://www.ezflap.io/essentials/introduction/introduction.html#ezflap-widget-classes
///
/// ezFlaps widgets are stateful, and like any stateful Flutter widget - consist
/// of two classes.
/// The class that, for a native Flutter widget would extend [StatefulWidget] -
/// needs to extend [EzStatefulWidgetBase] instead.
// TODO: add key support to ezFlap widgets (by properly passing to the constructor)
abstract class EzStatefulWidgetBase extends StatefulWidget {
	$IWidgetWrapperForWidget? _widgetWrapper;

	Map<String, dynamic>? _mapProps;
	Map<String, $ModelHandler>? _mapModels;
	Map<String, Function>? _mapEmitHandlers;
	Map<String?, $SlotProvider>? _mapSlotProviders;
	String? _interpolatedText;

	@internal
	_TFuncNotifyInitState? funcNotifyInitState;

	@internal
	_TFuncNotifyDispose? funcNotifyDispose;

	static int _nextGuid = 1;

	@internal
	int $ezWidgetGuid = EzStatefulWidgetBase._nextGuid++;

  EzStatefulWidgetBase({Key? key}) : super(key: key);

	@internal
	bool $hasWidgetWrapper() => this._widgetWrapper != null;

	@internal
	void $initWidgetWrapper($IWidgetWrapperForWidget widgetWrapper) {
		this._widgetWrapper = widgetWrapper;
	}

	@internal
	Map<String, dynamic>? $getDIOverrides() {
		return this._widgetWrapper?.$getDIOverrides();
	}

	@internal
	dynamic $getRouteParamFromWidgetWrapper(String key) {
		return this._widgetWrapper?.$getRouteParam(key);
	}

	@internal
	EzStatefulWidgetBase? $tryMockWidget(String key) {
		return this._widgetWrapper?.$mockWidget(key);
	}

	@internal
	void $initProps(Map<String, dynamic> mapProps) {
		if (this._mapProps != null) {
			throw "_mapProps is being initialized a second time in ${this}";
		}

		this._mapProps = mapProps;
	}

	@internal
	void $initModelHandlers(Map<String, $ModelHandler> mapModels) {
		this._mapModels = mapModels;
	}

	@internal
	void $initEmitHandlers(Map<String, Function> mapEmitHandlers) {
		this._mapEmitHandlers = mapEmitHandlers;
	}

	@internal
	void $initSlotProviders(Map<String?, $SlotProvider> mapSlotProviders) {
		this._mapSlotProviders = mapSlotProviders;
	}

	@internal
	void $initLifecycleHandlers(_TFuncNotifyInitState funcNotifyInitState, _TFuncNotifyDispose funcNotifyDispose) {
		this.funcNotifyInitState = (state) => Tick.nextTick(() => funcNotifyInitState(state));
		this.funcNotifyDispose = funcNotifyDispose;
	}

	@internal
	bool $isPropPopulated(String key) {
		return (this._mapProps?.containsKey(key) == true);
	}

	@internal
	T $getProp<T>(String key, [ T? def ]) {
		if (this._mapProps == null) {
			return def as T;
		}
		if (!this._mapProps!.containsKey(key)) {
			return def as T;
		}
		return this._mapProps![key];
	}

	@internal
	$ModelHandler<T>? $tryGetModelHandler<T>(String key) {
		if (this._mapModels == null) {
			return null;
		}
		if (!this._mapModels!.containsKey(key)) {
			return null;
		}

		return this._mapModels![key] as $ModelHandler<T>;
	}

	@internal
	Function? $tryGetEmitHandler(String key) {
		//this._widgetWrapper?.$onEmitHandlerRequested(key);
		if (this._mapEmitHandlers == null) {
			return null;
		}
		return this._mapEmitHandlers![key];
	}

	@internal
	void $onEmitHandlerInvoked(String key) {
		this._widgetWrapper?.$onEmitHandlerInvoked(key);
	}

	@internal
	List<Widget> $getSlotProviderWidgets(String? slotName, Map<String, dynamic> mapScopeParams) {
		$SlotProvider slotProvider = this._mapSlotProviders![slotName]!;
		$SlotProviderScope slotProviderScope = $SlotProviderScope(mapScopeParams);
		List<Widget> arr = slotProvider.funcBuild(slotProviderScope);
		return arr;
	}

	@internal
	Widget $getSingleSlotProviderWidgetOrDefault(String? slotName, Map<String, dynamic> mapScopeParams, Widget defaultWidget) {
		List<Widget>? arr;
		if (this.$hasSlotProvider(slotName)) {
			arr = this.$getSlotProviderWidgets(slotName, mapScopeParams);
		}
		return arr?.singleOrNull() ?? defaultWidget;
	}

	@internal
	bool $hasSlotProvider(String? name) {
		if (this._mapSlotProviders == null) {
			return false;
		}

		return this._mapSlotProviders!.containsKey(name);
	}
	
	@internal
	void $setInterpolatedText(String? innerText) {
		this._interpolatedText = innerText;
	}
	
	@internal
	String? $tryGetInterpolatedText() {
		return this._interpolatedText;
	}

	/// Full documentation: https://www.ezflap.io/advanced/interoperability/interoperability.html
	///
	/// Use [initProp] to "manually" push props into an ezFlap widget (for
	/// interoperability).
	void initProp<T>(String key, T value) {
		this._mapProps ??= { };
		this._mapProps![key] = value;
	}

	/// Full documentation: https://www.ezflap.io/advanced/interoperability/interoperability.html
	///
	/// Use [initModel] to "manually" provide models to an ezFlap widget (for
	/// interoperability).
	void initModel<T>(String key, { required T Function() getter, required void Function(T value) setter }) {
		this._mapModels ??= { };
		this._mapModels![key] = $ModelHandler<T>(
			funcGetModelValue: getter,
			funcSetModelValue: setter,
		);
	}

	/// Full documentation: https://www.ezflap.io/advanced/interoperability/interoperability.html
	///
	/// Use [initEmitHandler] to "manually" provide event emit handlers to an
	/// ezFlap widget (for interoperability).
	void initEmitHandler(String key, Function onEmit) {
		this._mapEmitHandlers ??= { };
		this._mapEmitHandlers![key] = onEmit;
	}

	/// Full documentation: https://www.ezflap.io/advanced/interoperability/interoperability.html
	///
	/// Use [initInterpolatedText] to "manually" provide interpolated text to
	/// an ezFlap widget (for interoperability).
	void initInterpolatedText(String interpolatedText) {
		this._interpolatedText = interpolatedText;
	}
}