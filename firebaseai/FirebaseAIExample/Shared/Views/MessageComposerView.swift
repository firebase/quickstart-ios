// Copyright 2026 Google LLC
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

struct MessageComposerView: View {
  @Binding var message: String
  @Binding var attachments: [MultimodalAttachment]
  
  private var hasAttachments: Bool = true
  private var onSubmitClosure: (() -> Void)? = nil
  
  init(message: Binding<String>, attachments: Binding<[MultimodalAttachment]>) {
    self._message = message
    self._attachments = attachments
  }
  
  init(message: Binding<String>) {
    self._message = message
    self._attachments = .constant([])
    self.hasAttachments = false
  }
  
  var body: some View {
    VStack(spacing: 8) {
      // Draft attachments preview
      if hasAttachments && !attachments.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(attachments) { attachment in
              ZStack(alignment: .topTrailing) {
                AttachmentPreviewCard(attachment: attachment)
                  .frame(width: 140, height: 60)
                
                Button(action: {
                  attachments.removeAll { $0.id == attachment.id }
                }) {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .background(Color.white.clipShape(Circle()))
                }
                .offset(x: 4, y: -4)
              }
            }
          }
          .padding(.horizontal)
        }
      }
      
      HStack(spacing: 12) {
        TextField("Type a message...", text: $message, axis: .vertical)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(.systemGray6))
          .cornerRadius(18)
          .lineLimit(1...5)
        
        Button(action: {
          if let onSubmit = onSubmitClosure {
            onSubmit()
          }
        }) {
          Image(systemName: "arrow.up.circle.fill")
            .font(.system(size: 28))
            .foregroundColor(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty ? .gray : .blue)
        }
        .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty)
      }
      .padding(.horizontal)
    }
  }
}

extension MessageComposerView {
  func disableAttachments(_ disable: Bool = true) -> Self {
    var copy = self
    copy.hasAttachments = !disable
    return copy
  }
  
  func onSubmitAction(_ perform: @escaping () -> Void) -> Self {
    var copy = self
    copy.onSubmitClosure = perform
    return copy
  }
}
