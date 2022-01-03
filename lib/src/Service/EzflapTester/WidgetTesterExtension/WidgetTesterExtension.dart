
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtension on WidgetTester {
	Future<void> pumpWidgetIntoScaffold(Widget widget, [ bool withExtraTick = true ]) async {
		await this.pumpWidget(
			MaterialApp(
				home: Scaffold(
					body: widget
				)
			)
		);

		if (withExtraTick) {
			// build seems to be called twice on Widget initialization. not sure
			// why, but it messes up some tests (because the second build happens
			// only after the first pumpWithSeconds(), which is usually pumping
			// 1 second. this causes this second build to run, and it can mess up
			// tests result if they rely on non-reactive data (because build()
			// would get run even if no reactive data has been modified, and this
			// can be confusing when working with non-reactive data and trying to
			// ensure that non-reactive data does NOT cause a build).
			await this.pumpTick();
		}
	}

	Future<void> pumpTick() async {
		await this.pumpWithMilliseconds(0);
	}

	Future<void> pumpWithMilliseconds(int milliseconds) async {
		await this.pump(Duration(milliseconds: milliseconds));
	}

	Future<void> pumpWithSeconds(int seconds) async {
		await this.pump(Duration(seconds: seconds));
	}

	Future<void> tapAndTickByFinder(Finder finder) async {
		await this.tap(finder);
		await this.pumpTick();
	}

	void setScreenDimensions(double width, double height) {
		this.binding.window.physicalSizeTestValue = Size(width, height);
	}

	void multiplyScreenDimensionsBy(double widthFactor, double heightFactor) {
		Size curSize = this.binding.window.physicalSize;
		double width = curSize.width * widthFactor;
		double height = curSize.height * heightFactor;
		this.setScreenDimensions(width, height);
	}

	void multiplyScreenWidthBy(double factor) {
		this.multiplyScreenDimensionsBy(factor, 1);
	}

	void multiplyScreenHeightBy(double factor) {
		this.multiplyScreenDimensionsBy(1, factor);
	}

	Future<void> tapAndTick(String key) async {
		await this.tapAndTickByFinder(find.byKey(Key(key)));
	}

	// in some cases a rendered data changes a tick later (e.g. when a prop
	// changes, the actual change takes place only one tick after didUpdateWidget()
	// is called.
	Future<void> pumpWithSecondsPlusTick(int seconds) async {
		await this.pumpWithSeconds(seconds);
		await this.pumpTick();
	}
}
