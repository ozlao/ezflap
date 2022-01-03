
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzProp/EzPropVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Parser/Mustache/SvcMustacheParser_.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ClassDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/ClassDescriptor/ConstructorDescriptor/ParameterDescriptor/ParameterDescriptor.dart';
import 'package:ezflap/src/Service/Reflector/SvcReflector_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:meta/meta.dart';

abstract class TransformerBase {
	@protected
	@nonVirtual
	SvcLogger get svcLogger => SvcLogger.i();

	@protected
	@nonVirtual
	SvcReflector get svcReflector => SvcReflector.i();

	@protected
	@nonVirtual
	SvcZmlParser get svcZmlParser => SvcZmlParser.i();

	@protected
	@nonVirtual
	SvcZmlTransformer get svcZmlTransformer => SvcZmlTransformer.i();

	@protected
	@nonVirtual
	SvcMustacheParser get svcMustacheParser => SvcMustacheParser.i();

	String getIdentifier();

	String getName();

	/// returns true if the transformer wants to transform the tag.
	bool test(Tag tag);

	/// actually perform the transformations (in-place in the Tags graph)
	void transform(Tag tag);

	@override
	String toString() {
		return "Transformer: ${this.getIdentifier()}, name: ${this.getName()}";
	}

	@protected
	@nonVirtual
	ParameterDescriptor? tryGetParameterDescriptor(Tag tag, String parameterName) {
		String className = tag.name;
		String? constructorName = tag.zCustomConstructorName;
		ParameterDescriptor? parameterDescriptor = this.svcReflector.tryDescribeNamedParameter(className, constructorName, parameterName);
		return parameterDescriptor;
	}

	@protected
	@nonVirtual
	bool hasParameter(Tag tag, String parameterName) {
		String className = tag.name;
		ClassDescriptor? classDescriptor = this.svcReflector.describeClass(className);
		if (classDescriptor == null) {
			return false;
		}

		ParameterDescriptor? parameterDescriptor;
		if (classDescriptor.isEzflapWidget) {
			// it's an ezFlap widget. check by prop.
			// TODO: improve this
			EzPropVisitor ezPropVisitor = EzPropVisitor();
			ezPropVisitor.visitAll(classDescriptor.getStateClassElementAndUp());
			EzPropData? ezPropData = ezPropVisitor.tryGetEzPropData(parameterName);
			return (ezPropData != null);
		}
		else {
			return (this.tryGetParameterDescriptor(tag, parameterName) != null);
		}
	}

	@protected
	@nonVirtual
	bool isTagOfEzflapWidget(Tag tag) {
		String className = tag.name;
		ClassDescriptor? desc = this.svcReflector.describeClass(className);
		return (desc?.isEzflapWidget ?? false);
	}
}