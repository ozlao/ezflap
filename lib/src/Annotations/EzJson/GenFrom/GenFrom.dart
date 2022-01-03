
import 'package:ezflap/src/Annotations/EzJson/Utils/EzJsonMixin.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/GenericFieldVisitor.dart';

class GenFrom with EzJsonMixin {
	final GenericFieldVisitor visitor;

	GenFrom(this.visitor);
	
	String generate(String className) {
		String params = this._makeParams();
		String statements = this._makeStatements();
		String paramsWrapper = "";
		if (params.isNotEmpty) {
			paramsWrapper = "{${params}}";
		}

		return """
			${className} from(${paramsWrapper}) {
				${statements}
				
				return this as ${className};
			}
		""";
	}

	String _makeParams() {
		List<String> arr = this.visitor.getArrGenericFieldData()
			.map((GenericFieldData data) {
				String sRequired = "";
				if (data.isLate) {
					sRequired = "required";
				}

				String type = data.typeNode.getFullName();
				return "${sRequired} ${type} ${data.derivedName},";
			})
			.toList()
		;

		return arr.join("\n");
	}

	String _makeStatements() {
		List<String> arr = this.visitor.getArrGenericFieldData()
			.map((GenericFieldData data) {
				String sThis = this.getThisCodeByField(data);
				return "${sThis}.${data.derivedName} = ${data.derivedName};";
			})
			.toList()
		;

		return arr.join("\n");
	}
}