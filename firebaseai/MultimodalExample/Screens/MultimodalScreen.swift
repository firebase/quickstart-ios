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
import SwiftUI
import PhotosUI
import ConversationKit

struct MultimodalScreen: View {
  let backendType: BackendOption
  @StateObject var viewModel: MultimodalViewModel

  @State private var showingPhotoPicker = false
  @State private var showingFilePicker = false
  @State private var showingLinkDialog = false
  @State private var linkText = ""
  @State private var linkMimeType = ""
  @State private var selectedPhotoItems = [PhotosPickerItem]()

  init(backendType: BackendOption, sample: Sample? = nil) {
    self.backendType = backendType
    _viewModel =
      StateObject(wrappedValue: MultimodalViewModel(backendType: backendType,
                                                    sample: sample))
  }

  private var attachmentPreviewScrollView: some View {
    AttachmentPreviewScrollView(
      attachments: viewModel.attachments,
      onAttachmentRemove: viewModel.removeAttachment
    )
  }

  var body: some View {
    NavigationStack {
      ConversationView(messages: $viewModel.messages,
                       userPrompt: viewModel.initialPrompt) { message in
        MessageView(message: message)
      }
      .attachmentActions {
        Button(action: showLinkDialog) {
          Label("Link", systemImage: "link")
        }
        Button(action: showFilePicker) {
          Label("File", systemImage: "doc.text")
        }
        Button(action: showPhotoPicker) {
          Label("Photo", systemImage: "photo.on.rectangle.angled")
        }
      }
      .attachmentPreview { attachmentPreviewScrollView }
      .onSendMessage { message in
        await viewModel.sendMessage(message.content ?? "", streaming: true)
      }
      .onError { error in
        viewModel.presentErrorDetails = true
      }
      .sheet(isPresented: $viewModel.presentErrorDetails) {
        if let error = viewModel.error {
          ErrorDetailsView(error: error)
        }
      }
      .photosPicker(
        isPresented: $showingPhotoPicker,
        selection: $selectedPhotoItems,
        maxSelectionCount: 5,
        matching: .any(of: [.images, .videos])
      )
      .fileImporter(
        isPresented: $showingFilePicker,
        allowedContentTypes: [.pdf, .audio],
        allowsMultipleSelection: true
      ) { result in
        handleFileImport(result)
      }
      .alert("Add Web URL", isPresented: $showingLinkDialog) {
        TextField("Enter URL", text: $linkText)
        TextField("Enter mimeType", text: $linkMimeType)
        Button("Add") {
          handleLinkAttachment()
        }
        Button("Cancel", role: .cancel) {
          linkText = ""
          linkMimeType = ""
        }
      }
    }
    .onChange(of: selectedPhotoItems) { _, newItems in
      handlePhotoSelection(newItems)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: newChat) {
          Image(systemName: "square.and.pencil")
        }
      }
    }
    .navigationTitle(viewModel.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func newChat() {
    viewModel.startNewChat()
  }

  private func showPhotoPicker() {
    showingPhotoPicker = true
  }

  private func showFilePicker() {
    showingFilePicker = true
  }

  private func showLinkDialog() {
    showingLinkDialog = true
  }

  private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
    Task {
      for item in items {
        do {
          let attachment = try await MultimodalAttachment.fromPhotosPickerItem(item)
          await MainActor.run {
            viewModel.addAttachment(attachment)
          }
        } catch {
          await MainActor.run {
            viewModel.error = error
            viewModel.presentErrorDetails = true
          }
        }
      }
      await MainActor.run {
        selectedPhotoItems = []
      }
    }
  }

  private func handleFileImport(_ result: Result<[URL], Error>) {
    switch result {
    case let .success(urls):
      Task {
        for url in urls {
          do {
            let attachment = try await MultimodalAttachment.fromFilePickerItem(from: url)
            await MainActor.run {
              viewModel.addAttachment(attachment)
            }
          } catch {
            await MainActor.run {
              viewModel.error = error
              viewModel.presentErrorDetails = true
            }
          }
        }
      }
    case let .failure(error):
      viewModel.error = error
      viewModel.presentErrorDetails = true
    }
  }

  private func handleLinkAttachment() {
    guard !linkText.isEmpty, let url = URL(string: linkText) else {
      return
    }

    let trimmedMime = linkMimeType.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    Task {
      do {
        let attachment = try await MultimodalAttachment.fromURL(url, mimeType: trimmedMime)
        await MainActor.run {
          viewModel.addAttachment(attachment)
        }
      } catch {
        await MainActor.run {
          viewModel.error = error
          viewModel.presentErrorDetails = true
        }
      }
      await MainActor.run {
        linkText = ""
        linkMimeType = ""
      }
    }
  }
}

#Preview {
  MultimodalScreen(backendType: .googleAI)
}
