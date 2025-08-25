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
import UIKit

@MainActor
class DnDCharacterCreatorViewModel: ObservableObject {
  @Published var character: DnDCharacter?
  @Published var characterImage: UIImage?
  @Published var errorMessage: String?
  @Published var isLoading = false

  private var generativeModel: GenerativeModel?
  private var imagen: ImagenModel?

  init(character: DnDCharacter? = nil,
       characterImage: UIImage? = nil,
       errorMessage: String? = nil,
       isLoading: Bool = false,
       generativeModel: GenerativeModel? = nil,
       imagen: ImagenModel? = nil) {
    self.character = character
    self.characterImage = characterImage
    self.errorMessage = errorMessage
    self.isLoading = isLoading
    self.generativeModel = generativeModel
    self.imagen = imagen
  }

  func configure(firebaseService: FirebaseAI) {
    let modelName = "gemini-2.5-flash-lite"
    let generationConfig = GenerationConfig(
      responseMIMEType: "application/json",
      responseSchema: Schema.object(properties: [
        "name": .string(),
        "age": .integer(description: "Age between 21 and 340"),
        "cityOfBirth": .string(),
        "description": .string(description: "A short, engaging description of the character."),
        "imagePrompt": .string(
          description: "A prompt to use to generate a portrait of the character using Imagen."
        ),
      ])
    )
    generativeModel = firebaseService.generativeModel(
      modelName: modelName,
      generationConfig: generationConfig
    )
    imagen = firebaseService.imagenModel(modelName: "imagen-4.0-fast-generate-001",
                                         generationConfig: ImagenGenerationConfig(
                                           numberOfImages: 1,
                                           aspectRatio: .square1x1
                                         ))
  }

  func generateCharacter() async {
    guard let generativeModel = generativeModel else {
      errorMessage = "Generative AI services not configured."
      return
    }

    isLoading = true
    errorMessage = nil

    let prompt = "Generate a Dungeons and Dragons character that's beach themed."

    do {
      let response = try await generativeModel.generateContent(prompt)
      if let text = response.text, let data = text.data(using: .utf8) {
        let decoder = JSONDecoder()
        character = try decoder.decode(DnDCharacter.self, from: data)
        await generateImage()
      } else {
        errorMessage = "Failed to generate character details."
      }
    } catch {
      errorMessage = "Error generating character: \(error.localizedDescription)"
    }

    isLoading = false
  }

  private func generateImage() async {
    guard let imagen = imagen, let character = character else {
      errorMessage = "Imagen service not configured or character not generated."
      return
    }

    do {
      let result = try await imagen.generateImages(prompt: character.imagePrompt)
      if let image = result.images.first {
        characterImage = UIImage(data: image.data)
      }
    } catch {
      errorMessage = "Error generating image: \(error.localizedDescription)"
    }
  }
}
