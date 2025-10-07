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

/// How long to wait (in milliseconds) between showing the next character.
private let CharDelayMS = 65

/// The intended amount of characters in a line.
///
/// Can exceed this if the line doesn't end in a space of punctuation.
private let LineCharacterLength = 20

/// The max amount of lines to hold references for at a time.
private let MaxLines = 3

/// Creates lines of transcripts to display, populated in a type-writer manner.
@MainActor
class TranscriptViewModel: ObservableObject {
  /// Lines of characters to display.
  @Published
  var audioTranscripts: [TranscriptLine] = []

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
  func appendTranscript(_ text: String) {
    pendingText.append(contentsOf: text)
  }

  /// Clears any text from the queue that is pending being added to a transcript line.
  func clearPending() {
    pendingText.removeAll()
  }

  /// Restarts the class to be a fresh instance.
  ///
  /// Effectively, this removes all the currently tracked transcript lines,
  /// and any pending text.
  func restart() {
    clearPending()
    audioTranscripts.removeAll()
  }

  /// Long running task for processing characters.
  private func processTask() {
    processTextTask = Task {
      var delay = CharDelayMS
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(delay))

        delay = processNextCharacter()
      }
    }
  }

  private func processNextCharacter() -> Int {
    guard !pendingText.isEmpty else {
      return CharDelayMS // Default delay if no text is pending
    }

    let char = pendingText.removeFirst()
    var line = popCurrentLine()
    line.message.append(char)

    let nextDelay = determineNextDelayAndFinalize(for: char, in: &line)

    updateTranscripts(with: line)

    return nextDelay
  }

  /// Determines the delay for the next character, finalizing the line as needed.
  ///
  /// We don't have a delay when outputting whitespace or the end of a sentence.
  ///
  /// We also don't mark a line as "complete" unless it ends in whitespace or some
  /// punctuation; as this helps avoid weird situations where words are split across lines.
  ///
  ///   - Returns: The MS delay before working on the next character in the queue.
  private func determineNextDelayAndFinalize(for char: Character,
                                             in line: inout TranscriptLine) -> Int {
    if char.isWhitespace || char.isEndOfSentence {
      if line.message.count >= LineCharacterLength {
        line.isFinal = true
      }

      return 0
    }

    return CharDelayMS
  }

  /// Updates `audioTranscripts` with the current line.
  ///
  /// Will remove the oldest line if we exceed `MaxLines`.
  private func updateTranscripts(with line: TranscriptLine) {
    audioTranscripts.append(line)

    if audioTranscripts.count > MaxLines {
      // fade out the removal; makes it less jumpy during rendering when lines are moved up
      withAnimation {
        _ = audioTranscripts.removeFirst()
      }
    }
  }

  /// Removes the last line from `audioTranscripts`.
  ///
  /// If the last line is already finalized, a new line will be returned instead.
  private func popCurrentLine() -> TranscriptLine {
    if audioTranscripts.last?.isFinal != false {
      return TranscriptLine()
    }
    return audioTranscripts.removeLast()
  }
}

extension Character {
  var isEndOfSentence: Bool {
    self == "." || self == "!" || self == "?"
  }
}
