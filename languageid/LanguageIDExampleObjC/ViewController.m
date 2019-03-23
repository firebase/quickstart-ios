//
// Copyright (c) 2015 Google Inc.
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

@import FirebaseMLNLLanguageID;
@import FirebaseMLNaturalLanguage;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *inputTextView;
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property(nonatomic, strong) FIRLanguageIdentification *languageId;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.languageId = [[FIRNaturalLanguage naturalLanguage] languageIdentification];
  _inputTextView.text = @"Type here";
}

- (IBAction)identifyLanguage:(id)sender {
  [_languageId identifyLanguageForText:_inputTextView.text completion:^(NSString * _Nullable languageCode, NSError * _Nullable error) {
    if (error != nil) {
      self.outputTextView.text = [NSString stringWithFormat:@"Failed with error: %@", error.localizedDescription];
      return;
    }
    if (languageCode != nil) {
      self.outputTextView.text = [NSString stringWithFormat:@"Identified Language: %@", languageCode];
    } else {
      self.outputTextView.text = @"No language was identified";
    }
  }];
}

- (IBAction)identifyPossibleLanguages:(id)sender {
  [_languageId identifyPossibleLanguagesForText:_inputTextView.text completion:^(NSArray<FIRIdentifiedLanguage *> * _Nonnull identifiedLanguages, NSError * _Nullable error) {
    if (error != nil) {
      self.outputTextView.text = [NSString stringWithFormat:@"Failed with error: %@", error.localizedDescription];
      return;
    }
    if (identifiedLanguages == nil || identifiedLanguages.count == 0) {
      self.outputTextView.text = @"No language was identified";
      return;
    }

    NSMutableString *outputText = [NSMutableString stringWithFormat:@"Identified Languages:"];
    for (FIRIdentifiedLanguage *language in identifiedLanguages) {
      [outputText appendFormat:@"\n(%@, %.2f)", language.languageCode, language.confidence];
    }
    self.outputTextView.text = outputText;
  }];
}

@end
