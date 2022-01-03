
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/EzAnnotationVisitor.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:meta/meta.dart';

class SplitCode {
	late List<String> arrInState;
	late List<String> arrInStateInitState;
	late List<String> arrInStateRefreshProps;
	late List<String> arrInBuildHost;
	late List<String> arrInBuildHostInitState;

	SplitCode({
		List<String>? arrInState,
		List<String>? arrInStateInitState,
		List<String>? arrInHost,
		List<String>? arrInStateRefreshProps,
		List<String>? arrInHostInitState,
	}) {
		this.arrInState = arrInState ?? [ ];
		this.arrInStateInitState = arrInStateInitState ?? [ ];
		this.arrInStateRefreshProps = arrInStateRefreshProps ?? [ ];
		this.arrInBuildHost = arrInHost ?? [ ];
		this.arrInBuildHostInitState = arrInHostInitState ?? [ ];
	}
}

abstract class AnnotationGeneratorBase<T extends EzAnnotationBase, U extends EzAnnotationData, V extends Element> {
	final ClassElement _element;
	final EzAnnotationVisitor<T, U, V> visitor;

	AnnotationGeneratorBase(this._element, this.visitor) {
		this._element.visitChildren(visitor);
	}

	@protected
	SvcLogger get svcLogger { return SvcLogger.i(); }

	@protected
	@nonVirtual
	bool isExtended() {
		return this._element.isAbstract;
	}

	@protected
	@nonVirtual
	String getUnderscoreIfNotExtended() {
		return (this.isExtended() ? "" : "_");
	}

	@protected
	@nonVirtual
	String getProtectedSnippetIfExtended() {
		if (!this.isExtended()) {
			return "";
		}
		return """
			@protected
			@nonVirtual
		""";
	}

	SplitCode generate() {
		SplitCode splitCode = SplitCode();

		visitor.forEach((U data) {
			String? forInState = this.generateItemForInState(data);
			if (forInState != null) {
				splitCode.arrInState.add(forInState);
			}

			String? forInInitState = this.generateItemForInInitState(data);
			if (forInInitState != null) {
				splitCode.arrInStateInitState.add(forInInitState);
			}

			String? forInHost = this.generateItemForInHost(data);
			if (forInHost != null) {
				splitCode.arrInBuildHost.add(forInHost);
			}

			String? forInRefreshProps = this.generateItemForInRefreshProps(data);
			if (forInRefreshProps != null) {
				splitCode.arrInStateRefreshProps.add(forInRefreshProps);
			}

			String? forInHostInitState = this.generateItemForInHostInitState(data);
			if (forInHostInitState != null) {
				splitCode.arrInBuildHostInitState.add(forInHostInitState);
			}
		});

		return splitCode;
	}

	@protected
	String? generateItemForInState(U data) { return null; }
	String? generateItemForInInitState(U data) { return null; }
	String? generateItemForInHost(U data) { return null; }
	String? generateItemForInRefreshProps(U data) { return null; }
	String? generateItemForInHostInitState(U data) { return null; }
}