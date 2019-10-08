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
@import Firebase;

NS_ASSUME_NONNULL_BEGIN

@interface ViewController ()

@property(weak, nonatomic) IBOutlet UITextView *inputTextView;
@property(weak, nonatomic) IBOutlet UITextView *outputTextView;
@property(weak, nonatomic) IBOutlet UITextView *statusTextView;
@property(weak, nonatomic) IBOutlet UIPickerView *inputPicker;
@property(weak, nonatomic) IBOutlet UIPickerView *outputPicker;
@property(weak, nonatomic) IBOutlet UIButton *sourceDownloadDeleteButton;
@property(weak, nonatomic) IBOutlet UIButton *targetDownloadDeleteButton;

@property(nonatomic, strong) FIRTranslator *translator;
@property(nonatomic, strong) NSArray<NSNumber *> *allLanguages;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.allLanguages = FIRTranslateAllLanguages().allObjects;
  self.inputPicker.dataSource = self;
  self.outputPicker.dataSource = self;
  [self.inputPicker selectRow:[self.allLanguages indexOfObject:@(FIRTranslateLanguageEN)]
                  inComponent:0
                     animated:NO];
  [self.outputPicker selectRow:[self.allLanguages indexOfObject:@(FIRTranslateLanguageES)]
                   inComponent:0
                      animated:NO];
  self.inputPicker.delegate = self;
  self.outputPicker.delegate = self;
  self.inputTextView.delegate = self;
  self.inputTextView.returnKeyType = UIReturnKeyDone;

  [self pickerView:self.inputPicker didSelectRow:0 inComponent:0];
  [self updateDownloadDeleteButtonLabels];

  [NSNotificationCenter.defaultCenter
      addObserver:self
         selector:@selector(modelDownloadDidCompleteWithNotification:)
             name:FIRModelDownloadDidSucceedNotification
           object:nil];
  [NSNotificationCenter.defaultCenter
      addObserver:self
         selector:@selector(modelDownloadDidCompleteWithNotification:)
             name:FIRModelDownloadDidFailNotification
           object:nil];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return FIRTranslateLanguageCodeForLanguage(self.allLanguages[row].integerValue);
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return self.allLanguages.count;
}

- (void)textViewDidChange:(UITextView *)textView {
  [self translate];
}

- (BOOL)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
  // Hide the keyboard when "Done" is pressed.
  // See: https://stackoverflow.com/questions/26600359/dismiss-keyboard-with-a-uitextview
  if ([text isEqualToString:@"\n"]) {
    [textView resignFirstResponder];
    return NO;
  }
  return YES;
}

- (IBAction)didTapSwap {
  NSInteger inputSelectedRow = [self.inputPicker selectedRowInComponent:0];
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
  FIRTranslator *translatorForDownload = self.translator;
  [self.translator downloadModelIfNeededWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      self.outputTextView.text =
          [NSString stringWithFormat:@"Failed to ensure model downloaded with error %@",
                                     error.localizedDescription];
      return;
    }
    [self updateDownloadDeleteButtonLabels];
    NSString *text = self.inputTextView.text;
    if (text == nil) {
      text = @"";
    }
    self.outputTextView.text = @"";
    if (translatorForDownload != self.translator) {
      return;
    }
    [self.translator translateText:text
                        completion:^(NSString *_Nullable result, NSError *_Nullable error) {
                          if (error != nil) {
                            self.outputTextView.text = [NSString
                                stringWithFormat:@"Failed to ensure model downloaded with error %@",
                                                 error.localizedDescription];
                            return;
                          }
                          if (translatorForDownload != self.translator) {
                            return;
                          }
                          self.outputTextView.text = result;
                        }];
  }];
}

