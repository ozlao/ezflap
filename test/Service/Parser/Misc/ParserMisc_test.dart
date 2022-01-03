
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	group("Testing misc parsers stuff", () {
		test("Type String.splitAndTrim", () {
			// hello world
			// -->
			// hello
			// world
			go("hello world", [ "hello", "world" ]);

			// "hello world"
			// -->
			// "hello world"
			go("\"hello world\"",
				[
					"\"hello world\"",
				]
			);

			// "hello world" "nihao shijie"
			// -->
			// "hello world"
			// "nihao shijie"
			go("\"hello world\" \"nihao shijie\"",
				[
					"\"hello world\"",
					"\"nihao shijie\"",
				]
			);

			// 'hello world' "nihao shijie"
			// -->
			// 'hello world'
			// "nihao shijie"
			go("'hello world' \"nihao shijie\"",
				[
					"'hello world'",
					"\"nihao shijie\"",
				]
			);

			// "hello 'world nihao' shijie"
			// -->
			// "hello 'world nihao' shijie"
			go("\"hello 'world nihao' shijie\"",
				[
					"\"hello 'world nihao' shijie\"",
				]
			);

			// "hello 'world" nihao' shijie
			// -->
			// "hello 'world"
			// nihao'
			// shijie
			go("\"hello 'world\" nihao' shijie",
				[
					"\"hello 'world\"",
					"nihao'",
					"shijie",
				]
			);

			// "hello 'world nihao' shijie
			// -->
			// "hello
			// 'world nihao'
			// shijie
			go("\"hello 'world nihao' shijie",
				[
					"\"hello",
					"'world nihao'",
					"shijie",
				]
			);

			// "hello'world" nihao'shijie
			// -->
			// "hello'world" nihao'shijie
			go("\"hello'world\" nihao'shijie",
				[
					"\"hello'world\" nihao'shijie",
				]
			);

			// "hello'world" nihao' shijie
			// -->
			// "hello'world" nihao'
			// shijie
			go("\"hello'world\" nihao' shijie",
				[
					"\"hello'world\" nihao'",
					"shijie",
				]
			);

			// "hello'world" nihao' shijie'
			// -->
			// "hello'world" nihao'
			// shijie'
			go("\"hello'world\" nihao' shijie'",
				[
					"\"hello'world\" nihao'",
					"shijie'",
				]
			);

			// "hello'world" ni'hao"shi jie"
			// -->
			// "hello'world" ni'hao"shi
			// jie"
			go("\"hello'world\" ni'hao\"shi jie\"",
				[
					"\"hello'world\" ni'hao\"shi",
					"jie\"",
				]
			);
		});
	});
}

void go(String s, List<String> arrExpected) {
	List<String> arr = s.splitAndTrim(" ", respectQuotes: true)!;
	expect(arr.length, arrExpected.length);
	for (int i = 0; i < arr.length; i++) {
		expect(arr[i], arrExpected[i]);
	}
}