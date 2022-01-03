
import 'package:ezflap/src/Service/EzflapTester/Wrapper/WidgetWrapper.dart';
import 'package:ezflap/src/Utils/Tick/Tick.dart';
import 'package:ezflap/src/View/EzState/EzStateBase.dart';
import 'package:ezflap/src/View/EzState/ModelHandler/ModelHandler.dart';
import 'package:ezflap/src/View/EzStatefulWidget/SlotProvider/SlotProvider.dart';
import 'package:flutter/widgets.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

typedef _TFuncNotifyInitState = void Function(EzStateBase);
typedef _TFuncNotifyDispose = void Function(EzStateBase);

typedef TFuncEzStatefulWidgetFactory = EzStatefulWidgetBase Function(BuildContext);

// the name of this class must be consistent with SvcReflector._WIDGET_BASE_CLASS
abstract class EzStatefulWidgetBase extends StatefulWidget {
	$IWidgetWrapperForWidget? _widgetWrapper;

	Map<String, dynamic>? _mapProps;
	Map<String, $ModelHandler>? _mapModels;
	Map<String, Function>? _mapEmitHandlers;
	Map<String?, $SlotProvider>? _mapSlotProviders;
	_TFuncNotifyInitState? funcNotifyInitState;
	_TFuncNotifyDispose? funcNotifyDispose;
	String? _interpolatedText;

	static int _nextGuid = 1;
	int $ezWidgetGuid = EzStatefulWidgetBase._nextGuid++;

	bool $hasWidgetWrapper() => this._widgetWrapper != null;

	void $initWidgetWrapper($IWidgetWrapperForWidget widgetWrapper) {
		this._widgetWrapper = widgetWrapper;
	}

	Map<String, dynamic>? $getDIOverrides() {
		return this._widgetWrapper?.$getDIOverrides();
	}

	dynamic $getRouteParamFromWidgetWrapper(String key) {
		return this._widgetWrapper?.$getRouteParam(key);
	}

	EzStatefulWidgetBase? $tryMockWidget(String key) {
		return this._widgetWrapper?.$mockWidget(key);
	}

	void $initProps(Map<String, dynamic> mapProps) {
		if (this._mapProps != null) {
			throw "_mapProps is being initialized a second time in ${this}";
		}

		this._mapProps = mapProps;
	}

	void $initModelHandlers(Map<String, $ModelHandler> mapModels) {
		this._mapModels = mapModels;
	}

	void $initEmitHandlers(Map<String, Function> mapEmitHandlers) {
		this._mapEmitHandlers = mapEmitHandlers;
	}

	void $initSlotProviders(Map<String?, $SlotProvider> mapSlotProviders) {
		this._mapSlotProviders = mapSlotProviders;
	}

	void $initLifecycleHandlers(_TFuncNotifyInitState funcNotifyInitState, _TFuncNotifyDispose funcNotifyDispose) {
		this.funcNotifyInitState = (state) => Tick.nextTick(() => funcNotifyInitState(state));
		this.funcNotifyDispose = funcNotifyDispose;
	}

	bool $isPropPopulated(String key) {
		return (this._mapProps?.containsKey(key) == true);
	}

	T $getProp<T>(String key, [ T? def ]) {
		if (this._mapProps == null) {
			return def as T;
		}
		if (!this._mapProps!.containsKey(key)) {
			return def as T;
		}
		return this._mapProps![key];
	}

	$ModelHandler<T>? $tryGetModelHandler<T>(String key) {
		if (this._mapModels == null) {
			return null;
		}
		if (!this._mapModels!.containsKey(key)) {
			return null;
		}

		return this._mapModels![key] as $ModelHandler<T>;
	}

	Function? $tryGetEmitHandler(String key) {
		//this._widgetWrapper?.$onEmitHandlerRequested(key);
		if (this._mapEmitHandlers == null) {
			return null;
		}
		return this._mapEmitHandlers![key];
	}

	void $onEmitHandlerInvoked(String key) {
		this._widgetWrapper?.$onEmitHandlerInvoked(key);
	}

	List<Widget> $getSlotProviderWidgets(String? slotName, Map<String, dynamic> mapScopeParams) {
		$SlotProvider slotProvider = this._mapSlotProviders![slotName]!;
		$SlotProviderScope slotProviderScope = $SlotProviderScope(mapScopeParams);
		List<Widget> arr = slotProvider.funcBuild(slotProviderScope);
		return arr;
	}

	Widget $getSingleSlotProviderWidgetOrDefault(String? slotName, Map<String, dynamic> mapScopeParams, Widget defaultWidget) {
		List<Widget>? arr;
		if (this.$hasSlotProvider(slotName)) {
			arr = this.$getSlotProviderWidgets(slotName, mapScopeParams);
		}
		return arr?.singleOrNull() ?? defaultWidget;
	}

	bool $hasSlotProvider(String? name) {
		if (this._mapSlotProviders == null) {
			return false;
		}

		return this._mapSlotProviders!.containsKey(name);
	}
	
	void $setInterpolatedText(String? innerText) {
		this._interpolatedText = innerText;
	}
	
	String? $tryGetInterpolatedText() {
		return this._interpolatedText;
	}

	/// Use this to "manually" push props into an ezFlap widget (for
	/// interoperability).
	void initProp<T>(String key, T value) {
		this._mapProps ??= { };
		this._mapProps![key] = value;
	}

	void initModel<T>(String key, { required T Function() getter, required void Function(T value) setter }) {
		this._mapModels ??= { };
		this._mapModels![key] = $ModelHandler<T>(
			funcGetModelValue: getter,
			funcSetModelValue: setter,
		);
	}

	void initEmitHandler(String key, Function onEmit) {
		this._mapEmitHandlers ??= { };
		this._mapEmitHandlers![key] = onEmit;
	}

	void initInterpolatedText(String interpolatedText) {
		this._interpolatedText = interpolatedText;
	}
}