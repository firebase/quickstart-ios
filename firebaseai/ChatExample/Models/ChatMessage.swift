// Copyright 2023 Google LLC
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

import FirebaseAI
import Foundation

public enum Participant {
  case system
  case user
}

public struct ChatMessage: Identifiable, Equatable {
  public let id = UUID().uuidString
  public var message: String
  public let participant: Participant
  public var groundingMetadata: GroundingMetadata?
  public var pending = false

  public static func pending(participant: Participant) -> ChatMessage {
    Self(message: "", participant: participant, pending: true)
  }

  // TODO(andrewheard): Add Equatable conformance to GroundingMetadata and remove this
  public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
    lhs.id == rhs.id && lhs.message == rhs.message && lhs.participant == rhs.participant && lhs
      .pending == rhs.pending
  }
}

public extension ChatMessage {
  static var samples: [ChatMessage] = [
    .init(message: "Hello. What can I do for you today?", participant: .system),
    .init(message: "Show me a simple loop in Swift.", participant: .user),
    .init(message: """
    Sure, here is a simple loop in Swift:

    # Example 1
    ```
    for i in 1...5 {
      print("Hello, world!")
    }
    ```

    This loop will print the string "Hello, world!" five times. The for loop iterates over a range of numbers,
    in this case the numbers from 1 to 5. The variable i is assigned each number in the range, and the code inside the loop is executed.

    **Here is another example of a simple loop in Swift:**
    ```swift
    var sum = 0
    for i in 1...100 {
      sum += i
    }
    print("The sum of the numbers from 1 to 100 is \\(sum).")
    ```

    This loop calculates the sum of the numbers from 1 to 100. The variable sum is initialized to 0, and then the for loop iterates over the range of numbers from 1 to 100. The variable i is assigned each number in the range, and the value of i is added to the sum variable. After the loop has finished executing, the value of sum is printed to the console.
    """, participant: .system),
  ]

  static var sample = samples[0]
}

public extension ChatMessage {
  static func from(_ modelContent: ModelContent) -> ChatMessage? {
    // TODO: add non-text parts to message when multi-model support is added
    let text = modelContent.parts.compactMap { ($0 as? TextPart)?.text }.joined()
    guard !text.isEmpty else {
      return nil
    }

    let participant: Participant = (modelContent.role == "user") ? .user : .system

    return ChatMessage(message: text, participant: participant)
  }

  static func from(_ modelContents: [ModelContent]) -> [ChatMessage] {
    return modelContents.compactMap { from($0) }
  }
}
