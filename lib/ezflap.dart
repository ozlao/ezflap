// ignore_for_file: invalid_export_of_internal_element

library ezflap;

export 'package:ezflap/src/Annotations/Common/EzValue/EzValue.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzWidget.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzField/EzField.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzMethod/EzMethod.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzComputed/EzComputed.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzWatch/EzWatch.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzProp/EzProp.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzRef/EzRef.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzRefs/EzRefs.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzModel/EzModel.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzEmit/EzEmit.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzOptionalModel/EzOptionalModel.dart';
export 'package:ezflap/src/Annotations/EzWidget/EzRouteParam/EzRouteParam.dart';
export 'package:ezflap/src/Annotations/EzReactive/EzReactive.dart';
export 'package:ezflap/src/Annotations/EzJson/EzJson.dart';
export 'package:ezflap/src/Annotations/EzWithDI/EzDI/EzDI.dart';
export 'package:ezflap/src/Annotations/EzWithDI/EzDIProvider/EzDIProvider.dart';
export 'package:ezflap/src/Annotations/EzService/EzService.dart';
export 'package:ezflap/src/View/EzState/EzStateBase.dart';
export 'package:ezflap/src/View/EzStatefulWidget/EzStatefulWidgetBase.dart';
export 'package:ezflap/src/View/EzStatefulWidget/SlotProvider/SlotProvider.dart';
export 'package:ezflap/src/View/EzState/ComputedHandler/ComputedHandler.dart';
export 'package:ezflap/src/View/EzState/WatchHandler/WatchHandler.dart';
export 'package:ezflap/src/View/EzState/ModelHandler/ModelHandler.dart';
export 'package:ezflap/src/Utils/Singleton/Singleton.dart';
export 'package:ezflap/src/Utils/Tick/Tick.dart';
export 'package:ezflap/src/Utils/Guid/Guid.dart';
export 'package:ezflap/src/Utils/EZ/EZ.dart';
export 'package:ezflap/src/Utils/Rx/RxWrapper/RxWrapper.dart';
export 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
export 'package:ezflap/src/Service/EzServiceBase.dart';
export 'package:ezflap/src/Service/DependencyInjector/ProviderBase.dart';
export "package:ezflap/src/Service/DependencyInjector/ResolverBase.dart";
export 'package:ezflap/src/Service/EzflapTester/Wrapper/TestWrapperMixin.dart';
export 'package:ezflap/src/Service/EzflapTester/Wrapper/WidgetWrapper.dart';
export 'package:meta/meta.dart';

// this makes pub.dev complain that this and dependent packages are not suitable
// for Web, because of the implicit dependency on dart:io (which comes from
// package:flutter_test/src/platform.dart, which is an indirect dependent of
// package:flutter_test/flutter_test.dart). so, for now - this file will need
// to be imported into tests explicitly.
//export 'package:ezflap/src/Service/EzflapTester/WidgetTesterExtension/WidgetTesterExtension.dart';
