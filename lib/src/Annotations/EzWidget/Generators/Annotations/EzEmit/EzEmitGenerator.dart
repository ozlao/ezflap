
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzEmit/EzEmit.dart';
import 'package:ezflap/src/Annotations/EzWidget/Generators/Annotations/Base/GeneratorBase.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzEmit/EzEmitVisitor.dart';

class EzEmitGenerator extends AnnotationGeneratorBase<EzEmit, EzEmitData, FieldElement> {
	EzEmitGenerator(ClassElement element, EzAnnotationVisitor<EzEmit, EzEmitData, FieldElement> visitor) : super(element, visitor);

	static const String _COMPONENT = "EzEmitGenerator";

	@override
	String? generateItemForInState(EzEmitData data) {
		int numParameters = this._getNumParameters(data);
		String sParameters = List.generate(numParameters, (x) => "_${x}").join(", ");
		String functionParenthesesPart = "(${sParameters})";
		String ch = this.getUnderscoreIfNotExtended();
		String protectedSnippet = this.getProtectedSnippetIfExtended();

		return """
			${protectedSnippet}
			${data.typeWithNullability} get ${ch}${data.derivedName} {
				Function? func = this.widget.\$tryGetEmitHandler("${data.assignedName}");
				//if (func == null) {
				//	return ${functionParenthesesPart} {
				//	};
				//}
				//return func as ${data.typeWithNullability};
				
				return ${functionParenthesesPart} {
					this.widget.\$onEmitHandlerInvoked("${data.assignedName}");
					func?.call${functionParenthesesPart};
				};
			}
		""";
	}

	int _getNumParameters(EzEmitData data) {
		String functionParenthesesPart = data.functionParenthesesPart;
		int start = functionParenthesesPart.indexOf("(");
		int end = -1;
		if (start != -1) {
			end = functionParenthesesPart.indexOf(")", start);
		}

		if (start == -1 || end == -1) {
			this.svcLogger.logErrorFrom(_COMPONENT, "invalid EzEmitData with functionParenthesesPart: [${functionParenthesesPart}]");
			return 0;
		}

		String middle = functionParenthesesPart.substring(start + 1, end);
		if (middle.trim().isEmpty) {
			// zero parameters
			return 0;
		}

		int numParameters = 1;
		int numTriangles = 0;
		for (int i = start + 1; i < functionParenthesesPart.length; i++) {
			String ch = functionParenthesesPart[i];
			if (ch == "<") {
				numTriangles++;
			}
			else if (ch == ">") {
				numTriangles--;
			}
			else if (ch == "," && numTriangles == 0) {
				numParameters++;
			}
		}

		return numParameters;
	}

	@override
	String? generateItemForInHost(EzEmitData data) {
		String ch = this.getUnderscoreIfNotExtended();
		return """
			${data.typeWithNullability} get ${data.assignedName} => this._ezState.${ch}${data.derivedName};
		""";
	}
}