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
#if canImport(FirebaseAILogic)
  import FirebaseAILogic
#else
  import FirebaseAI
#endif

public struct Sample: Identifiable {
  public let id = UUID()
  public let title: String
  public let description: String
  public let useCases: [UseCase]
  public let navRoute: String
  public let modelName: String
  public let chatHistory: [ModelContent]?
  public let initialPrompt: String?
  public let systemInstruction: ModelContent?
  public let tools: [Tool]?
  public let generationConfig: GenerationConfig?
  public let liveGenerationConfig: LiveGenerationConfig?
  public let fileDataParts: [FileDataPart]?
  public let tip: InlineTip?

  public init(title: String,
              description: String,
              useCases: [UseCase],
              navRoute: String,
              modelName: String = "gemini-2.5-flash",
              chatHistory: [ModelContent]? = nil,
              initialPrompt: String? = nil,
              systemInstruction: ModelContent? = nil,
              tools: [Tool]? = nil,
              generationConfig: GenerationConfig? = nil,
              liveGenerationConfig: LiveGenerationConfig? = nil,
              fileDataParts: [FileDataPart]? = nil,
              tip: InlineTip? = nil) {
    self.title = title
    self.description = description
    self.useCases = useCases
    self.navRoute = navRoute
    self.modelName = modelName
    self.chatHistory = chatHistory
    self.initialPrompt = initialPrompt
    self.systemInstruction = systemInstruction
    self.tools = tools
    self.generationConfig = generationConfig
    self.liveGenerationConfig = liveGenerationConfig
    self.fileDataParts = fileDataParts
    self.tip = tip
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
      navRoute: "ChatScreen",
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
      title: "Hello world (with template)",
      description: "Uses a template to say hello. The template uses 'name' and 'language' (defaults to Spanish) as inputs.",
      useCases: [.text],
      navRoute: "GenerateContentFromTemplateScreen",
      initialPrompt: "Peter",
      systemInstruction: ModelContent(
        parts: "The user's name is {{name}}. They prefer to communicate in {{language}}."
      )
    ),
    Sample(
      title: "Chatbot recommendations for courses",
      description: "A chatbot suggests courses for a performing arts program.",
      useCases: [.text],
      navRoute: "ChatScreen",
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
      navRoute: "MultimodalScreen",
      initialPrompt: "Write a short, engaging blog post based on this picture." +
        " It should include a description of the meal in the" +
        " photo and talk about my journey meal prepping.",
      fileDataParts: [
        FileDataPart(
          uri: "https://storage.googleapis.com/cloud-samples-data/generative-ai/image/meal-prep.jpeg",
          mimeType: "image/jpeg"
        ),
      ]
    ),
    Sample(
      title: "Imagen - image generation",
      description: "Generate images using Imagen 3",
      useCases: [.image],
      navRoute: "ImagenScreen",
      initialPrompt: "A photo of a modern building with water in the background"
    ),
    Sample(
      title: "[T] Imagen - image generation",
      description: "[T] Generate images using Imagen 3",
      useCases: [.image],
      navRoute: "ImagenFromTemplateScreen",
      initialPrompt: "A photo of a modern building with water in the background"
    ),
    Sample(
      title: "Gemini Flash - image generation",
      description: "Generate and/or edit images using Gemini 2.0 Flash",
      useCases: [.image],
      navRoute: "ChatScreen",
      modelName: "gemini-2.0-flash-preview-image-generation",
      initialPrompt: "Hi, can you create a 3d rendered image of a pig " +
        "with wings and a top hat flying over a happy " +
        "futuristic scifi city with lots of greenery?",
      generationConfig: GenerationConfig(responseModalities: [.text, .image]),
    ),
    // Video
    Sample(
      title: "Hashtags for a video",
      description: "Generate hashtags for a video ad stored in Cloud Storage.",
      useCases: [.video],
      navRoute: "MultimodalScreen",
      initialPrompt: "Generate 5-10 hashtags that relate to the video content." +
        " Try to use more popular and engaging terms," +
        " e.g. #Viral. Do not add content not related to" +
        " the video.\n Start the output with 'Tags:'",
      fileDataParts: [
        FileDataPart(
          uri: "https://storage.googleapis.com/cloud-samples-data/generative-ai/video/google_home_celebrity_ad.mp4",
          mimeType: "video/mp4"
        ),
      ]
    ),
    Sample(
      title: "Summarize video",
      description: "Summarize a video and extract important dialogue.",
      useCases: [.video],
      navRoute: "MultimodalScreen",
      chatHistory: [
        ModelContent(role: "user", parts: "Can you help me with the description of a video file?"),
        ModelContent(
          role: "model",
          parts: "Sure! Click on the attach button below and choose a video file for me to describe."
        ),
      ],
      initialPrompt: "I have attached the video file. Provide a description of" +
        " the video. The description should also contain" +
        " anything important which people say in the video."
    ),
    // Audio
    Sample(
      title: "Audio Summarization",
      description: "Summarize an audio file",
      useCases: [.audio],
      navRoute: "MultimodalScreen",
      chatHistory: [
        ModelContent(role: "user", parts: "Can you help me summarize an audio file?"),
        ModelContent(
          role: "model",
          parts: "Of course! Click on the attach button below and choose an audio file for me to summarize."
        ),
      ],
      initialPrompt: "I have attached the audio file. Please analyze it and summarize the contents" +
        " of the audio as bullet points."
    ),
    Sample(
      title: "Translation from audio",
      description: "Translate an audio file stored in Cloud Storage",
      useCases: [.audio],
      navRoute: "MultimodalScreen",
      initialPrompt: "Please translate the audio in Mandarin.",
      fileDataParts: [
        FileDataPart(
          uri: "https://storage.googleapis.com/cloud-samples-data/generative-ai/audio/How_to_create_a_My_Map_in_Google_Maps.mp3",
          mimeType: "audio/mp3"
        ),
      ]
    ),
    // Document
    Sample(
      title: "Document comparison",
      description: "Compare the contents of 2 documents." +
        " Supported by the Vertex AI Gemini API because the documents are stored in Cloud Storage",
      useCases: [.document],
      navRoute: "MultimodalScreen",
      initialPrompt: "The first document is from 2013, and the second document is" +
        " from 2023. How did the standard deduction evolve?",
      fileDataParts: [
        FileDataPart(
          uri: "https://storage.googleapis.com/cloud-samples-data/generative-ai/pdf/form_1040_2013.pdf",
          mimeType: "application/pdf"
        ),
        FileDataPart(
          uri: "https://storage.googleapis.com/cloud-samples-data/generative-ai/pdf/form_1040_2023.pdf",
          mimeType: "application/pdf"
        ),
      ]
    ),
    // Function Calling
    Sample(
      title: "Weather Chat",
      description: "Use function calling to get the weather conditions" +
        " for a specific US city on a specific date.",
      useCases: [.functionCalling, .text],
      navRoute: "FunctionCallingScreen",
      initialPrompt: "What was the weather in Boston, MA on October 17, 2024?",
      tools: [.functionDeclarations([
        FunctionDeclaration(
          name: "fetchWeather",
          description: "Get the weather conditions for a specific US city on a specific date",
          parameters: [
            "city": .string(description: "The US city of the location"),
            "state": .string(description: "The US state of the location"),
            "date": .string(description: "The date for which to get the weather." +
              " Date must be in the format: YYYY-MM-DD"),
          ]
        ),
      ])]
    ),
    // Grounding
    Sample(
      title: "Grounding with Google Search",
      description: "Use Grounding with Google Search to get responses based on up-to-date information from the web.",
      useCases: [.text],
      navRoute: "GroundingScreen",
      initialPrompt: "What's the weather in Chicago this weekend?",
      tools: [.googleSearch()]
    ),
    // Live API
    Sample(
      title: "Live native audio",
      description: "Use the Live API to talk with the model via native audio.",
      useCases: [.audio],
      navRoute: "LiveScreen",
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [.audio],
        speech: SpeechConfig(voiceName: "Zephyr", languageCode: "en-US"),
        outputAudioTranscription: AudioTranscriptionConfig()
      )
    ),
    Sample(
      title: "Live function calling",
      description: "Use function calling with the Live API to ask the model to change the background color.",
      useCases: [.functionCalling, .audio],
      navRoute: "LiveScreen",
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
      ],
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [.audio],
        speech: SpeechConfig(voiceName: "Zephyr", languageCode: "en-US"),
        outputAudioTranscription: AudioTranscriptionConfig()
      ),
      tip: InlineTip(text: "Try asking the model to change the background color"),
    ),
  ]

  public static var sample = samples[0]
}
