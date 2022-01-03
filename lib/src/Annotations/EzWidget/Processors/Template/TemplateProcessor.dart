
import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzWidget.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/Template/TemplateVisitor.dart';
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:ezflap/src/Service/Zml/Compiler/SvcZmlCompiler_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Service/Zss/Matcher/SvcZssMatcher_.dart';
import 'package:ezflap/src/Service/Zss/Parser/RuleSet/ZssRuleSet.dart';
import 'package:ezflap/src/Service/Zss/Parser/SvcZssParser_.dart';
import 'package:path/path.dart';
import 'package:source_gen/source_gen.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

class TemplateProcessor {
	static const String _COMPONENT = "TemplateProcessor";

	final Element _element;
	final ConstantReader _annotation;
	late TemplateVisitor _visitor;
	String? _zml;
	String? _initialZml;
	List<String> _arrOrderedZsses = [ ];

	TemplateProcessor(this._element, this._annotation) {
		this._prepare();
	}

	SvcLogger get _svcLogger => SvcLogger.i();
	SvcZmlCompiler get _svcZmlCompiler => SvcZmlCompiler.i();
	SvcZmlParser get _svcZmlParser => SvcZmlParser.i();
	SvcZmlTransformer get _svcZmlTransformer => SvcZmlTransformer.i();
	SvcZssParser get _svcZssParser => SvcZssParser.i();
	SvcZssMatcher get _svcZssMatcher => SvcZssMatcher.i();

	void _prepare() {
		this._tryPrepareForFileSystem();
		this._tryPrepareFromAnnotation();
		this._tryPrepareFromVisitor();
	}

	void _tryPrepareForFileSystem() {
		// e.g. /ezflap_tests/lib/App/View/Test3/MyButton/MyButton.dart
		//String? pathFromCompiledPackageRoot = this._element.librarySource?.source.fullName;
		String? pathFromCompiledPackageRoot = this._element.librarySource?.fullName;
		if (pathFromCompiledPackageRoot == null) {
			return;
		}

		Directory curDir = Directory.current;

		// e.g. /home/user/ezflap/ezflap_tests
		String pathOfCompiledPackageRoot = curDir.path;

		String? path = this._tryMakeAbsolutePathForPackageFile(pathFromCompiledPackageRoot, pathOfCompiledPackageRoot);
		if (path == null) {
			return;
		}

		Directory bottomDirectory = Directory(path);
		this._arrOrderedZsses = this._collectZssesFromDirectoryAndParents(bottomDirectory, pathOfCompiledPackageRoot);
	}

	/// for example:
	///   - pathOfCompiledPackageRoot: /ezflap_tests/lib/App/View/Test3/MyButton/MyButton.dart
	///   - pathFromCompiledPackageRoot: /home/user/ezflap/ezflap_tests
	///   - return: /home/user/ezflap/ezflap_tests/lib/App/View/Test3/MyButton/MyButton.dart
	String? _tryMakeAbsolutePathForPackageFile(String pathOfCompiledPackageRoot, String pathFromCompiledPackageRoot) {
		String SEP = Platform.pathSeparator;
		List<String> arrFromCompiledPackageRoot = pathFromCompiledPackageRoot.split(SEP);
		String packagePathName = arrFromCompiledPackageRoot.last;
		if (!pathOfCompiledPackageRoot.startsWith("${SEP}${packagePathName}${SEP}")) {
			// unexpected structure
			return null;
		}

		String parentPath = arrFromCompiledPackageRoot.take(arrFromCompiledPackageRoot.length - 1).join(SEP);
		String finalPathAndFilename = "${parentPath}${pathOfCompiledPackageRoot}";
		File file = File(finalPathAndFilename);
		String finalPath = file.parent.path;
		return finalPath;
	}

	/// returns all files with '.zss' extension in the provided directory, and
	/// in each parent directory, to the root of the package.
	/// the returned list is ordered by the directories (higher directories
	/// are listed first), and internally - by ZSS file names (in ascending
	/// order).
	List<String> _collectZssesFromDirectoryAndParents(Directory bottomDir, String rootPath) {
		List<String> arr = [ ];

		Directory curDir = bottomDir;
		while (curDir.path != rootPath) {
			arr.addAll(this._getZssesInPath(curDir.path));
			curDir = curDir.parent;
		}

		return arr.reversed.toList();
	}

	Map<String, List<String>> _mapCachedZssesInPaths = { };
	List<String> _getZssesInPath(String path) {
		if (!this._mapCachedZssesInPaths.containsKey(path)) {
			Directory dir = new Directory(path);
			this._mapCachedZssesInPaths[path] = dir
				.listSync()
				.map((x) => x.path)
				.where((x) {
					String theExtension = extension(x);
					return (theExtension.toLowerCase() == ".zss");
				})

				// sort descending, because we eventually reverse the whole thing
				.sortByString((x) => x, true)
				.map((x) => File(x).readAsStringSync())
				.toList(growable: false)
			;
		}
		return this._mapCachedZssesInPaths[path]!;
	}

