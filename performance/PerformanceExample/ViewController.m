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

@import FirebasePerformance;

@interface ViewController()
@property (strong, nonatomic) FIRTrace *trace;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    
  // Start tracing
  self.trace = [FIRPerformance startTraceWithName:@"request_trace"];
}

- (IBAction)makeARequest:(id)sender {
  NSString *target = @"https://www.google.com";
  NSURL *targetUrl = [NSURL URLWithString:target];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:targetUrl];
  request.HTTPMethod = @"GET";

  [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
    ^(NSData * _Nullable data,
      NSURLResponse * _Nullable response,
      NSError * _Nullable error) {

      NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      NSLog(@"Data received: %@", responseString);
    }] resume];

  [_trace incrementCounterNamed:@"request_sent"];
}


- (void)dealloc {
    [_trace stop];
}

@end
