// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


/// Firebase Auth supported identity providers and other methods of authentication
enum AuthProvider: String {
    case Google, Apple, Twitter, Microsoft, GitHub, Yahoo, Facebook
    case EmailPassword = "Email & Password Login"
    case Passwordless = "Email Link/Passwordless"
    case PhoneNumber = "Phone Number"
    case Anonymous = "Anonymous Authentication"
    case Custom = "Custom Auth System"
    
    var id: String { self.rawValue.lowercased().appending(".com") }
}
