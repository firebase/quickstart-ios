//
// Copyright (c) 2019 Google Inc.
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

@import FirebaseMLNaturalLanguage;
@import FirebaseMLNLTranslate;

NS_ASSUME_NONNULL_BEGIN

@interface ViewController ()

@property(weak, nonatomic) IBOutlet UITextView *inputTextView;
@property(weak, nonatomic) IBOutlet UITextView *outputTextView;
@property(weak, nonatomic) IBOutlet UIPickerView *inputPicker;
@property(weak, nonatomic) IBOutlet UIPickerView *outputPicker;
@property(nonatomic, strong) FIRTranslator *translator;
@property(nonatomic, strong) NSArray<NSNumber *> *allLanguages;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.allLanguages = FIRTranslatorAllLanguages().allObjects;
  self.inputPicker.dataSource = self;
  self.outputPicker.dataSource = self;
  [self.inputPicker selectRow:[self.allLanguages indexOfObject:@(FIRTranslatorLanguageEN)] inComponent:0 animated:NO];
  [self.outputPicker selectRow:[self.allLanguages indexOfObject:@(FIRTranslatorLanguageES)] inComponent:0 animated:NO];
  self.inputPicker.delegate = self;
  self.outputPicker.delegate = self;
  self.inputTextView.delegate = self;
  [self pickerView:self.inputPicker didSelectRow:0 inComponent:0];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return FIRTranslatorLanguageCodeForLanguage(self.allLanguages[row].integerValue);
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return self.allLanguages.count;
}

- (void)textViewDidChange:(UITextView *)textView {
  [self translate];
}

- (IBAction)didTapSwap {
  int inputSelectedRow = [self.inputPicker selectedRowInComponent:0];
  [self.inputPicker selectRow:[self.outputPicker selectedRowInComponent:0] inComponent:0 animated:NO];
  [self.outputPicker selectRow:inputSelectedRow inComponent:0 animated:NO];
  self.inputTextView.text = self.outputTextView.text;
  [self pickerView:self.inputPicker didSelectRow:0 inComponent:0];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  FIRTranslatorOptions *options =
  [[FIRTranslatorOptions alloc] initWithSourceLanguage:self.allLanguages[[self.inputPicker selectedRowInComponent:0]].integerValue
                                        targetLanguage:self.allLanguages[[self.outputPicker selectedRowInComponent:0]].integerValue];
  self.translator = [[FIRNaturalLanguage naturalLanguage] translatorWithOptions:options];
  [self translate];
}

- (void)translate {
  [self.translator ensureModelDownloadedWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      self.outputTextView.text =
          [NSString stringWithFormat:@"Failed to ensure model downloaded with error %@",
                                     error.localizedDescription];
      return;
    }
    NSString *text = self.inputTextView.text;
    if (text == nil) {
      text = @"";
    }
    [self.translator translateText:text
                        completion:^(NSString *_Nullable result, NSError *_Nullable error) {
                          if (error != nil) {
                            self.outputTextView.text = [NSString
                                stringWithFormat:@"Failed to ensure model downloaded with error %@",
                                                 error.localizedDescription];
                            return;
                          }
                          self.outputTextView.text = result;
                        }];
  }];
}

@end

NS_ASSUME_NONNULL_END
