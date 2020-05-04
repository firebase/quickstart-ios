//
//  Copyright (c) 2016 Google Inc.
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

#import "UIViewController+Alerts.h"

#import <objc/runtime.h>

/*! @var kPleaseWaitAssociatedObjectKey
 @brief Key used to identify the "please wait" spinner associated object.
 */
static NSString *const kPleaseWaitAssociatedObjectKey =
    @"_UIViewControllerAlertCategory_PleaseWaitScreenAssociatedObject";

/*! @var kOK
 @brief Text for an 'OK' button.
 */
static NSString *const kOK = @"OK";

/*! @var kCancel
 @brief Text for an 'Cancel' button.
 */
static NSString *const kCancel = @"Cancel";

/*! @class SimpleTextPromptDelegate
 @brief A @c UIAlertViewDelegate which allows @c UIAlertView to be used with blocks more easily.
 */
@interface SimpleTextPromptDelegate : NSObject<UIAlertViewDelegate>

/*! @fn init
 @brief Please use initWithCompletionHandler.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

/*! @fn initWithCompletionHandler:
 @brief Designated initializer.
 @param completionHandler The block to call when the alert view is dismissed.
 */
- (nullable instancetype)initWithCompletionHandler:(AlertPromptCompletionBlock)completionHandler
    NS_DESIGNATED_INITIALIZER;

@end

@implementation UIViewController (Alerts)

- (void)showMessagePrompt:(NSString *)message {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:nil
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *okAction =
      [UIAlertAction actionWithTitle:kOK style:UIAlertActionStyleDefault handler:nil];
  [alert addAction:okAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showTextInputPromptWithMessage:(NSString *)message
                       completionBlock:(AlertPromptCompletionBlock)completion {
  UIAlertController *prompt =
      [UIAlertController alertControllerWithTitle:nil
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  __weak UIAlertController *weakPrompt = prompt;
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:kCancel
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *_Nonnull action) {
                                                         completion(NO, nil);
                                                       }];
  UIAlertAction *okAction =
      [UIAlertAction actionWithTitle:kOK
                               style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *_Nonnull action) {
                               UIAlertController *strongPrompt = weakPrompt;
                               completion(YES, strongPrompt.textFields[0].text);
                             }];
  [prompt addTextFieldWithConfigurationHandler:nil];
  [prompt addAction:cancelAction];
  [prompt addAction:okAction];
  [self presentViewController:prompt animated:YES completion:nil];
}

- (void)showSpinner:(nullable void (^)(void))completion {
  UIAlertController *pleaseWaitAlert =
      objc_getAssociatedObject(self, (__bridge const void *)(kPleaseWaitAssociatedObjectKey));
  if (pleaseWaitAlert) {
    if (completion) {
      completion();
    }
    return;
  }
  pleaseWaitAlert = [UIAlertController alertControllerWithTitle:nil
                                                        message:@"Please Wait...\n\n\n\n"
                                                 preferredStyle:UIAlertControllerStyleAlert];

  UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  spinner.color = [UIColor blackColor];
  spinner.center = CGPointMake(pleaseWaitAlert.view.bounds.size.width / 2,
                               pleaseWaitAlert.view.bounds.size.height / 2);
  spinner.autoresizingMask =
      UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
      UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
  [spinner startAnimating];
  [pleaseWaitAlert.view addSubview:spinner];

  objc_setAssociatedObject(self, (__bridge const void *)(kPleaseWaitAssociatedObjectKey),
                           pleaseWaitAlert, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  [self presentViewController:pleaseWaitAlert animated:YES completion:completion];
}

- (void)hideSpinner:(nullable void (^)(void))completion {
  UIAlertController *pleaseWaitAlert =
      objc_getAssociatedObject(self, (__bridge const void *)(kPleaseWaitAssociatedObjectKey));

  [pleaseWaitAlert dismissViewControllerAnimated:YES completion:completion];

  objc_setAssociatedObject(self, (__bridge const void *)(kPleaseWaitAssociatedObjectKey), nil,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation SimpleTextPromptDelegate {
  AlertPromptCompletionBlock _completionHandler;
  SimpleTextPromptDelegate *_retainedSelf;
}

- (instancetype)initWithCompletionHandler:(AlertPromptCompletionBlock)completionHandler {
  self = [super init];
  if (self) {
    _completionHandler = completionHandler;
    _retainedSelf = self;
  }
  return self;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == alertView.firstOtherButtonIndex) {
    _completionHandler(YES, [alertView textFieldAtIndex:0].text);
  } else {
    _completionHandler(NO, nil);
  }
  _completionHandler = nil;
  _retainedSelf = nil;
}

@end
