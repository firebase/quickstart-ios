//
//  Copyright (c) 2015 Google Inc.
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

#import "Post.h"

@implementation Post

- (instancetype)init {
  return [self initWithUid:@"" andAuthor:@"" andTitle:@"" andBody:@""];
}

- (instancetype)initWithUid:(NSString *)uid
                 andAuthor:(NSString *)author
                  andTitle:(NSString *)title
                   andBody:(NSString *)body {
  self = [super init];
  if (self) {
    self.uid = uid;
    self.author = author;
    self.title = title;
    self.body = body;
  }
  return self;
}
@end
