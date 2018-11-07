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

#import "ViewController.h"
@import Firebase;

@implementation ViewController

-(void)viewDidLoad {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(displayFCMToken:)
                                        name:@"FCMToken"
                                        object:nil];
}

- (IBAction)handleLogTokenTouch:(id)sender {
  // [START log_fcm_reg_token]
  NSString *fcmToken = [FIRMessaging messaging].FCMToken;
  NSLog(@"Local FCM registration token: %@", fcmToken);
  // [END log_fcm_reg_token]
    
  NSString* displayToken = [NSString stringWithFormat:@"Logged FCM token: %@", fcmToken];
  self.fcmTokenMessage.text = displayToken;
    
  // [START log_iid_reg_token]
  [[FIRInstanceID instanceID] instanceIDWithHandler:^(FIRInstanceIDResult * _Nullable result,
                                                      NSError * _Nullable error) {
    if (error != nil) {
      NSLog(@"Error fetching remote instance ID: %@", error);
    } else {
      NSLog(@"Remote instance ID token: %@", result.token);
      NSString* message =
        [NSString stringWithFormat:@"Remote InstanceID token: %@", result.token];
      self.instanceIDTokenMessage.text = message;
    }
  }];
  // [END log_iid_reg_token]
}

- (IBAction)handleSubscribeTouch:(id)sender {
  // [START subscribe_topic]
  [[FIRMessaging messaging] subscribeToTopic:@"weather"
                                  completion:^(NSError * _Nullable error) {
    NSLog(@"Subscribed to weather topic");
  }];
  // [END subscribe_topic]
}

- (void) displayFCMToken:(NSNotification *) notification {
  NSString* message =
    [NSString stringWithFormat:@"Received FCM token: %@", notification.userInfo[@"token"]];
  self.fcmTokenMessage.text = message;
}

@end
