// Copyright 2025 Google LLC
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

import SwiftUI
import Foundation

@MainActor
class TypeWriterViewModel: ObservableObject {
  @Published
  var text: String = ""

  /// How long to wait (in milliseconds) between showing the next character.
  var delay: Int = 65

  private var pendingText = [Character]()
  private var processTextTask: Task<Void, Never>?

  init() {
    processTask()
  }

  deinit {
    processTextTask?.cancel()
  }

  /// Queues text to show.
  ///
  /// Since the text is queued, the text wont be displayed until the previous
  /// pending text is populated.
  func appendText(_ text: String) {
    pendingText.append(contentsOf: text)
  }

  /// Clears any text from the queue that is pending being added to the text.
  func clearPending() {
    pendingText.removeAll()
  }

  /// Restarts the class to be a fresh instance.
  ///
  /// Effectively, this removes all the currently tracked text,
  /// and any pending text.
  func restart() {
    clearPending()
    text = ""
  }

  /// Long running task for processing characters.
  private func processTask() {
    processTextTask = Task {
      var delay = delay
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(delay))

        delay = processNextCharacter()
      }
    }
  }

  /// Determines the delay for the next character, adding pending text as needed.
  ///
  /// We don't have a delay when outputting whitespace or the end of a sentence.
  ///
  ///   - Returns: The MS delay before working on the next character in the queue.
  private func processNextCharacter() -> Int {
    guard !pendingText.isEmpty else {
      return delay // Default delay if no text is pending
    }

    let char = pendingText.removeFirst()
    text.append(char)

    return (char.isWhitespace || char.isEndOfSentence) ? 0 : delay
  }
}

extension Character {
  /// Marker for punctuation that dictates the end of a sentence.
  ///
  /// Namely, this checks for `.`, `!` and `?`.
  var isEndOfSentence: Bool {
    self == "." || self == "!" || self == "?"
  }
}
