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

import Foundation
import FirebaseAI

public struct Sample: Identifiable {
  public let id = UUID()
  public let title: String
  public let description: String
  public let useCases: [UseCase]
  public let chatHistory: [ModelContent]?
  public let initialPrompt: String?
  public let systemInstruction: ModelContent?
  public let tools: [Tool]?

  public init(title: String,
              description: String,
              useCases: [UseCase],
              chatHistory: [ModelContent]? = nil,
              initialPrompt: String? = nil,
              systemInstruction: ModelContent? = nil,
              tools: [Tool]? = nil) {
    self.title = title
    self.description = description
    self.useCases = useCases
    self.chatHistory = chatHistory
    self.initialPrompt = initialPrompt
    self.systemInstruction = systemInstruction
    self.tools = tools
  }

  public var useCase: UseCase {
    return useCases.first ?? .text
  }

  public static func find(by id: UUID?) -> Sample? {
    guard let id = id else { return nil }
    return samples.first { $0.id == id }
  }
}

extension Sample {
  public static let samples: [Sample] = [
    // Text
    Sample(
      title: "Travel tips",
      description: "The user wants the model to help a new traveler" +
        " with travel tips",
      useCases: [.text],
      chatHistory: [
        ModelContent(
          role: "user",
          parts: "I have never traveled before. When should I book a flight?"
        ),
        ModelContent(
          role: "model",
          parts: "You should book flights a couple of months ahead of time. It will be cheaper and more flexible for you."
        ),
        ModelContent(role: "user", parts: "Do I need a passport?"),
        ModelContent(
          role: "model",
          parts: "If you are traveling outside your own country, make sure your passport is up-to-date and valid for more than 6 months during your travel."
        ),
      ],
      initialPrompt: "What else is important when traveling?",
      systemInstruction: ModelContent(parts: "You are a Travel assistant. You will answer" +
        " questions the user asks based on the information listed" +
        " in Relevant Information. Do not hallucinate. Do not use" +
        " the internet."),
    ),
    Sample(
      title: "Chatbot recommendations for courses",
      description: "A chatbot suggests courses for a performing arts program.",
      useCases: [.text],
      initialPrompt: "I am interested in Performing Arts. I have taken Theater 1A.",
      systemInstruction: ModelContent(parts: "You are a chatbot for the county's performing and fine arts" +
        " program. You help students decide what course they will" +
        " take during the summer."),
    ),
    // Image
    Sample(
      title: "Blog post creator",
      description: "Create a blog post from an image file stored in Cloud Storage.",
      useCases: [.image],
      chatHistory: [
        ModelContent(role: "user", parts: "Can you help me create a blog post about this image?"),
        ModelContent(
          role: "model",
          parts: "I'd be happy to help you create a blog post! Please share the image you'd like me to analyze and write about."
        ),
      ],
      initialPrompt: "Please analyze this image and create an engaging blog post"
    ),
    Sample(
      title: "Imagen 3 - image generation",
      description: "Generate images using Imagen 3",
      useCases: [.image],
      initialPrompt: "A photo of a modern building with water in the background"
    ),
    Sample(
      title: "Gemini 2.0 Flash - image generation",
      description: "Generate and/or edit images using Gemini 2.0 Flash",
      useCases: [.image],
      chatHistory: [
        ModelContent(role: "user", parts: "Can you edit this image to make it brighter?"),
        ModelContent(
          role: "model",
          parts: "I can help you edit images using Gemini 2.0 Flash. Please share the image you'd like me to modify."
        ),
      ],
      initialPrompt: ""
    ),
    // Video
    Sample(
      title: "Hashtags for a video",
      description: "Generate hashtags for a video ad stored in Cloud Storage.",
      useCases: [.video],
      chatHistory: [
        ModelContent(role: "user", parts: "Can you suggest hashtags for my product video?"),
        ModelContent(
          role: "model",
          parts: "I'd be happy to help you generate relevant hashtags! Please share your video or describe what it's about so I can suggest appropriate hashtags."
        ),
      ],
      initialPrompt: ""
    ),
    Sample(
      title: "Summarize video",
      description: "Summarize a video and extract important dialogue.",
      useCases: [.video],
      chatHistory: [
        ModelContent(role: "user", parts: "Can you summarize this video for me?"),
        ModelContent(
          role: "model",
          parts: "I can help you summarize videos and extract key dialogue. Please share the video you'd like me to analyze."
        ),
      ],
      initialPrompt: ""
    ),
    // Audio
    Sample(
      title: "Audio Summarization",
      description: "Summarize an audio file",
      useCases: [.audio],
      chatHistory: [
        ModelContent(role: "user", parts: "Can you summarize this audio recording?"),
        ModelContent(
          role: "model",
          parts: "I can help you summarize audio files. Please share the audio recording you'd like me to analyze."
        ),
      ],
      initialPrompt: ""
    ),
    Sample(
      title: "Translation from audio",
      description: "Translate an audio file stored in Cloud Storage",
      useCases: [.audio],
      chatHistory: [
        ModelContent(role: "user", parts: "Can you translate this audio from Spanish to English?"),
        ModelContent(
          role: "model",
          parts: "I can help you translate audio files. Please share the audio file you'd like me to translate."
        ),
      ],
      initialPrompt: ""
    ),
    // Document
    Sample(
      title: "Document comparison",
      description: "Compare the contents of 2 documents." +
        " Only supported by the Vertex AI Gemini API because the documents are stored in Cloud Storage",
      useCases: [.document],
      chatHistory: [
        ModelContent(role: "user", parts: "Can you compare these two documents for me?"),
        ModelContent(
          role: "model",
          parts: "I can help you compare documents using the Vertex AI Gemini API. Please share the two documents you'd like me to compare."
        ),
      ],
      initialPrompt: ""
    ),
    // Function Calling
    Sample(
      title: "Weather Chat",
      description: "Use function calling to get the weather conditions" +
        " for a specific US city on a specific date.",
      useCases: [.functionCalling, .text],
      chatHistory: [
        ModelContent(role: "user", parts: "What's the weather like in New York today?"),
        ModelContent(
          role: "model",
          parts: "I can help you get weather information using function calling. Let me check the current weather conditions for New York."
        ),
      ],
      initialPrompt: ""
    ),
    // Grounding
    Sample(
      title: "Grounding with Google Search",
      description: "Use Grounding with Google Search to get responses based on up-to-date information from the web.",
      useCases: [.text],
      initialPrompt: "What's the weather in Chicago this weekend?",
      tools: [.googleSearch()]
    ),
  ]

  public static var sample = samples[0]
}
