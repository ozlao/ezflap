
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:ezflap/src/View/EzState/EzStateBase.dart';
import 'package:ezflap/src/View/EzState/ModelHandler/ModelHandler.dart';
import 'package:ezflap/src/View/EzStatefulWidget/EzStatefulWidgetBase.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class WidgetMockFactory {
	late Widget Function() funcWidgetFactory;
	final MockWidgetStateBase Function()? funcCreateMockWidgetState;

	WidgetMockFactory({
		Widget Function()? funcWidgetFactory,
		this.funcCreateMockWidgetState,
	}) {
		this.funcWidgetFactory = funcWidgetFactory ?? () => Container();
	}
}

class _WidgetMockStatefulWidget extends EzStatefulWidgetBase {
	final Widget widgetToRender;

	final Function(MockWidgetStateBase) funcOnCreatedState;
	late MockWidgetStateBase Function() _funcCreateMockWidgetState;

	_WidgetMockStatefulWidget({
		required this.widgetToRender,
		required this.funcOnCreatedState,
		MockWidgetStateBase Function()? funcCreateMockWidgetState,
	}) {
		this._funcCreateMockWidgetState = funcCreateMockWidgetState ?? () => MockWidgetStateBase();
	}

	@override
	MockWidgetStateBase createState() {
		MockWidgetStateBase state = this._funcCreateMockWidgetState();
		this.funcOnCreatedState(state);
		return state;
	}

	bool _isPropPopulated(String key) {
		return this.$isPropPopulated(key);
	}

	dynamic _getPropValue(String key) {
		return this.$getProp(key);
	}
}

class WidgetMockStatefulWidget extends _WidgetMockStatefulWidget {
	WidgetMockStatefulWidget({ required Widget widgetToRender }) : super(
		widgetToRender: widgetToRender,
		funcOnCreatedState: (_) { },
	);

}

class MockWidgetStateBase extends EzStateBase<_WidgetMockStatefulWidget> {
	@override
	Widget $internalBuild(BuildContext context) {
		return this.widget.widgetToRender;
	}

	@override
	void $internalInitState() {

	}

	@override
	void $internalOnReady() {

	}
}

abstract class $IWidgetWrapperForWidget {
	dynamic $getRouteParam(String key);
	_WidgetMockStatefulWidget? $mockWidget(String key);
	//void $onEmitHandlerRequested(String key);
	void $onEmitHandlerInvoked(String key);
	Map<String, dynamic>? $getDIOverrides();
}

class WidgetMock {
	late MockWidgetStateBase _state;

	WidgetMock();

	factory WidgetMock._init({
		required MockWidgetStateBase state,
	}) {
		WidgetMock widgetMock = WidgetMock()
			.._state = state
		;
		return widgetMock;
	}

	bool isPropPopulated(String key) {
		return this._state.widget._isPropPopulated(key);
	}

	dynamic getPropValue(String key) {
		return this._state.widget._getPropValue(key);
	}
}

class _ModelHandlerWithBackendValue<T> {
	final $ModelHandler<T> modelHandler;
	final Rx<T> rx;
	_ModelHandlerWithBackendValue({ required this.modelHandler, required this.rx });
}

class WidgetWrapper<TState extends EzStateBase<TWidget>, TWidget extends EzStatefulWidgetBase> implements $IWidgetWrapperForWidget {
	late TWidget _widget;
	TState? _widgetState;

	final Map<String, Function> mapEmitHandlers;
	final Map<String, dynamic> mapProps;
	final Map<String, dynamic> mapRouteParams;
	final Map<String, WidgetMockFactory> mapHostedWidgetMockFactories;
	final Map<String, _ModelHandlerWithBackendValue> _mapModelHandlerWrappers = { };
	final Map<String, dynamic>? mapDIOverrides;

	bool _applyModelsWasCalled = false;
	final Map<String, int> _mapEmitCounters = { };
	final Map<String, List<MockWidgetStateBase>> _mapArrWidgetStates = { };

	WidgetWrapper(TWidget widget, {
		this.mapEmitHandlers = const { },
		this.mapProps = const { },
		this.mapRouteParams = const { },
		this.mapHostedWidgetMockFactories = const { },
		this.mapDIOverrides,
	}) {
		this._widget = widget;
		this._initWidgetWrapperForWidget();
		this._initEmitHandlers();
		// this._initModels();
		this._initProps();
		this._initLifecycleHandlers();
	}

	void _initWidgetWrapperForWidget() {
		this._widget.$initWidgetWrapper(this);
	}

