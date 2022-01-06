
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWithDI/EzDI/EzDI.dart';
import 'package:ezflap/src/Annotations/EzWithDI/EzDIProvider/EzDIProvider.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/GenericFieldVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';

// TODO: move this stuff to a service
class EzWithDIGenerator {
	static const String _COMPONENT = "EzWithDIGenerator";

	SvcLogger get _svcLogger => SvcLogger.i();

	static String generateForEzDIs(Element element, { required bool supportOverrides }) {
		GenericFieldVisitor visitor = GenericFieldVisitor((x) => AnnotationUtils.hasAnnotation<EzDI>(x.element));
		element.visitChildren(visitor);

		List<GenericFieldData> arrFields = visitor.getArrGenericFieldData();
		List<String> arrParts = arrFields
			.map((x) {
				String overridesPart = "";
				if (supportOverrides) {
					overridesPart = "mapOverrides?[\"${x.coreTypeName}\"] ??";
				}

				return """
					(this as dynamic).${x.name} = ${overridesPart} ${x.coreTypeName}.i();
				""";
			})
			.toList()
		;

		String block = arrParts.join("\n");
		String sOverridesParameter = "";
		if (supportOverrides) {
			sOverridesParameter = "[ Map<String, dynamic>? mapOverrides ]";
		}

		return """
			@override
			void \$initDI(${sOverridesParameter}) {
				super.\$initDI(mapOverrides);
				${block}
			}
		""";
	}

	static String generateForEzDIProviders(Element element) {
		GenericFieldVisitor visitor = GenericFieldVisitor((x) => AnnotationUtils.hasAnnotation<EzDIProvider>(x.element));
		element.visitChildren(visitor);

		List<GenericFieldData> arrFields = visitor.getArrGenericFieldData();
		List<String> arrParts = [ ];
		for (GenericFieldData field in arrFields) {
			ElementAnnotation? elementAnnotation = AnnotationUtils.tryGetAnnotation<EzDIProvider>(field.element);
			if (elementAnnotation == null) {
				continue;
			}

			String? sResolverTypeName = AnnotationUtils.tryGetAnnotationArgumentLiteralFromAst(elementAnnotation, 0);
			if (sResolverTypeName == null) {
				continue;
			}

			String s = """
				${field.coreTypeName} get _${field.derivedName} {
					${sResolverTypeName} resolver = ${sResolverTypeName}.i();
					${field.coreTypeName} provider = resolver.resolve() as ${field.coreTypeName};
					return provider;
				}
			""";
			arrParts.add(s);
		}

		return arrParts.join("\n");
	}
}