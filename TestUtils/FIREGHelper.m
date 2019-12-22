//
//  Copyright (c) 2019 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FIREGHelper.h"

#pragma mark - Helpers

// Returns the coordinates of the element via debug description of the app.
XCUICoordinate *FIRViewCoordinate(XCUIApplication *app, XCUIElement *element);

BOOL FIRSystemAlertShown() {
  return FIRSystemAlert().exists;
}

XCUIElement *FIRSystemAlert() {
  XCUIApplication *springboard =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  return [springboard.alerts firstMatch];
}

void FIRWaitTillAlertPresent(NSTimeInterval timeout) {
  FIRWaitForVisibleWithTimeout(FIRSystemAlert(), timeout);
}

void FIRWaitTillAlertGone(NSTimeInterval timeout) {
  NSPredicate *gone = [NSPredicate predicateWithFormat:@"exists == false"];
  FIRWaitForPredicateWithTimeout(gone, FIRSystemAlert(), timeout);
}

void FIRDismissAlertIfOpen(XCUIApplication *app) {
  FIRWaitForVisible([app.alerts firstMatch]);
  if ([app.alerts firstMatch].exists) {
    [app.alerts.buttons[@"OK"] tap];
  }
}

BOOL FIRSignedIn(XCUIApplication *app) {
  FIRWaitForVisible(app.buttons[@"Sign Out"]);
  FIRWaitForVisible(app.buttons[@"Sign In"]);
  return !app.buttons[@"Sign In"].exists;
}

void FIRDumpUIHierarchy(XCUIApplication *app) { NSLog(@"Hierarchy: %@", [app debugDescription]); }

NSString *randomString(NSUInteger length) {
  NSMutableString *returnString = [NSMutableString stringWithCapacity:length];
  NSString *numbers = @"0123456789";
  for (int i = 0; i < length; i++) {
    [returnString appendFormat:@"%C", [numbers characterAtIndex:arc4random() % [numbers length]]];
  }
  return returnString;
}

NSString *timestamp() {
  NSDate *now = [NSDate date];
  NSNumber *seconds = [NSNumber numberWithLong:[now timeIntervalSince1970]];
  return [seconds stringValue];
}

void FIRWaitForPredicateWithTimeout(NSPredicate *predicate, XCUIElement *element,
                                    NSUInteger timeout) {
  XCTestExpectation *expectation =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:element];
  NSArray *expectationArray = @[ expectation ];
  (void)[XCTWaiter waitForExpectations:expectationArray timeout:timeout];
}

void FIRWaitForPredicate(NSPredicate *predicate, XCUIElement *element) {
  FIRWaitForPredicateWithTimeout(predicate, element, defaultTimeout);
}

void FIRWaitForVisibleWithTimeout(XCUIElement *element, NSUInteger timeout) {
  NSPredicate *visible = [NSPredicate predicateWithFormat:@"exists == true"];
  FIRWaitForPredicateWithTimeout(visible, element, timeout);
}

void FIRWaitForVisible(XCUIElement *element) {
  FIRWaitForVisibleWithTimeout(element, defaultTimeout);
}

XCUICoordinate *FIRViewCoordinate(XCUIApplication *app, XCUIElement *element) {
  // Finds the printable description of the element.
  NSString *description = [[element firstMatch] debugDescription];
  @try {
    NSRange rangeOpen = [description rangeOfString:@"{{" options:NSBackwardsSearch];
    NSRange rangeClose = [description rangeOfString:@"}}" options:NSBackwardsSearch];
    NSRange subRange = NSMakeRange(rangeOpen.location,
                                   rangeClose.location + rangeClose.length - rangeOpen.location);
    NSString *frameCoordinates = [description substringWithRange:subRange];
    // Finds the coordinates of the center.
    CGRect rect = CGRectFromString(frameCoordinates);
    CGVector center = CGVectorMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    return [[app coordinateWithNormalizedOffset:CGVectorMake(0, 0)] coordinateWithOffset:center];
  }
  // This is an edge case when debug description doesn't contain coordinates information.
  @catch (NSException *e) {
    NSLog(@"Exception happened when trying to get coordinates");
    FIRDumpUIHierarchy(app);
    NSLog(@"Use the regular way of obtaining coordinates");
    return [element coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  }
}

void FIRTapSafely(XCUIApplication *app, XCUIElement *element) {
  XCUICoordinate *coordinates = FIRViewCoordinate(app, element);
  NSLog(@"Trying to tap on the coordinates: %@", NSStringFromCGPoint([coordinates screenPoint]));
  FIRDumpUIHierarchy(app);
  [coordinates tap];
}

void FIRTypeWithPastebin(XCUIApplication *app, XCUIElement *element, NSString *text) {
  // Adds the text to pastebin.
  [[UIPasteboard generalPasteboard] setString:text];

  // Long click on the element.
  XCUICoordinate *textViewCoordinate = FIRViewCoordinate(app, element);
  [textViewCoordinate pressForDuration:2];

  // Pastes the text.
  FIRWaitForVisible(app.menuItems[@"Paste"]);
  [app.menuItems[@"Paste"] tap];
}
