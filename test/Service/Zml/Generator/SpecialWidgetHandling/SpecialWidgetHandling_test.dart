
import 'package:flutter_test/flutter_test.dart';

import '../../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';
import '../Utils/ZmlGeneratorTestUtils.dart';

void _verifyDart({ required String zml, required String dart }) {
	ZmlGeneratorTestUtils.verifyDart(zml: zml, dart: dart);
}

void main() {
	group("Testing SvcZmlGenerator", () {
		ReflectorBootstrapper.initReflectorForTesting();

		List<String> arrChildNames = [
			"Directionality",
			"Opacity",
			"ShaderMask",
			"BackdropFilter",
			"CustomPaint",
			"ClipRect",
			"ClipRRect",
			"ClipOval",
			"ClipPath",
			"PhysicalModel",
			"PhysicalShape",
			"Transform",
			"CompositedTransformTarget",
			"CompositedTransformFollower",
			"FittedBox",
			"FractionalTranslation",
			"RotatedBox",
			"Padding",
			"Align",
			"Center",
			"CustomSingleChildLayout",
			"LayoutId",
			"SizedBox",
			"ConstrainedBox",
			"ConstraintsTransformBox",
			"UnconstrainedBox",
			"FractionallySizedBox",
			"LimitedBox",
			"OverflowBox",
			"SizedOverflowBox",
			"Offstage",
			"AspectRatio",
			"IntrinsicWidth",
			"IntrinsicHeight",
			"Baseline",
			"SliverToBoxAdapter",
			"Positioned",
			"PositionedDirectional",
			"Flexible",
			"Expanded",
			"DefaultAssetBundle",
			"Listener",
		];
		for (String tagName in arrChildNames) {
			test("Generator test - [Basic.dart][${tagName} (single-child)] - ${tagName} with a child", () {
				_verifyDart(
					zml: """
						<${tagName}>
							<Text>Text</Text>
						</${tagName}>
					""",

					dart: """
						return (${tagName}(
							child: (Text(\"""Text\""",))
						));
					""",
				);
			});
		}

		test("Generator test - [Basic.dart][CustomMultiChildLayout (multi-child)] - CustomMultiChildLayout with one child", () {
			_verifyDart(
				zml: """
					<CustomMultiChildLayout>
						<Text>Text</Text>
					</CustomMultiChildLayout>
				""",

				dart: """
					return (CustomMultiChildLayout(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][CustomMultiChildLayout (multi-child)] - CustomMultiChildLayout with children", () {
			_verifyDart(
				zml: """
					<CustomMultiChildLayout>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</CustomMultiChildLayout>
				""",

				dart: """
					return (CustomMultiChildLayout(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});


		test("Generator test - [Basic.dart][ListBody (multi-child)] - ListBody with one child", () {
			_verifyDart(
				zml: """
					<ListBody>
						<Text>Text</Text>
					</ListBody>
				""",

				dart: """
					return (ListBody(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][ListBody (multi-child)] - ListBody with children", () {
			_verifyDart(
				zml: """
					<ListBody>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</ListBody>
				""",

				dart: """
					return (ListBody(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Stack (multi-child)] - Stack with one child", () {
			_verifyDart(
				zml: """
					<Stack>
						<Text>Text</Text>
					</Stack>
				""",

				dart: """
					return (Stack(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Stack (multi-child)] - Stack with children", () {
			_verifyDart(
				zml: """
					<Stack>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Stack>
				""",

				dart: """
					return (Stack(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][IndexedStack (multi-child)] - IndexedStack with one child", () {
			_verifyDart(
				zml: """
					<IndexedStack>
						<Text>Text</Text>
					</IndexedStack>
				""",

				dart: """
					return (IndexedStack(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][IndexedStack (multi-child)] - IndexedStack with children", () {
			_verifyDart(
				zml: """
					<IndexedStack>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</IndexedStack>
				""",

				dart: """
					return (IndexedStack(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Flex (multi-child)] - Flex with one child", () {
			_verifyDart(
				zml: """
					<Flex>
						<Text>Text</Text>
					</Flex>
				""",

				dart: """
					return (Flex(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Flex (multi-child)] - Flex with children", () {
			_verifyDart(
				zml: """
					<Flex>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Flex>
				""",

				dart: """
					return (Flex(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Row (multi-child)] - Row with one child", () {
			_verifyDart(
				zml: """
					<Row>
						<Text>Text</Text>
					</Row>
				""",

				dart: """
					return (Row(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Row (multi-child)] - Row with children", () {
			_verifyDart(
				zml: """
					<Row>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Row>
				""",

				dart: """
					return (Row(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Column (multi-child)] - Column with one child", () {
			_verifyDart(
				zml: """
					<Column>
						<Text>Text</Text>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Column (multi-child)] - Column with children", () {
			_verifyDart(
				zml: """
					<Column>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Wrap (multi-child)] - Wrap with one child", () {
			_verifyDart(
				zml: """
					<Wrap>
						<Text>Text</Text>
					</Wrap>
				""",

				dart: """
					return (Wrap(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Wrap (multi-child)] - Wrap with children", () {
			_verifyDart(
				zml: """
					<Wrap>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Wrap>
				""",

				dart: """
					return (Wrap(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Flow (multi-child)] - Flow with one child", () {
			_verifyDart(
				zml: """
					<Flow>
						<Text>Text</Text>
					</Flow>
				""",

				dart: """
					return (Flow(
						children: [
							(Text(\"""Text\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Basic.dart][Flow (multi-child)] - Flow with children", () {
			_verifyDart(
				zml: """
					<Flow>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Flow>
				""",

				dart: """
					return (Flow(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - Container with Text", () {
			_verifyDart(
				zml: """
					<Container>
						<Text>hello world</Text>
					</Container>
				""",

				dart: """
					return (Container(
						child: (Text(\"""hello world\""",))
					));
				""",
			);
		});

		test("Generator test - Column with stuff", () {
			_verifyDart(
				zml: """
					<Column>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - Column with stuff 2", () {
			_verifyDart(
				zml: """
					<Column>
						<Text>Text 1</Text>
						<Text>Text 2</Text>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""Text 1\""",)),
							(Text(\"""Text 2\""",)),
							(Container(
								child: (Text(\"""Text in Container\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - Column with one child", () {
			_verifyDart(
				zml: """
					<Column>
						<Text>Text 1</Text>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""Text 1\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - Column with children", () {
			_verifyDart(
				zml: """
					<Column>
						<Text>Text 1</Text>
						<Row>
							<Column>
								<Text>Text in Column 1</Text>		
								<Container>
									<Text>Text in Container 1</Text>		
								</Container>
							</Column>
							<Container>
								<Text>Text in Container 2</Text>		
							</Container>
						</Row>
						<Container>
							<Text>Text in Container 3</Text>
						</Container>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""Text 1\""",)),
							(Row(
								children: [
									(Column(
										children: [
											(Text(\"""Text in Column 1\""",)),
											(Container(
												child: (Text(\"""Text in Container 1\""",))
											))
										]
									)),
									(Container(
										child: (Text(\"""Text in Container 2\""",))
									))
								]
							)),
							(Container(
								child: (Text(\"""Text in Container 3\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - Row with one child", () {
			_verifyDart(
				zml: """
					<Row>
						<Text>Text 1</Text>
					</Row>
				""",

				dart: """
					return (Row(
						children: [
							(Text(\"""Text 1\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - Row with children", () {
			_verifyDart(
				zml: """
					<Row>
						<Text>Text 1</Text>
						<Column>
							<Column>
								<Text>Text in Column 1</Text>		
								<Text>Text in Column 2</Text>		
							</Column>
							<Container>
								<Text>Text in Container 1</Text>		
							</Container>
						</Column>
						<Container>
							<Text>Text in Container 2</Text>
						</Container>
					</Row>
				""",

				dart: """
					return (Row(
						children: [
							(Text(\"""Text 1\""",)),
							(Column(
								children: [
									(Column(
										children: [
											(Text(\"""Text in Column 1\""",)),
											(Text(\"""Text in Column 2\""",))
										]
									)),
									(Container(
										child: (Text(\"""Text in Container 1\""",))
									))
								]
							)),
							(Container(
								child: (Text(\"""Text in Container 2\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - Wrap with one child", () {
			_verifyDart(
				zml: """
					<Wrap>
						<Text>Text 1</Text>
					</Wrap>
				""",

				dart: """
					return (Wrap(
						children: [
							(Text(\"""Text 1\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - Wrap with children", () {
			_verifyDart(
				zml: """
					<Wrap>
						<Text>Text 1</Text>
						<Container>
							<Text>Text in Container 1</Text>
						</Container>
						<Container>
							<Text>Text in Container 2</Text>
						</Container>
					</Wrap>
				""",

				dart: """
					return (Wrap(
						children: [
							(Text(\"""Text 1\""",)),
							(Container(
								child: (Text(\"""Text in Container 1\""",))
							)),
							(Container(
								child: (Text(\"""Text in Container 2\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - ListView with one child", () {
			_verifyDart(
				zml: """
					<ListView>
						<Text>Text 1</Text>
					</ListView>
				""",

				dart: """
					return (ListView(
						children: [
							(Text(\"""Text 1\""",))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout multi-child] - ListView with children", () {
			_verifyDart(
				zml: """
					<ListView>
						<Container>
							<Text>Text in Container 1</Text>
						</Container>
						<Container>
							<Text>Text in Container 2</Text>
						</Container>
					</ListView>
				""",

				dart: """
					return (ListView(
						children: [
							(Container(
								child: (Text(\"""Text in Container 1\""",))
							)),
							(Container(
								child: (Text(\"""Text in Container 2\""",))
							))
						]
					));
				""",
			);
		});

		test("Generator test - [Layout single-child] - Center with child", () {
			_verifyDart(
				zml: """
					<Center>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Center>
				""",

				dart: """
					return (Center(
						child: (Container(
							child: (Text(\"""Text in Container\""",))
						))
					));
				""",
			);
		});

		test("Generator test - [Layout single-child] - Padding with child", () {
			_verifyDart(
				zml: """
					<Padding>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Padding>
				""",

				dart: """
					return (Padding(
						child: (Container(
							child: (Text(\"""Text in Container\""",))
						))
					));
				""",
			);
		});

		test("Generator test - [Layout single-child] - Align with child", () {
			_verifyDart(
				zml: """
					<Padding>
						<Container>
							<Text>Text in Container</Text>
						</Container>
					</Padding>
				""",

				dart: """
					return (Padding(
						child: (Container(
							child: (Text(\"""Text in Container\""",))
						))
					));
				""",
			);
		});

		test("Generator test - [actions.dart][ActionListener (single-child)] - ActionListener with a child", () {
			_verifyDart(
				zml: """
					<ActionListener>
						<Text>Text</Text>
					</ActionListener>
				""",

				dart: """
					return (ActionListener(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [actions.dart][Actions (single-child)] - Actions with a child", () {
			_verifyDart(
				zml: """
					<Actions>
						<Text>Text</Text>
					</Actions>
				""",

				dart: """
					return (Actions(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [actions.dart][FocusableActionDetector (single-child)] - FocusableActionDetector with a child", () {
			_verifyDart(
				zml: """
					<FocusableActionDetector>
						<Text>Text</Text>
					</FocusableActionDetector>
				""",

				dart: """
					return (FocusableActionDetector(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [animated_size.dart][AnimatedSize (single-child)] - AnimatedSize with a child", () {
			_verifyDart(
				zml: """
					<AnimatedSize>
						<Text>Text</Text>
					</AnimatedSize>
				""",

				dart: """
					return (AnimatedSize(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [animated_switcher.dart][AnimatedSwitcher (single-child)] - AnimatedSwitcher with a child", () {
			_verifyDart(
				zml: """
					<AnimatedSwitcher>
						<Text>Text</Text>
					</AnimatedSwitcher>
				""",

				dart: """
					return (AnimatedSwitcher(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [annotated_region.dart][AnnotatedRegion (single-child)] - AnnotatedRegion with a child", () {
			_verifyDart(
				zml: """
					<AnnotatedRegion>
						<Text>Text</Text>
					</AnnotatedRegion>
				""",

				dart: """
					return (AnnotatedRegion(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [autocomplete.dart][AutocompleteHighlightedOption (single-child)] - AutocompleteHighlightedOption with a child", () {
			_verifyDart(
				zml: """
					<AutocompleteHighlightedOption>
						<Text>Text</Text>
					</AutocompleteHighlightedOption>
				""",

				dart: """
					return (AutocompleteHighlightedOption(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [autofill.dart][AutofillGroup (single-child)] - AutofillGroup with a child", () {
			_verifyDart(
				zml: """
					<AutofillGroup>
						<Text>Text</Text>
					</AutofillGroup>
				""",

				dart: """
					return (AutofillGroup(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [automatic_keep.dart][AutofillGroup (single-child)] - AutomaticKeepAlive with a child", () {
			_verifyDart(
				zml: """
					<AutomaticKeepAlive>
						<Text>Text</Text>
					</AutomaticKeepAlive>
				""",

				dart: """
					return (AutomaticKeepAlive(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [banner.dart][Banner (single-child)] - Banner with a child", () {
			_verifyDart(
				zml: """
					<Banner>
						<Text>Text</Text>
					</Banner>
				""",

				dart: """
					return (Banner(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [banner.dart][CheckedModeBanner (single-child)] - CheckedModeBanner with a child", () {
			_verifyDart(
				zml: """
					<CheckedModeBanner>
						<Text>Text</Text>
					</CheckedModeBanner>
				""",

				dart: """
					return (CheckedModeBanner(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [container.dart][Container (single-child)] - Container with a child", () {
			_verifyDart(
				zml: """
					<Container>
						<Text>Text</Text>
					</Container>
				""",

				dart: """
					return (Container(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [default_text_editing_actions.dart][DefaultTextEditingActions (single-child)] - DefaultTextEditingActions with a child", () {
			_verifyDart(
				zml: """
					<DefaultTextEditingActions>
						<Text>Text</Text>
					</DefaultTextEditingActions>
				""",

				dart: """
					return (DefaultTextEditingActions(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [dismissible.dart][Dismissible (single-child)] - Dismissible with a child", () {
			_verifyDart(
				zml: """
					<Dismissible>
						<Text>Text</Text>
					</Dismissible>
				""",

				dart: """
					return (Dismissible(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [drag_target.dart][Draggable (single-child)] - Draggable with a child", () {
			_verifyDart(
				zml: """
					<Draggable>
						<Text>Text</Text>
					</Draggable>
				""",

				dart: """
					return (Draggable(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [drag_target.dart][LongPressDraggable (single-child)] - LongPressDraggable with a child", () {
			_verifyDart(
				zml: """
					<LongPressDraggable>
						<Text>Text</Text>
					</LongPressDraggable>
				""",

				dart: """
					return (LongPressDraggable(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [draggable_scrollable_sheet.dart][DraggableScrollableActuator (single-child)] - DraggableScrollableActuator with a child", () {
			_verifyDart(
				zml: """
					<DraggableScrollableActuator>
						<Text>Text</Text>
					</DraggableScrollableActuator>
				""",

				dart: """
					return (DraggableScrollableActuator(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [dual_transition_builder.dart][DualTransitionBuilder (single-child)] - DualTransitionBuilder with a child", () {
			_verifyDart(
				zml: """
					<DualTransitionBuilder>
						<Text>Text</Text>
					</DualTransitionBuilder>
				""",

				dart: """
					return (DualTransitionBuilder(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [focus_scope.dart][FocusScope (single-child)] - FocusScope with a child", () {
			_verifyDart(
				zml: """
					<FocusScope>
						<Text>Text</Text>
					</FocusScope>
				""",

				dart: """
					return (FocusScope(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [focus_scope.dart][ExcludeFocus (single-child)] - ExcludeFocus with a child", () {
			_verifyDart(
				zml: """
					<ExcludeFocus>
						<Text>Text</Text>
					</ExcludeFocus>
				""",

				dart: """
					return (ExcludeFocus(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [focus_traversal.dart][FocusTraversalGroup (single-child)] - FocusTraversalGroup with a child", () {
			_verifyDart(
				zml: """
					<FocusTraversalGroup>
						<Text>Text</Text>
					</FocusTraversalGroup>
				""",

				dart: """
					return (FocusTraversalGroup(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [form.dart][Form (single-child)] - Form with a child", () {
			_verifyDart(
				zml: """
					<Form>
						<Text>Text</Text>
					</Form>
				""",

				dart: """
					return (Form(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [gesture_detector.dart][GestureDetector (single-child)] - GestureDetector with a child", () {
			_verifyDart(
				zml: """
					<GestureDetector>
						<Text>Text</Text>
					</GestureDetector>
				""",

				dart: """
					return (GestureDetector(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [gesture_detector.dart][RawGestureDetector (single-child)] - RawGestureDetector with a child", () {
			_verifyDart(
				zml: """
					<RawGestureDetector>
						<Text>Text</Text>
					</RawGestureDetector>
				""",

				dart: """
					return (RawGestureDetector(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [grid_paper.dart][GridPaper (single-child)] - GridPaper with a child", () {
			_verifyDart(
				zml: """
					<GridPaper>
						<Text>Text</Text>
					</GridPaper>
				""",

				dart: """
					return (GridPaper(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [heroes.dart][Hero (single-child)] - Hero with a child", () {
			_verifyDart(
				zml: """
					<Hero>
						<Text>Text</Text>
					</Hero>
				""",

				dart: """
					return (Hero(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [icon_theme.dart][IconTheme (single-child)] - IconTheme with a child", () {
			_verifyDart(
				zml: """
					<IconTheme>
						<Text>Text</Text>
					</IconTheme>
				""",

				dart: """
					return (IconTheme(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [image_filtered.dart][ImageFiltered (single-child)] - ImageFiltered with a child", () {
			_verifyDart(
				zml: """
					<ImageFiltered>
						<Text>Text</Text>
					</ImageFiltered>
				""",

				dart: """
					return (ImageFiltered(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [implicit_animations.dart][AnimatedContainer (single-child)] - AnimatedContainer with a child", () {
			_verifyDart(
				zml: """
					<AnimatedContainer>
						<Text>Text</Text>
					</AnimatedContainer>
				""",

				dart: """
					return (AnimatedContainer(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [implicit_animations.dart][AnimatedPadding (single-child)] - AnimatedPadding with a child", () {
			_verifyDart(
				zml: """
					<AnimatedPadding>
						<Text>Text</Text>
					</AnimatedPadding>
				""",

				dart: """
					return (AnimatedPadding(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});

		test("Generator test - [implicit_animations.dart][AnimatedAlign (single-child)] - AnimatedAlign with a child", () {
			_verifyDart(
				zml: """
					<AnimatedAlign>
						<Text>Text</Text>
					</AnimatedAlign>
				""",

				dart: """
					return (AnimatedAlign(
						child: (Text(\"""Text\""",))
					));
				""",
			);
		});
	});
}