	void _initEmitHandlers() {
		this._widget.$initEmitHandlers(this.mapEmitHandlers);
	}

	void _initProps() {
		this._widget.$initProps(this.mapProps);
	}

	void _initLifecycleHandlers() {
		this._widget.$initLifecycleHandlers(
			(EzStateBase state) { this._widgetState = state as TState; },
			(EzStateBase state) { this._widgetState = null; },
		);
	}

	TState getWidgetState() {
		return this._widgetState!;
	}

	/// synonym for getWidgetState()
	TState get ws {
		return this.getWidgetState();
	}

	@override
	dynamic $getRouteParam(String key) {
		return this.mapRouteParams[key];
	}

	@override
	_WidgetMockStatefulWidget? $mockWidget(String key) {
		WidgetMockFactory? factory = this.mapHostedWidgetMockFactories[key];
		if (factory == null) {
			return null;
		}

		Widget widget = factory.funcWidgetFactory();
		_WidgetMockStatefulWidget widgetMock = _WidgetMockStatefulWidget(
			widgetToRender: widget,
			funcOnCreatedState: (MockWidgetStateBase widgetState) {
				if (!this._mapArrWidgetStates.containsKey(key)) {
					this._mapArrWidgetStates[key] = [ ];
				}
				this._mapArrWidgetStates[key]!.add(widgetState);
			},
			funcCreateMockWidgetState: factory.funcCreateMockWidgetState,
		);

		return widgetMock;
	}

	@override
	//void $onEmitHandlerRequested(String key) {
	void $onEmitHandlerInvoked(String key) {
		this._mapEmitCounters[key] = (_mapEmitCounters[key] ?? 0) + 1;
	}

	Rx<T> initModelWithRx<T>({
		String name = SvcZmlParser.DEFAULT_MODEL_KEY,
		required Rx<T> existingModel,
	}) {
		Rx<T> rx = existingModel;
		//this._mapModels[key] = rxWrapper;
		$ModelHandler<T> modelHandler = $ModelHandler<T>(
			funcGetModelValue: () => rx.value,
			funcSetModelValue: (value) => rx.value = value,
		);
		this._mapModelHandlerWrappers[name] = _ModelHandlerWithBackendValue<T>(
			modelHandler: modelHandler,
			rx: rx,
		);
		return rx;
	}

	Rx<T> initModel<T>({
		String? name,
		required T value,
	}) {
		name ??= SvcZmlParser.DEFAULT_MODEL_KEY;
		return this.initModelWithRx<T>(name: name, existingModel: Rx<T>(value));
	}

	void _applyModels() {
		assert(!this._applyModelsWasCalled);

		// this._widget.$initModelHandlers(mapModelHandlers);
		Map<String, $ModelHandler> map = this._mapModelHandlerWrappers.map((key, modelHandlerWrapper) => MapEntry(key, modelHandlerWrapper.modelHandler));
		this._widget.$initModelHandlers(map);

		this._applyModelsWasCalled = true;
	}

	WidgetMock _makeWidgetMockFromState(MockWidgetStateBase state) {
		return WidgetMock._init(
			state: state,
		);
	}

	@override
	Map<String, dynamic>? $getDIOverrides() {
		return this.mapDIOverrides;
	}

	List<WidgetMock> getWidgetMocks(String key) {
		List<MockWidgetStateBase> arr = this._mapArrWidgetStates[key] ?? [ ];
		return arr.map((x) => this._makeWidgetMockFromState(x)).toList();
	}

	WidgetMock getSingleWidgetMock(String key) {
		return this.getWidgetMocks(key).single;
	}

	WidgetMock? tryGetSingleWidgetMock(String key) {
		return this.getWidgetMocks(key).singleOrNull();
	}

	TWidget get widget {
		// make sure that _applyModels() was or is called if it's needed
		if (this._mapModelHandlerWrappers.isNotEmpty && !this._applyModelsWasCalled) {
			this._applyModels();
		}
		return this._widget;
	}

	T getModelValue<T>([ String key = SvcZmlParser.DEFAULT_MODEL_KEY ]) => this._mapModelHandlerWrappers[key]!.modelHandler.getModelValue();
	void setModelValue<T>(T value, [ String key = SvcZmlParser.DEFAULT_MODEL_KEY ]) {
		$ModelHandler modelHandler = this._mapModelHandlerWrappers[key]!.modelHandler;
		modelHandler.setModelValue(value);
	}
	int getNumEmits(String key) => this._mapEmitCounters[key] ?? 0;
}