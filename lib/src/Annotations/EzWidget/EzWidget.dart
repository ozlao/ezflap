
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

class EzWidget extends EzAnnotationBase {
	static const String EZ_WIDGET__ZML = "zml";
	static const String EZ_WIDGET__INITIAL_ZML = "initialZml";
	static const String EZ_WIDGET__ZSS = "zss";
	static const String EZ_WIDGET__ZSSES = "zsses";
	static const String EZ_WIDGET__EXTEND = "extend";

	final String? zml;
	final String? initialZml;
	final String? zss;
	final List<String>? zsses;
	final Type? extend;

	const EzWidget({
		this.zml,
		this.initialZml,
		this.zss,
		this.zsses,
		this.extend,
	});
}