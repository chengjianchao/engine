// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"

FLUTTER_ASSERT_ARC

const CGRect kScreenSize = CGRectMake(0, 0, 600, 800);

namespace flutter {
namespace {

class SemanticsActionObservation {
 public:
  SemanticsActionObservation(int32_t observed_id, SemanticsAction observed_action)
      : id(observed_id), action(observed_action) {}

  int32_t id;
  SemanticsAction action;
};

class MockAccessibilityBridge : public AccessibilityBridgeIos {
 public:
  MockAccessibilityBridge() : observations({}) {
    view_ = [[UIView alloc] initWithFrame:kScreenSize];
    window_ = [[UIWindow alloc] initWithFrame:kScreenSize];
    [window_ addSubview:view_];
  }
  UIView* view() const override { return view_; }
  UIView<UITextInput>* textInputView() override { return nil; }
  void DispatchSemanticsAction(int32_t id, SemanticsAction action) override {
    SemanticsActionObservation observation(id, action);
    observations.push_back(observation);
  }
  void DispatchSemanticsAction(int32_t id,
                               SemanticsAction action,
                               fml::MallocMapping args) override {
    SemanticsActionObservation observation(id, action);
    observations.push_back(observation);
  }
  void AccessibilityObjectDidBecomeFocused(int32_t id) override {}
  void AccessibilityObjectDidLoseFocus(int32_t id) override {}
  std::shared_ptr<FlutterPlatformViewsController> GetPlatformViewsController() const override {
    return nil;
  }
  std::vector<SemanticsActionObservation> observations;

 private:
  UIView* view_;
  UIWindow* window_;
};
}  // namespace
}  // namespace flutter

@interface SemanticsObjectTest : XCTestCase
@end

@implementation SemanticsObjectTest

- (void)testCreate {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  XCTAssertNotNil(object);
}

- (void)testSetChildren {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  parent.children = @[ child ];
  XCTAssertEqual(parent, child.parent);
  parent.children = @[];
  XCTAssertNil(child.parent);
}

- (void)testReplaceChildAtIndex {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* child2 = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  parent.children = @[ child1 ];
  [parent replaceChildAtIndex:0 withChild:child2];
  XCTAssertNil(child1.parent);
  XCTAssertEqual(parent, child2.parent);
  XCTAssertEqualObjects(parent.children, @[ child2 ]);
}

- (void)testPlainSemanticsObjectWithLabelHasStaticTextTrait {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitStaticText);
}

- (void)testNodeWithImplicitScrollIsAnAccessibilityElementWhenItisHidden {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling) |
               static_cast<int32_t>(flutter::SemanticsFlags::kIsHidden);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual(object.isAccessibilityElement, YES);
}

- (void)testNodeWithImplicitScrollIsNotAnAccessibilityElementWhenItisNotHidden {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual(object.isAccessibilityElement, NO);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  object.children = @[ child1 ];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitNone);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait1 {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsTextField);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitNone);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait2 {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsButton);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitButton);
}

