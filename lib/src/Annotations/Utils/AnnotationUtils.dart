
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

typedef _TFuncConvertElementAnnotationToEzAnnotation<T extends EzAnnotationBase> = T? Function(ElementAnnotation);

abstract class EzAnnotationData {

}

class AnnotationUtils {
	static const String _DONT_TOUCH_PREFIX = "_\$";

	static T? tryGetEzAnnotation<T extends EzAnnotationBase>(Element element, _TFuncConvertElementAnnotationToEzAnnotation<T> funcConvert) {
		ElementAnnotation? elementAnnotation = AnnotationUtils.tryGetAnnotation<T>(element);
		if (elementAnnotation == null) {
			return null;
		}
		return funcConvert(elementAnnotation);
	}

	static ElementAnnotation? tryGetAnnotation<T extends EzAnnotationBase>(Element element) {
		Iterable<ElementAnnotation> iterAnnotations = AnnotationUtils._getAnnotations(element);
		String name = T.toString();
		ElementAnnotation? annotation = AnnotationUtils._tryGetAnnotationByName(iterAnnotations, name);
		return annotation;
	}

	static List<ElementAnnotation> _getAnnotations(Element element) {
		return element.metadata;
	}

	static ElementAnnotation? _tryGetAnnotationByName(Iterable<ElementAnnotation> iterAnnotations, String name) {
		Iterable<ElementAnnotation> iter = iterAnnotations.where((x) {
			return x.element?.enclosingElement?.name == name;
		});
		assert(iter.length <= 1);
		if (iter.isEmpty) {
			return null;
		}
		return iter.single;
	}

	static bool hasAnnotation<T extends EzAnnotationBase>(Element element) {
		return (AnnotationUtils.tryGetAnnotation<T>(element) != null);
	}

	static String stripDontTouchPrefix(String s) {
		assert(AnnotationUtils.doesStartWithDontTouchPrefix(s));
		return s.substring(_DONT_TOUCH_PREFIX.length);
	}

	static bool doesStartWithDontTouchPrefix(String s) {
		return s.startsWith(_DONT_TOUCH_PREFIX);
	}

	static DartObject? tryGetAnnotationDataObject(ElementAnnotation elementAnnotation) {
		DartObject? value = elementAnnotation.computeConstantValue();
		return value;
	}

	static Annotation _getAnnotationAst(ElementAnnotation elementAnnotation) {
		Annotation annotationAst = (elementAnnotation as dynamic).annotationAst;
		return annotationAst;
	}

	static Expression? tryGetAnnotationArgumentFromAstByName(ElementAnnotation elementAnnotation, String paramName) {
		Annotation annotationAst = AnnotationUtils._getAnnotationAst(elementAnnotation);
		ArgumentList? argumentList = annotationAst.arguments;
		if (argumentList == null) {
			return null;
		}

		for (int i = 0; i < argumentList.length; i++) {
			Expression? expr = AnnotationUtils.tryGetAnnotationArgumentFromAst(elementAnnotation, i);
			if (expr == null || expr is! NamedExpression) {
				continue;
			}

			String exprName = expr.name.label.name;
			if (exprName == paramName) {
				return expr;
			}
		}

		return null;
	}

	static Expression? tryGetAnnotationArgumentFromAst(ElementAnnotation elementAnnotation, int argumentIdx) {
		// kinda dirty but useful to get the string representation of the type. e.g. in case it's an enum or some other "complicated" type.
		Annotation annotationAst = AnnotationUtils._getAnnotationAst(elementAnnotation);
		ArgumentList? argumentList = annotationAst.arguments;
		if (argumentList == null) {
			return null;
		}

		NodeList<Expression> nodeList = argumentList.arguments;
		if (nodeList.length <= argumentIdx) {
			return null;
		}

		Expression expr = nodeList[argumentIdx];
		return expr;
	}

	static String? tryGetAnnotationArgumentLiteralFromAst(ElementAnnotation elementAnnotation, int argumentIdx) {
		Expression? expr = AnnotationUtils.tryGetAnnotationArgumentFromAst(elementAnnotation, argumentIdx);
		return expr?.toString();
	}
}