- (void)handleDownloadDeleteWithPicker:(UIPickerView *)picker button:(UIButton *)button {
  FIRTranslateLanguage language =
      (FIRTranslateLanguage)self.allLanguages[[picker selectedRowInComponent:0]].intValue;
  NSString *languageCode = FIRTranslateLanguageCodeForLanguage(language);

  [button setTitle:@"Working..." forState:UIControlStateNormal];
  FIRTranslateRemoteModel *model = [self modelForLanguage:language];
  FIRModelManager *modelManager = [FIRModelManager modelManager];

  if ([modelManager isModelDownloaded:model]) {
    self.statusTextView.text = [NSString stringWithFormat:@"Deleting %@", languageCode];
    [modelManager deleteDownloadedModel:model
                             completion:^(NSError *_Nullable error) {
                               [self updateDownloadDeleteButtonLabels];
                               self.statusTextView.text =
                                   [NSString stringWithFormat:@"Deleted %@", languageCode];
                             }];
  } else {
    self.statusTextView.text = [NSString stringWithFormat:@"Downloading %@", languageCode];
    FIRModelDownloadConditions *conditions =
        [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:YES
                                             allowsBackgroundDownloading:YES];
    [modelManager downloadModel:model conditions:conditions];
  }
}

- (void)updateDownloadDeleteButtonLabels {
  FIRTranslateLanguage inputLanguage =
      (FIRTranslateLanguage)self.allLanguages[[self.inputPicker selectedRowInComponent:0]].intValue;
  FIRTranslateLanguage outputLanguage =
      (FIRTranslateLanguage)self.allLanguages[[self.outputPicker selectedRowInComponent:0]]
          .intValue;

  if ([self isLanguageDownloaded:inputLanguage]) {
    [self.sourceDownloadDeleteButton setTitle:@"Delete Model" forState:UIControlStateNormal];
  } else {
    [self.sourceDownloadDeleteButton setTitle:@"Download Model" forState:UIControlStateNormal];
  }
  if ([self isLanguageDownloaded:outputLanguage]) {
    [self.targetDownloadDeleteButton setTitle:@"Delete Model" forState:UIControlStateNormal];
  } else {
    [self.targetDownloadDeleteButton setTitle:@"Download Model" forState:UIControlStateNormal];
  }
}

- (BOOL)isLanguageDownloaded:(FIRTranslateLanguage)language {
  FIRTranslateRemoteModel *model = [self modelForLanguage:language];
  FIRModelManager *modelManager = [FIRModelManager modelManager];
  return [modelManager isModelDownloaded:model];
}

- (IBAction)listDownloadedModels {
  FIRModelManager *modelManager = [FIRModelManager modelManager];
  NSMutableString *listOfLanguages = [NSMutableString string];
  for (FIRTranslateRemoteModel *model in modelManager.downloadedTranslateModels) {
    if (listOfLanguages.length > 0) {
      [listOfLanguages appendString:@", "];
    }
    [listOfLanguages appendString:FIRTranslateLanguageCodeForLanguage(model.language)];
  }
  self.statusTextView.text = [NSString stringWithFormat:@"Downloaded models: %@", listOfLanguages];
}

- (IBAction)didTapDownloadDeleteSourceLanguage {
  [self handleDownloadDeleteWithPicker:self.inputPicker button:self.sourceDownloadDeleteButton];
}

- (IBAction)didTapDownloadDeleteTargetLanguage {
  [self handleDownloadDeleteWithPicker:self.outputPicker button:self.targetDownloadDeleteButton];
}

- (FIRTranslateRemoteModel *)modelForLanguage:(FIRTranslateLanguage)language {
  return [FIRTranslateRemoteModel translateRemoteModelWithLanguage:language];
}

- (void)modelDownloadDidCompleteWithNotification:(NSNotification *)notification {
  FIRTranslateRemoteModel *model = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
  if (![model isKindOfClass:FIRTranslateRemoteModel.class]) {
    return;
  }
  NSString *languageCode = FIRTranslateLanguageCodeForLanguage(model.language);

  dispatch_async(dispatch_get_main_queue(), ^{
    if (notification.name == FIRModelDownloadDidSucceedNotification) {
      self.statusTextView.text =
          [NSString stringWithFormat:@"Download succeeded for %@", languageCode];
    } else {
      self.statusTextView.text = [NSString stringWithFormat:@"Download failed for%@", languageCode];
    }
    [self updateDownloadDeleteButtonLabels];
  });
}

@end

NS_ASSUME_NONNULL_END
