
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ClassDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ConstructorDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ParameterDescriptor/ParameterDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/SvcReflector_.dart';
import 'package:ezflap/src/Utils/EzUtils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../Bootstrapper/ReflectorBootstrapper.dart';

SvcReflector svcReflector = SvcReflector.i();

Future<void> main() async {
	SvcLogger svcLogger = SvcLogger.i();
	String dir = EzUtils.getDirFromUri(EzUtils.getCallerUri());
	String customEntryPoint = "${dir}/SvcReflector_test_CustomEntryPoint.dart";
	await ReflectorBootstrapper.initReflectorForTesting(customEntryPoint);

	group("Testing SvcReflector", () {
		test("sanity test", () async {
			ClassDescriptor? text = svcReflector.describeClass("Text");
			expect(text != null, true);

			ParameterDescriptor? textParam1 = svcReflector.describeOrderedParameter("Text", null, 0);
			expect(textParam1 != null, true);
			expect(textParam1!.name, "data");
		});

		test("classes", () {
			ClassDescriptor? descNotExists = svcReflector.describeClass("ReflectorTest1_does_not_exist");
			expect(descNotExists == null, true);

			ClassDescriptor? descStandalone = svcReflector.describeClass("ReflectorTestStandalone");
			expect(descStandalone != null, true);
			expect(descStandalone!.name, "ReflectorTestStandalone");
			expect(descStandalone.isEzflapWidget, false);

			ClassDescriptor? descStandaloneGeneric = svcReflector.describeClass("ReflectorTestStandaloneGeneric");
			expect(descStandaloneGeneric != null, true);
			expect(descStandaloneGeneric!.name, "ReflectorTestStandaloneGeneric");
			expect(descStandaloneGeneric.isEzflapWidget, false);

			ClassDescriptor? descExtend = svcReflector.describeClass("ReflectorTestExtend");
			expect(descExtend != null, true);
			expect(descExtend!.name, "ReflectorTestExtend");
			expect(descExtend.isEzflapWidget, false);

			ClassDescriptor? descExtendGeneric = svcReflector.describeClass("ReflectorTestExtendGeneric");
			expect(descExtendGeneric != null, true);
			expect(descExtendGeneric!.name, "ReflectorTestExtendGeneric");
			expect(descExtendGeneric.isEzflapWidget, false);

			ClassDescriptor? descExtendEzState = svcReflector.describeClass("ReflectorTestExtendEzStatefulWidget");
			expect(descExtendEzState != null, true);
			expect(descExtendEzState!.name, "ReflectorTestExtendEzStatefulWidget");
			expect(descExtendEzState.isEzflapWidget, true);

			ClassDescriptor? descMixin = svcReflector.describeClass("ReflectorTestMixin");
			expect(descMixin != null, true);
			expect(descMixin!.name, "ReflectorTestMixin");
			expect(descMixin.isEzflapWidget, false);
		});

		test("constructors", () {
			ClassDescriptor? descConstructors = svcReflector.describeClass("ReflectorTestConstructors");
			expect(descConstructors != null, true);
			expect(descConstructors!.name, "ReflectorTestConstructors");
			expect(descConstructors.isEzflapWidget, false);

			ConstructorDescriptor? descDefaultConstructor = svcReflector.describeConstructor(descConstructors, null);
			expect(descDefaultConstructor != null, true);
			expect(descDefaultConstructor!.name, null);

			ConstructorDescriptor? descNotExistsConstructor = svcReflector.describeConstructor(descConstructors, "not_exists");
			expect(descNotExistsConstructor == null, true);

			ConstructorDescriptor? descCon1 = svcReflector.describeConstructor(descConstructors, "con1");
			expect(descCon1 != null, true);
			expect(descCon1!.name, "con1");

			ConstructorDescriptor? descCon2 = svcReflector.describeConstructor(descConstructors, "con2");
			expect(descCon2 != null, true);
			expect(descCon2!.name, "con2");
		});

		test("parameters", () {
			testParameter(null, 0, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter(null, 1, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);

			testParameter("con1", 0, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter("con1", 1, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);

			testParameter("con2", 0, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter("con2", 1, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter("con2", 2, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);

			testParameter("con3", 0, isRequired: true, isList: false, isNullable: true, defaultValueLiteral: null);
			testParameter("con3", 1, isRequired: true, isList: false, isNullable: true, defaultValueLiteral: null);

			testParameter("con4", 0, isRequired: true, isList: false, isNullable: true, defaultValueLiteral: null);
			testParameter("con4", 1, isRequired: false, isList: false, isNullable: true, defaultValueLiteral: null);

			testParameter("con5", 0, isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "42");
			testParameter("con5", 1, isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "\"hello world\"");

			testParameter("con6", "p1", isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "42");
			testParameter("con6", "p2", isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "\"hello world\"");

			testParameter("con7", 0, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter("con7", "p2", isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "\"hello world\"");

			testParameter("con8", 0, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter("con8", "p2", isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);

			testParameter("con9", 0, isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "42 * 88");
			testParameter("con10", 0, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter("con11", 0, isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "const ReflectorTestAux()");
			testParameter("con12", 0, isRequired: false, isList: false, isNullable: false, defaultValueLiteral: "EReflectorTestAux.enumValue2");
			testParameter("con13", 0, isRequired: true, isList: true, isNullable: false, defaultValueLiteral: null);
			testParameter("con14", 0, isRequired: true, isList: true, isNullable: false, defaultValueLiteral: null);
			testParameter("con15", 0, isRequired: true, isList: false, isNullable: false, defaultValueLiteral: null);
			testParameter("con16", 0, isRequired: true, isList: true, isNullable: false, defaultValueLiteral: null);
			testParameter("con17", 0, isRequired: false, isList: true, isNullable: false, defaultValueLiteral: "const [{\"key\" : [[88]]}]");
		});
	});
}

void testParameter(String? constructorName, dynamic parameterNameOrIdx, { required bool isRequired, required bool isList, required bool isNullable, required String? defaultValueLiteral, String? overrideClassName }) {
	String className = overrideClassName ?? "ReflectorTestConstructors";

	ParameterDescriptor? parameterDescriptor;
	dynamic expectedName = parameterNameOrIdx;
	dynamic expectedIdx = parameterNameOrIdx;
	if (parameterNameOrIdx is String) {
		parameterDescriptor = svcReflector.describeNamedParameter(className, constructorName, parameterNameOrIdx);
		expectedIdx = null;
	}
	else if (parameterNameOrIdx is int) {
		parameterDescriptor = svcReflector.describeOrderedParameter(className, constructorName, parameterNameOrIdx);
		expectedName = null;
	}
	else assert(false);

	expect(parameterDescriptor != null, true);
	if (expectedName != null) { // we need this [if] because positional parameters have names too...
		expect(parameterDescriptor!.name, expectedName);
	}
	expect(parameterDescriptor!.idx, expectedIdx);
	expect(parameterDescriptor.isRequired, isRequired);
	expect(parameterDescriptor.isList, isList);
	expect(parameterDescriptor.isNullable, isNullable);
	expect(parameterDescriptor.defaultValueLiteral, defaultValueLiteral);
}