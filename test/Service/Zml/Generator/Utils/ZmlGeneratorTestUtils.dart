
// ignore_for_file: avoid_print

import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:ezflap/src/Service/Zml/Compiler/SvcZmlCompiler_.dart';
import 'package:ezflap/src/Service/Zml/Generator/AnnotationsSummary/AnnotationsSummary.dart';
import 'package:ezflap/src/Service/Zml/Generator/SvcZmlGenerator_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Service/Zss/Matcher/SvcZssMatcher_.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';
import 'package:ezflap/src/Service/Zss/Parser/RuleSet/ZssRuleSet.dart';
import 'package:ezflap/src/Service/Zss/Parser/SvcZssParser_.dart';
import 'package:ezflap/src/Utils/EZ/EZ.dart';
import 'package:flutter_test/flutter_test.dart';

String t(String s) {
	return "\"\"\"${s}\"\"\",";
}

class ZmlGeneratorTestUtils {
	static AstNodeWrapper verifyDart({ required String zml, required String dart, String? zss, bool getBuilderZssStyleFunctionsInstead = false }) {
		SvcLogger svcLogger = SvcLogger.i();
		SvcZmlCompiler svcZmlCompiler = SvcZmlCompiler.i();
		SvcZmlGenerator svcZmlGenerator = SvcZmlGenerator.i();
		SvcZmlParser svcZmlParser = SvcZmlParser.i();
		SvcZmlTransformer svcZmlTransformer = SvcZmlTransformer.i();
		SvcZssParser svcZssParser = SvcZssParser.i();
		SvcZssMatcher svcZssMatcher = SvcZssMatcher.i();

		svcZmlTransformer.bootstrapDefaultTransformers();
		StylingTag.resetNextUidForTesting();

		AstNodeBase? maybeNode;
		svcLogger.invoke(() {
			Tag? maybeTag = svcZmlParser.tryParse(zml);

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			Tag transTag = svcZmlTransformer.transform(tag);

			if (zss != null) {
				ZssRuleSet? maybeZssRuleSet = svcZssParser.parse(zss, transTag);
				expect(maybeZssRuleSet != null, true);

				svcZssMatcher.matchZssToTags(transTag, maybeZssRuleSet!);
			}

			maybeNode = svcZmlCompiler.tryGenerateAst(transTag);
		});
		if (svcLogger.hasLoggedErrors()) {
			svcLogger.printLoggedErrorsIfNeeded();
			expect(false, true);
		}

		expect(maybeNode != null, true);

		AstNodeBase nodeBase = maybeNode!;
		expect(nodeBase is AstNodeWrapper, true);

		AstNodeWrapper wrapper = nodeBase as AstNodeWrapper;

		String code;
		if (zss != null && getBuilderZssStyleFunctionsInstead) {
			code = svcZmlGenerator.generateBuilderZssStyleFunctions(wrapper);
		}
		else {
			code = svcZmlGenerator.generateBuilderContent(wrapper, AnnotationsSummary.empty());
		}

		String comparableCode = EZ.removeWhitespaces(code);
		String expected = EZ.removeWhitespaces(dart);
		if (comparableCode != expected) {
			print("Expected: ${dart}");
			print("Actual: ${code}");
		}

		expect(comparableCode, expected);

		return wrapper;
	}
}