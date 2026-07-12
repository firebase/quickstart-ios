// Copyright 2026 Google LLC
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

#if canImport(FoundationModels)
  import Foundation
  import FoundationModels

  @available(iOS 26.0, *)
  @Generable
  struct IdentifiedObject: Equatable, Codable {
    @Guide(description: "The name of the primary object or landmark detected.")
    let name: String

    @Guide(
      description: "The category of the object (e.g. Landmark, Plant, Food, Animal, Device, Clothing)."
    )
    let category: String

    @Guide(description: "A short, 2-sentence description of the object and interesting facts.")
    let description: String
  }

  @available(iOS 26.0, *)
  @Generable
  struct TextSummary: Equatable, Codable {
    @Guide(description: "A list of exactly 2 key summary points.")
    let summaryPoints: [String]
  }
#endif
