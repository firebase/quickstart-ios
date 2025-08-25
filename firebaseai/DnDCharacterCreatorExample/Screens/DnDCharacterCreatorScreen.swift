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
import FirebaseCore
import FirebaseAI

struct DnDCharacterCreatorScreen: View {
  @StateObject var viewModel = DnDCharacterCreatorViewModel()
  @State private var screenshot: UIImage? = nil
  var firebaseService: FirebaseAI

  var body: some View {
    VStack(spacing: 20) {
      if viewModel.isLoading {
        ProgressView("Generating Character...")
      } else if let character = viewModel.character {
        characterDetailsView(character: character)
      } else {
        Text("Tap \"Generate\" to create a character.")
      }

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .padding()
      }

      Spacer()

      actionButtons
    }
    .onAppear {
      viewModel.configure(firebaseService: firebaseService)
    }
    .navigationTitle("DnD Character Creator")
    .sheet(item: $screenshot) { image in
      ShareSheet(activityItems: [image])
    }
  }

  private func characterDetailsView(character: DnDCharacter) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(alignment: .top, spacing: 20) {
        let image = viewModel
          .characterImage != nil ? Image(uiImage: viewModel.characterImage!) :
          Image(systemName: "person.fill")
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 200, height: 200)
          .clipShape(RoundedRectangle(cornerRadius: 10))

        VStack(alignment: .leading, spacing: 8) {
          VStack(alignment: .leading) {
            Text("Name").bold()
            Text(character.name)
              .lineLimit(3)
          }
          VStack(alignment: .leading) {
            Text("Age").bold()
            Text("\(character.age)")
          }
          VStack(alignment: .leading) {
            Text("City of Birth").bold()
            Text(character.cityOfBirth)
              .lineLimit(2)
          }
        }
      }

      VStack(alignment: .leading) {
        Text("Description:").bold()
        Text(character.description)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
  }

  private var actionButtons: some View {
    HStack(spacing: 20) {
      Button("Generate") {
        Task {
          await viewModel.generateCharacter()
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(viewModel.isLoading)

      Button("Save") {
        if let character = viewModel.character {
          let viewToSnapshot = characterDetailsView(character: character)
            .padding()
            .background(Color(.systemBackground))
          screenshot = viewToSnapshot.snapshot()
        }
      }
      .buttonStyle(.bordered)
      .disabled(viewModel.isLoading || viewModel.character == nil)
    }
    .padding()
  }
}

extension UIImage: @retroactive Identifiable {
  public var id: String {
    UUID().uuidString
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  var activityItems: [Any]
  var applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>)
    -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: applicationActivities
    )
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController,
                              context: UIViewControllerRepresentableContext<ShareSheet>) {}
}

#Preview {
  struct Wrapper: View {
    @State var model = DnDCharacterCreatorViewModel(
      character: DnDCharacter(name: "Peter Friese",
                              age: 25,
                              cityOfBirth: "Mountain View, CA",
                              description: "Software engineer, author, speaker, and musician with a passion for helping developers build great apps. Currently, he works as a Developer Relations Engineer / Developer Advocate on the Firebase team at Google, where he focuses on helping developers build better apps using Firebase on iOS and other Apple platforms.",
                              imagePrompt: ""),
      characterImage: UIImage(systemName: "person")
    )
    var firebase: FirebaseAI {
      return FirebaseAI.firebaseAI(app: FirebaseApp.app(), backend: .googleAI())
    }

    var body: some View {
      NavigationView {
        DnDCharacterCreatorScreen(viewModel: model,
                                  firebaseService: firebase)
      }
    }
  }

  return Wrapper()
}
