
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/Transformer/TransformerBase.dart';

/// Action:
/// - transform unnamed child(ren) to named child(ren) by detecting if the
///   class has a "child" or "children" named parameters (in the constructor
///   that is being used) and moving the unnamed children under such named
///   parameters.
///
/// Applies to:
/// - any non-child tag (i.e. any constructor tag) that has unnamed children
///   and whose desired constructor supports a "child" or "children" named
///   parameter.
///
/// Scope of changes:
/// - can add a named child.
/// - can clear unnamed children.
///
/// Error conditions:
/// - if there are multiple unnamed children and the respective constructor has
///   a "child" named parameter and no "children" named parameter - an error
///   is logged.
class ChildrenTransformer extends TransformerBase {
	static const String _COMPONENT = "ChildrenTransformer";

	@override
	String getIdentifier() => "childrenTransformer";

	@override
	String getName() => "Children Transformer";

	@override
	bool test(Tag tag) {
		bool ret = true
			&& !tag.isNamedChildTag
			//&& tag.text.isEmpty // allow to have text, because comments are parsed and stored as Tag text (still haven't decided if it's good or bad...)
			&& this._getEffectiveUnnamedChildren(tag).isNotEmpty
			&& (false
				|| this._supportsChildren(tag)
				|| this._supportsChild(tag)
			)
		;
		return ret;
	}

	@override
	void transform(Tag tag) {
		bool supportsChildren = this._supportsChildren(tag);
		List<Tag> arrEffectiveUnnamedChildren = this._getEffectiveUnnamedChildren(tag);

		bool useChildParam = this._supportsChild(tag);
		int numUnnamedChildren = arrEffectiveUnnamedChildren.length;
		if (numUnnamedChildren > 1) {
			useChildParam = false;

			if (!supportsChildren) {
				// this may be ok, if all children have [z-if]s
				if (arrEffectiveUnnamedChildren.any((x) => x.zIf == null)) {
					String constructorName = tag.zCustomConstructorName ?? "default";
					this.svcLogger.logErrorFrom(_COMPONENT, "Tag ${tag} has ${numUnnamedChildren} unnamed children but does not support the \"children\" named parameter (in the ${constructorName} constructor), and the children are not mutually-exclusive (i.e. at least one of them has no [z-if] attribute).");
					return;
				}

				// it's ok!
				useChildParam = true;
			}
		}

		String newTagName;
		if (useChildParam) {
			newTagName = "child";
		}
		else {
			newTagName = "children";
		}

		// does tag already have such a named child? this would be an invalid
		// ZML, but it can technically happen, e.g. if a <Column> has an
		// unnamed <Text> as a direct child, and ALSO a named <children->.
		if (tag.mapNamedChildren.containsKey(newTagName)) {
			this.svcLogger.logErrorFrom(_COMPONENT, "Tag [${tag}] has both unnamed children, AND a named child/children parameter. This is not allowed.");
			return;
		}

		Tag newTag = Tag(parent: tag, name: newTagName, isNamedChildTag: true);
		newTag.arrUnnamedChildren.addAll(arrEffectiveUnnamedChildren);
		newTag.arrUnnamedChildren.forEach((x) => x.parent = newTag);

		tag.addChildTag(newTag);
		tag.arrUnnamedChildren.removeWhere((x) => arrEffectiveUnnamedChildren.contains(x));
	}

	List<Tag> _getEffectiveUnnamedChildren(Tag tag) {
		List<Tag> arrEffectiveUnnamedChildren = tag.arrUnnamedChildren.where((x) => !x.isTypeSlotProvider()).toList();
		return arrEffectiveUnnamedChildren;
	}

	bool _supportsChild(Tag tag) {
		return this.hasParameter(tag, "child");
	}

	bool _supportsChildren(Tag tag) {
		return this.hasParameter(tag, "children");
	}
}