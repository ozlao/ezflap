
// bootstraps SvcReflector (populates it with standard flutter classes)
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Service/Reflector/SvcReflector_.dart';
import 'package:ezflap/src/Utils/EzUtils.dart';

class ReflectorBootstrapper {
	static const String _SDK_PATH = "/home/user/flutter";

	static Future<void> initReflectorForTesting([ String? alternativeCustomEntryPoint ]) async {
		String entryPointPath = ReflectorBootstrapper._getGenericEntryPoint();
		List<String> arrIncludedPaths = [ entryPointPath ];
		if (alternativeCustomEntryPoint != null) {
			arrIncludedPaths.add(alternativeCustomEntryPoint);
		}

		AnalysisContextCollection analysisContextCollection = AnalysisContextCollection(
			includedPaths: arrIncludedPaths,
			sdkPath: _SDK_PATH,
		);

		SvcReflector svcReflector = SvcReflector.i();
		for (String path in arrIncludedPaths) {
			AnalysisContext analysisContext = analysisContextCollection.contextFor(path);
			//SomeResolvedUnitResult resolvedUnitResult = await analysisContext.currentSession.getResolvedUnit2(path);
			SomeResolvedUnitResult resolvedUnitResult = await analysisContext.currentSession.getResolvedUnit(path);
			dynamic unit = (resolvedUnitResult as dynamic).unit;
			CompilationUnitElement compilationUnitElement = unit.declaredElement;
			LibraryElement libraryElement = compilationUnitElement.enclosingElement;
			svcReflector.repopulateAsNeededForTesting(libraryElement);
		}
	}

	static String _getGenericEntryPoint() {
		Uri uri = EzUtils.getCallerUri();
		String dir = EzUtils.getDirFromUri(uri);
		return "${dir}/EntryPoint.dart";
	}
}