	void _tryPrepareFromAnnotation() {
		ConstantReader? zmlReader = this._annotation.peek(EzWidget.EZ_WIDGET__ZML);
		if (zmlReader != null) {
			if (!zmlReader.isString && !zmlReader.isNull) {
				this._svcLogger.logErrorFrom(_COMPONENT, "The EzWidget's \"zml\" parameter must be a String (or null, to skip).");
			}
			if (zmlReader.isString) {
				this._zml = zmlReader.stringValue;
			}
		}

		ConstantReader? initialZmlReader = this._annotation.peek(EzWidget.EZ_WIDGET__INITIAL_ZML);
		if (initialZmlReader != null) {
			if (!initialZmlReader.isString && !initialZmlReader.isNull) {
				this._svcLogger.logErrorFrom(_COMPONENT, "The EzWidget's \"initialZml\" parameter must be a String (or null, to skip).");
			}
			if (initialZmlReader.isString) {
				this._initialZml = initialZmlReader.stringValue;
			}
		}

		ConstantReader? zssesReader = this._annotation.peek(EzWidget.EZ_WIDGET__ZSSES);
		if (zssesReader != null) {
			if (!zssesReader.isList && !zssesReader.isNull) {
				this._svcLogger.logErrorFrom(_COMPONENT, "The EzWidget's \"zsses\" parameter must be a List<String> (or null, to skip).");
			}
			if (zssesReader.isList) {
				List<DartObject> arrZssesObjects = zssesReader.listValue;
				for (DartObject obj in arrZssesObjects) {
					String? zss = obj.toStringValue();
					if (zss != null) {
						this._arrOrderedZsses.add(this._addZssRootTagIfNeeded(zss));
					}
				}
			}
		}

		ConstantReader? zssReader = this._annotation.peek(EzWidget.EZ_WIDGET__ZSS);
		if (zssReader != null) {
			if (!zssReader.isString && !zssReader.isNull) {
				this._svcLogger.logErrorFrom(_COMPONENT, "The EzWidget's \"zss\" parameter must be a String (or null, to skip).");
			}
			if (zssReader.isString) {
				this._arrOrderedZsses.add(this._addZssRootTagIfNeeded(zssReader.stringValue));
			}
		}
	}

	void _tryPrepareFromVisitor() {
		this._visitor = this._visit();
		
		if (this._zml != null && this._visitor.zml != null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Do not provide ZML in both the ${TemplateVisitor.ZML_ELEMENT_NAME} constant and the EzWidget annotation.");
		}
		
		if (this._initialZml != null && this._visitor.initialZml != null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Do not provide Initial ZML in both the ${TemplateVisitor.INITIAL_ZML_ELEMENT_NAME} constant and the EzWidget annotation.");
		}
		
		this._zml ??= this._visitor.zml;
		this._initialZml ??= this._visitor.initialZml;

		if (this._visitor.zss != null) {
			String zss = this._addZssRootTagIfNeeded(this._visitor.zss!);
			this._arrOrderedZsses.add(zss);
		}
	}

	String _addZssRootTagIfNeeded(String zss) {
		String ZSS_TAG_NAME = SvcZssParser.ZSS_TAG_NAME;
		if (!zss.trimLeft().startsWith("<${ZSS_TAG_NAME}>")) {
			zss = "<${ZSS_TAG_NAME}>${zss}</${ZSS_TAG_NAME}>";
		}
		return zss;
	}

	AstNodeWrapper? processPrimary() {
		return this._processZmlOrLogError(this._zml, TemplateVisitor.ZML_ELEMENT_NAME);
	}

	AstNodeWrapper? processInitial() {
		if (this._initialZml == null) {
			return null;
		}
		return this._process(this._initialZml!);
	}

	AstNodeWrapper? _processZmlOrLogError(String? zml, String zmlElementName) {
		if (zml == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "Template not found or is empty. Did you provide it in the EzWidget's \"zml\" parameter, or a 'static const String ${zmlElementName}' field?");
			return null;
		}
		return this._process(zml);
	}

	String? _tryGetMergedZss() {
		if (this._arrOrderedZsses.isEmpty) {
			return null;
		}

		return _arrOrderedZsses.join("\n");
	}

	AstNodeWrapper? _process(String zml) {
		Tag? rootTag = this._svcZmlParser.tryParse(zml);
		if (rootTag == null) {
			return null;
		}

		Tag transformedRootTag = this._svcZmlTransformer.transform(rootTag);

		String? zss = this._tryGetMergedZss();
		if (zss != null) {
			ZssRuleSet? zssRuleSet = this._svcZssParser.parse(zss, transformedRootTag);
			if (zssRuleSet != null) {
				this._svcZssMatcher.matchZssToTags(transformedRootTag, zssRuleSet);
			}
		}

		AstNodeWrapper? wrapperAstNode = this._svcZmlCompiler.tryGenerateAst(transformedRootTag);
		return wrapperAstNode;
	}

	TemplateVisitor _visit() {
		TemplateVisitor visitor = TemplateVisitor();
		this._element.visitChildren(visitor);
		return visitor;
	}
}