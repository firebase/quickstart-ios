//
//  Copyright (c) 2018 Google Inc.
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

#import "CommentCell.h"

@import Firebase;

@interface CommentCell ()
@property(weak, nonatomic) IBOutlet MDCTextField *resultField1;
@property(weak, nonatomic) IBOutlet MDCTextField *resultField2;
@property(weak, nonatomic) IBOutlet MDCTextField *resultField3;
// [START define_functions_instance]
@property(strong, nonatomic) FIRTextSmartReplyPredictor *predictor;
// [END define_functions_instance]
@end

@implementation CommentCell

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    // [START initialize_predictor_instance]
    self.predictor = [[FIRText text] smartReplyPredictor];
    // [END initialize_predictor_instance]
  }
  return self;
}

- (IBAction)didTapAddMessage:(id)sender {
  NSString *inputText = inputField.text;
  // [START predictor_predict]
  [predictor predictReplyForText:inputText
                      completion:^(NSArray<FIRTextSmartReply *> *replies,
                                   NSError *error) {
                        if (error != nil) {
                          return;
                        } else if (replies != nil) {
                          // Successfully predicted message replies.
                          for (id <FIRTextSmartReply> reply in replies) {
                            NSLog(@"Suggested reply (confidence: %@): %@", reply.confidence, reply.text);
                          }
                          // [START_EXCLUDE]
                          int count = replies.count;
                          FIRTextSmartReply *reply;
                          if (count > 0) {
                            reply = replies[0];
                            resultField1.text = reply.text + " - " + reply. confidence;
                            if (count > 1) {
                              reply = replies[1];
                              resultField1.text = reply.text + " - " + reply. confidence;
                              if (count > 2) {
                                reply = replies[2];
                                resultField1.text = reply.text + " - " + reply. confidence;
                              }
                            }
                          }
                          // [END_EXCLUDE]
                        }
                      }];
  // [END predictor_predict]
}

@end