- (void)testVerticalFlutterScrollableSemanticsObject {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float screenScale = [[bridge->view() window] screen].scale;
  float effectivelyScale = transformScale / screenScale;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = 500.0;
  float scrollPosition = 150.0;

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kVerticalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(x, y, w, h);
  node.scrollExtentMax = scrollExtentMax;
  node.scrollPosition = scrollPosition;
  node.transform = {
      transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, 1.0};
  FlutterSemanticsObject* delegate = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithSemanticsObject:delegate];
  SemanticsObject* scrollable_object = static_cast<SemanticsObject*>(scrollable);
  [scrollable_object setSemanticsNode:&node];
  [scrollable_object accessibilityBridgeDidFinishUpdate];
  XCTAssertTrue(
      CGRectEqualToRect(scrollable.frame, CGRectMake(x * effectivelyScale, y * effectivelyScale,
                                                     w * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGSizeEqualToSize(
      scrollable.contentSize,
      CGSizeMake(w * effectivelyScale, (h + scrollExtentMax) * effectivelyScale)));
  XCTAssertTrue(CGPointEqualToPoint(scrollable.contentOffset,
                                    CGPointMake(0, scrollPosition * effectivelyScale)));
}

- (void)testHorizontalFlutterScrollableSemanticsObject {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float screenScale = [[bridge->view() window] screen].scale;
  float effectivelyScale = transformScale / screenScale;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = 500.0;
  float scrollPosition = 150.0;

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(x, y, w, h);
  node.scrollExtentMax = scrollExtentMax;
  node.scrollPosition = scrollPosition;
  node.transform = {
      transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, 1.0};
  FlutterSemanticsObject* delegate = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithSemanticsObject:delegate];
  SemanticsObject* scrollable_object = static_cast<SemanticsObject*>(scrollable);
  [scrollable_object setSemanticsNode:&node];
  [scrollable_object accessibilityBridgeDidFinishUpdate];
  XCTAssertTrue(
      CGRectEqualToRect(scrollable.frame, CGRectMake(x * effectivelyScale, y * effectivelyScale,
                                                     w * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGSizeEqualToSize(
      scrollable.contentSize,
      CGSizeMake((w + scrollExtentMax) * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGPointEqualToPoint(scrollable.contentOffset,
                                    CGPointMake(scrollPosition * effectivelyScale, 0)));
}

- (void)testFlutterScrollableSemanticsObjectIsNotHittestable {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;

  FlutterSemanticsObject* delegate = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithSemanticsObject:delegate];
  SemanticsObject* scrollable_object = static_cast<SemanticsObject*>(scrollable);
  [scrollable_object setSemanticsNode:&node];
  [scrollable_object accessibilityBridgeDidFinishUpdate];
  XCTAssertEqual([scrollable hitTest:CGPointMake(10, 10) withEvent:nil], nil);
}

- (void)testSemanticsObjectBuildsAttributedString {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "label";
  std::shared_ptr<flutter::SpellOutStringAttribute> attribute =
      std::make_shared<flutter::SpellOutStringAttribute>();
  attribute->start = 1;
  attribute->end = 2;
  attribute->type = flutter::StringAttributeType::kSpellOut;
  node.labelAttributes.push_back(attribute);
  node.value = "value";
  attribute = std::make_shared<flutter::SpellOutStringAttribute>();
  attribute->start = 2;
  attribute->end = 3;
  attribute->type = flutter::StringAttributeType::kSpellOut;
  node.valueAttributes.push_back(attribute);
  node.hint = "hint";
  std::shared_ptr<flutter::LocaleStringAttribute> local_attribute =
      std::make_shared<flutter::LocaleStringAttribute>();
  local_attribute->start = 3;
  local_attribute->end = 4;
  local_attribute->type = flutter::StringAttributeType::kLocale;
  local_attribute->locale = "en-MX";
  node.hintAttributes.push_back(local_attribute);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  NSMutableAttributedString* expectedAttributedLabel =
      [[NSMutableAttributedString alloc] initWithString:@"label"];
  NSDictionary* attributeDict = @{
    UIAccessibilitySpeechAttributeSpellOut : @YES,
  };
  [expectedAttributedLabel setAttributes:attributeDict range:NSMakeRange(1, 1)];
  XCTAssertTrue(
      [object.accessibilityAttributedLabel isEqualToAttributedString:expectedAttributedLabel]);

  NSMutableAttributedString* expectedAttributedValue =
      [[NSMutableAttributedString alloc] initWithString:@"value"];
  attributeDict = @{
    UIAccessibilitySpeechAttributeSpellOut : @YES,
  };
  [expectedAttributedValue setAttributes:attributeDict range:NSMakeRange(2, 1)];
  XCTAssertTrue(
      [object.accessibilityAttributedValue isEqualToAttributedString:expectedAttributedValue]);

  NSMutableAttributedString* expectedAttributedHint =
      [[NSMutableAttributedString alloc] initWithString:@"hint"];
  attributeDict = @{
    UIAccessibilitySpeechAttributeLanguage : @"en-MX",
  };
  [expectedAttributedHint setAttributes:attributeDict range:NSMakeRange(3, 1)];
  XCTAssertTrue(
      [object.accessibilityAttributedHint isEqualToAttributedString:expectedAttributedHint]);
}

- (void)testShouldTriggerAnnouncement {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];

  // Handle nil with no node set.
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:nil]);

  // Handle initial setting of node with liveRegion
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsLiveRegion);
  node.label = "foo";
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&node]);

  // Handle nil with node set.
  [object setSemanticsNode:&node];
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:nil]);

  // Handle new node, still has live region, same label.
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:&node]);

  // Handle update node with new label, still has live region.
  flutter::SemanticsNode updatedNode;
  updatedNode.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsLiveRegion);
  updatedNode.label = "bar";
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&updatedNode]);

  // Handle dropping the live region flag.
  updatedNode.flags = 0;
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:&updatedNode]);

  // Handle adding the flag when the label has not changed.
  updatedNode.label = "foo";
  [object setSemanticsNode:&updatedNode];
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&node]);
}

- (void)testShouldDispatchShowOnScreenActionForHeader {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsHeader);
  node.label = "foo";

  [object setSemanticsNode:&node];

  // Simulate accessibility focus.
  [object accessibilityElementDidBecomeFocused];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 1);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testShouldDispatchShowOnScreenActionForHidden {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:1];

  // Handle initial setting of node with hidden.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsHidden);
  node.label = "foo";

  [object setSemanticsNode:&node];

  // Simulate accessibility focus.
  [object accessibilityElementDidBecomeFocused];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 1);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testSemanticsObjectAndPlatformViewSemanticsContainerDontHaveRetainCycle {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  object.platformViewSemanticsContainer =
      [[FlutterPlatformViewSemanticsContainer alloc] initWithSemanticsObject:object];
  __weak SemanticsObject* weakObject = object;
  object = nil;
  XCTAssertNil(weakObject);
}

- (void)testFlutterSwitchSemanticsObjectMatchesUISwitch {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterSwitchSemanticsObject* object = [[FlutterSwitchSemanticsObject alloc] initWithBridge:bridge
                                                                                          uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasToggledState) |
               static_cast<int32_t>(flutter::SemanticsFlags::kIsToggled);
  node.label = "foo";
  [object setSemanticsNode:&node];
  // Create ab real UISwitch to compare the FlutterSwitchSemanticsObject with.
  UISwitch* nativeSwitch = [[UISwitch alloc] init];
  nativeSwitch.on = YES;

  XCTAssertEqual(object.accessibilityTraits, nativeSwitch.accessibilityTraits);
  XCTAssertEqual(object.accessibilityValue, nativeSwitch.accessibilityValue);

  // Set the toggled to false;
  flutter::SemanticsNode update;
  update.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasToggledState);
  update.label = "foo";
  [object setSemanticsNode:&update];

  nativeSwitch.on = NO;

  XCTAssertEqual(object.accessibilityTraits, nativeSwitch.accessibilityTraits);
  XCTAssertEqual(object.accessibilityValue, nativeSwitch.accessibilityValue);
}

@end
