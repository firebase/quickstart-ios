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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#pragma mark - Common constants

static NSString *const FIRCellClassName = @"UITableViewCell";
static NSString *const FIRTextFieldClassName = @"UITextField";
static NSString *const FIRUIFieldClassName = @"UIFieldEditor";

static NSTimeInterval const defaultTimeout = 10;
static NSTimeInterval const pollInterval = 0.5;

// Common EarlGrey methods that are used in various tests.
#pragma mark - Helpers

// Returns if system alert is present.
BOOL FIRSystemAlertShown(void);

// Returns system alert if it exists.
XCUIElement *FIRSystemAlert(void);

// Waits given time till system alert appears.
void FIRWaitTillAlertPresent(NSTimeInterval timeout);

// Waits given time till system alert disappears.
void FIRWaitTillAlertGone(NSTimeInterval timeout);

// Dismisses NSAlert if it appears (not to confuse with system alerts).
void FIRDismissAlertIfOpen(XCUIApplication *app);

// Dumps UI hierarchy to log, used for debugging purposes.
void FIRDumpUIHierarchy(XCUIApplication *app);

// Common way of detecting whether user is signed in.
BOOL FIRSignedIn(XCUIApplication *app);

// Generates a random numric string with the length given.
NSString *randomString(NSUInteger length);

// Generates a numeric string that represents the current time in epoch seconds.
NSString *timestamp(void);

// Waits given time till predicate is satisfied. Does not lead to test failure
// if timeout happens.
void FIRWaitForPredicateWithTimeout(NSPredicate *predicate, XCUIElement *element,
                                    NSUInteger timeout);

// Waits default timeout till predicate is satisfied.
void FIRWaitForPredicate(NSPredicate *predicate, XCUIElement *element);

// Waits given time till given XCUIElement is visible.
void FIRWaitForVisibleWithTimeout(XCUIElement *element, NSUInteger timeout);

// Waits default timeout till given XCUIElement is visible.
void FIRWaitForVisible(XCUIElement *element);

// Taps on the center of the element using its coordinates.
// This is safer than interacting directly with the XCUIElement, because
// there are certain known Xcode bugs for SFSafariViewController
// or WKWebView. See more http://www.openradar.me/36788196.
void FIRTapSafely(XCUIApplication *app, XCUIElement *element);

// Types the text to the provided XCUIElement (Must correspond to a UITextView)
// using the pastebin
void FIRTypeWithPastebin(XCUIApplication *app, XCUIElement *element, NSString *text);
