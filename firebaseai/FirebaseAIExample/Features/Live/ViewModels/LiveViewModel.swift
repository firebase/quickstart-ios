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

import FirebaseAILogic
import Foundation
import OSLog
import AVFoundation
import SwiftUI
import AVKit
import Combine

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
  var transcriptTypewriter: TypeWriterViewModel = TypeWriterViewModel()

  @Published
  var backgroundColor: Color? = nil

  @Published
  var hasTranscripts: Bool = false

  @Published
  var title: String

  @Published
  var tip: String?

  @Published
  var isAudioOutputEnabled: Bool = {
    #if targetEnvironment(simulator)
      return false
    #else
      return true
    #endif
  }()

  private var model: LiveGenerativeModel?
  private var liveSession: LiveSession?

  private var audioController: AudioController?
  private var microphoneTask = Task<Void, Never> {}

  init(backendType: BackendOption, sample: Sample? = nil) {
    let firebaseService = backendType == .googleAI
      ? FirebaseAI.firebaseAI(backend: .googleAI())
      : FirebaseAI.firebaseAI(backend: .vertexAI())

    model = firebaseService.liveModel(
      modelName: (backendType == .googleAI) ? "gemini-2.5-flash-native-audio-preview-09-2025" :
        "gemini-live-2.5-flash-preview-native-audio-09-2025",
      generationConfig: sample?.liveGenerationConfig,
      tools: sample?.tools,
      systemInstruction: sample?.systemInstruction
    )
    title = sample?.title ?? ""
    tip = sample?.tip
  }

  /// Start a connection to the model.
  ///
  /// If a connection is already active, you'll need to call ``LiveViewModel/disconnect()`` first.
  func connect() async {
    guard let model, state == .idle else {
      return
    }

    if !isAudioOutputEnabled {
      logger.warning("Playback audio is disabled.")
    }

    guard await requestRecordPermission() else {
      logger.warning("The user denied us permission to record the microphone.")
      return
    }

    state = .connecting
    transcriptTypewriter.restart()
    hasTranscripts = false

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
    transcriptTypewriter.clearPending()

    withAnimation {
      backgroundColor = nil
    }
  }

  /// Starts recording data from the user's microphone, and sends it to the model.
  private func startRecording() async throws {
    guard let audioController, let liveSession else { return }

    let stream = try await audioController.listenToMic()
    microphoneTask = Task {
      do {
        for await audioBuffer in stream {
          await liveSession.sendAudioRealtime(try audioBuffer.int16Data())
        }
      } catch {
        logger.error("\(String(describing: error))")
        self.error = error
        await disconnect()
      }
    }
  }

  /// Starts queuing responses from the model for parsing.
  private func startProcessingResponses() async throws {
    guard let liveSession else { return }

    for try await response in liveSession.responses {
      try await processServerMessage(response)
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

  private func processServerMessage(_ message: LiveServerMessage) async throws {
    switch message.payload {
    case let .content(content):
      try await processServerContent(content)
    case let .toolCall(toolCall):
      try await processFunctionCalls(functionCalls: toolCall.functionCalls ?? [])
    case .toolCallCancellation:
      // we don't have any long running functions to cancel
      return
    case let .goingAwayNotice(goingAwayNotice):
      let time = goingAwayNotice.timeLeft?.description ?? "soon"
      logger.warning("Going away in: \(time)")
    }
  }

  private func processServerContent(_ content: LiveServerContent) async throws {
    if let message = content.modelTurn {
      try await processAudioMessages(message)
    }

    if content.isTurnComplete {
      // add a space, so the next time a transcript comes in, it's not squished with the previous one
      transcriptTypewriter.appendText(" ")
    }

    if content.wasInterrupted {
      logger.warning("Model was interrupted")
      await audioController?.interrupt()
      transcriptTypewriter.clearPending()
      // adds an em dash to indiciate that the model was cutoff
      transcriptTypewriter.appendText("— ")
    } else if let transcript = content.outputAudioTranscription?.text {
      appendAudioTranscript(transcript)
    }
  }

  private func processAudioMessages(_ content: ModelContent) async throws {
    for part in content.parts {
      if let part = part as? InlineDataPart {
        if part.mimeType.starts(with: "audio/pcm") {
          if isAudioOutputEnabled {
            try await audioController?.playAudio(audio: part.data)
          }
        } else {
          logger.warning("Received non audio inline data part: \(part.mimeType)")
        }
      }
    }
  }

  private func processFunctionCalls(functionCalls: [FunctionCallPart]) async throws {
    let responses = try functionCalls.map { functionCall in
      switch functionCall.name {
      case "changeBackgroundColor":
        return try changeBackgroundColor(args: functionCall.args, id: functionCall.functionId)
      case "clearBackgroundColor":
        return clearBackgroundColor(id: functionCall.functionId)
      default:
        logger.debug("Function call: \(String(describing: functionCall))")
        throw ApplicationError("Unknown function named \"\(functionCall.name)\".")
      }
    }

    await liveSession?.sendFunctionResponses(responses)
  }

  private func appendAudioTranscript(_ transcript: String) {
    hasTranscripts = true
    transcriptTypewriter.appendText(transcript)
  }

  private func changeBackgroundColor(args: JSONObject, id: String?) throws -> FunctionResponsePart {
    guard case let .string(color) = args["color"] else {
      logger.debug("Function arguments: \(String(describing: args))")
      throw ApplicationError("Missing `color` parameter.")
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
