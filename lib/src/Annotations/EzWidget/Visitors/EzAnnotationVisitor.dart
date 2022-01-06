
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:meta/meta.dart';

abstract class EzAnnotationVisitor<T extends EzAnnotationBase, U extends EzAnnotationData, V extends Element> extends SimpleElementVisitor {
	@protected
	SvcLogger get svcLogger { return SvcLogger.i(); }

	static const String _COMPONENT = "EzAnnotationVisitor";

	List<U> _arrEzAnnotationData = [ ];

	void visitAll(List<ClassElement> arrElements) {
		for (ClassElement el in arrElements) {
			el.visitChildren(this);
		}
	}

	List<U> getEzAnnotationData() {
		return this._arrEzAnnotationData;
	}

	void forEach(void Function(U data) func) {
		for (U data in this._arrEzAnnotationData) {
			func(data);
		}
	}
	
	@protected
	void process(Element element) {
		ElementAnnotation? elementAnnotation = AnnotationUtils.tryGetAnnotation<T>(element);
		if (elementAnnotation == null) {
			return;
		}

		DartObject? objValue = AnnotationUtils.tryGetAnnotationDataObject(elementAnnotation);
		if (objValue == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "failed to get value (with computeConstantValue()) for ElementAnnotation: ${elementAnnotation}");
			return;
		}

		T? ezAnnotation = this.convertFromAnnotation(objValue, elementAnnotation);
		if (ezAnnotation == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "failed to get EzAnnotation for ElementAnnotation: ${elementAnnotation} and computed value: ${objValue}");
			return;
		}

		U? ezAnnotationData = this.makeData(ezAnnotation, element as V, objValue, elementAnnotation);
		if (ezAnnotationData == null) {
			this.svcLogger.logErrorFrom(_COMPONENT, "failed to get EzAnnotationData for ElementAnnotation: ${elementAnnotation} and EzAnnotation: ${ezAnnotation}");
			return;
		}

		this._arrEzAnnotationData.add(ezAnnotationData);
	}
	
	T? convertFromAnnotation(DartObject objValue, ElementAnnotation elementAnnotation);

	// we need to pass objValue and the rest to makeData() because in some cases
	// we can't extract all data into the annotation class. for example, EzRefs
	// requires the refs map's key type, which is provided by the user as Type
	// (in EzRef.keyType), but we can't get Type when processing objValue; we
	// can only get DartType, and so the annotation class can't be used to pass
	// this around. a better solution may be to not mess around with the
	// annotation class at all; i.e. get rid of convertFromAnnotation() and
	// only do makeData(). we will probably refactor to this in the future.
	U? makeData(T ezAnnotation, V element, DartObject objValue, ElementAnnotation elementAnnotation);
}