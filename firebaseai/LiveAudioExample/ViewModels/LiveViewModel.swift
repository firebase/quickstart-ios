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

import FirebaseAI
import Foundation
import OSLog
import AVFoundation
import SwiftUI
import AVKit

enum LiveViewModelState {
  case idle
  case connecting
  case connected
}

@MainActor
class LiveViewModel: ObservableObject {
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

  @Published
  var error: Error?

  @Published
  var state: LiveViewModelState = .idle

  @Published
  var transcriptViewModel: TranscriptViewModel = TranscriptViewModel()

  @Published
  var backgroundColor: Color? = nil

  private var model: LiveGenerativeModel?
  private var liveSession: LiveSession?

  private var audioController: AudioController?
  private var microphoneTask = Task<Void, Never> {}

  init(firebaseService: FirebaseAI, backend: BackendOption) {
    model = firebaseService.liveModel(
      modelName: (backend == .googleAI) ? "gemini-live-2.5-flash-preview" : "gemini-2.0-flash-exp",
      generationConfig: LiveGenerationConfig(
        responseModalities: [.audio],
        speech: SpeechConfig(voiceName: "Zephyr", languageCode: "en-US"),
        outputAudioTranscription: AudioTranscriptionConfig()
      ),
      tools: [
        .functionDeclarations([
          FunctionDeclaration(
            name: "changeBackgroundColor",
            description: "Changes the background color to the specified hex color.",
            parameters: [
              "color": .string(
                description: "Hex code of the color to change to. (eg, #F54927)"
              ),
            ],
          ),
          FunctionDeclaration(
            name: "clearBackgroundColor",
            description: "Removes the background color.",
            parameters: [:]
          ),
        ]),
      ]
    )
  }

  /// Start a connection to the model.
  ///
  /// If a connection is already active, you'll need to call ``LiveViewModel/disconnect()`` first.
  func connect() async {
    guard let model, state == .idle else {
      return
    }

    guard await requestRecordPermission() else {
      logger.warning("The user denied us permission to record the microphone.")
      return
    }

    state = .connecting
    transcriptViewModel.restart()

    do {
      liveSession = try await model.connect()
      audioController = try await AudioController()

      try await startRecording()

      state = .connected
      try await startProcessingResponses()
    } catch {
      logger.error("\(String(describing: error))")
      self.error = error
      await disconnect()
    }
  }

  /// Disconnects the model.
  ///
  /// Will stop any pending playback, and the recording of the mic.
  func disconnect() async {
    await audioController?.stop()
    await liveSession?.close()
    microphoneTask.cancel()
    state = .idle
    liveSession = nil
    transcriptViewModel.clearPending()

    withAnimation {
      backgroundColor = nil
    }
  }

  /// Starts recording data from the user's microphone, and sends it to the model.
  private func startRecording() async throws {
    guard let audioController, let liveSession else { return }

    let stream = try await audioController.listenToMic()
    microphoneTask = Task {
      for await audioBuffer in stream {
        await liveSession.sendAudioRealtime(audioBuffer.int16Data())
      }
    }
  }

  /// Starts queuing responses from the model for parsing.
  private func startProcessingResponses() async throws {
    guard let liveSession else { return }

    for try await response in liveSession.responses {
      await processServerMessage(response)
    }
  }

  /// Requests permission to record the user's microphone, returning the result.
  ///
  /// This is a requirement on iOS devices, on top of needing the proper recording
  /// intents.
  private func requestRecordPermission() async -> Bool {
    await withCheckedContinuation { cont in
      if #available(iOS 17.0, *) {
        Task {
          let ok = await AVAudioApplication.requestRecordPermission()
          cont.resume(with: .success(ok))
        }
      } else {
        AVAudioSession.sharedInstance().requestRecordPermission { ok in
          cont.resume(with: .success(ok))
        }
      }
    }
  }

  private func processServerMessage(_ message: LiveServerMessage) async {
    switch message.payload {
    case let .content(content):
      await processServerContent(content)
    case let .toolCall(toolCall):
      await processFunctionCalls(functionCalls: toolCall.functionCalls ?? [])
    case .toolCallCancellation:
      // we don't have any long running functions to cancel
      return
    case let .goingAwayNotice(goingAwayNotice):
      let time = goingAwayNotice.timeLeft?.description ?? "soon"
      logger.warning("Going away in: \(time)")
    }
  }

  private func processServerContent(_ content: LiveServerContent) async {
    if let message = content.modelTurn {
      await processAudioMessages(message)
    }

    if content.isTurnComplete {
      // add a space, so the next time a transcript comes in, it's not squished with the previous one
      transcriptViewModel.appendTranscript(" ")
    }

    if content.wasInterrupted {
      logger.warning("Model was interrupted")
      await audioController?.interrupt()
      transcriptViewModel.clearPending()
      // adds an em dash to indiciate that the model was cutoff
      transcriptViewModel.appendTranscript("— ")
    } else if let transcript = content.outputAudioTranscription?.text {
      appendAudioTranscript(transcript)
    }
  }

  private func processAudioMessages(_ content: ModelContent) async {
    for part in content.parts {
      if let part = part as? InlineDataPart {
        if part.mimeType.starts(with: "audio/pcm") {
          await audioController?.playAudio(audio: part.data)
        } else {
          logger.warning("Received non audio inline data part: \(part.mimeType)")
        }
      }
    }
  }

  private func processFunctionCalls(functionCalls: [FunctionCallPart]) async {
    let responses = functionCalls.map { functionCall in
      switch functionCall.name {
      case "changeBackgroundColor":
        return changeBackgroundColor(args: functionCall.args, id: functionCall.functionId)
      case "clearBackgroundColor":
        return clearBackgroundColor(id: functionCall.functionId)
      default:
        logger.debug("Function call: \(String(describing: functionCall))")
        fatalError("Unknown function named \"\(functionCall.name)\".")
      }
    }

    await liveSession?.sendFunctionResponses(responses)
  }

  private func appendAudioTranscript(_ transcript: String) {
    transcriptViewModel.appendTranscript(transcript)
  }

  private func changeBackgroundColor(args: JSONObject, id: String?) -> FunctionResponsePart {
    guard case let .string(color) = args["color"] else {
      logger.debug("Function arguments: \(String(describing: args))")
      fatalError("Missing `color` parameter.")
    }

    withAnimation {
      backgroundColor = Color(hex: color)
    }

    if backgroundColor == nil {
      logger.warning("The model sent us an invalid hex color: \(color)")
    }

    return FunctionResponsePart(
      name: "changeBackgroundColor",
      response: JSONObject(),
      functionId: id
    )
  }

  private func clearBackgroundColor(id: String?) -> FunctionResponsePart {
    withAnimation {
      backgroundColor = nil
    }

    return FunctionResponsePart(
      name: "clearBackgroundColor",
      response: JSONObject(),
      functionId: id
    )
  }
}
