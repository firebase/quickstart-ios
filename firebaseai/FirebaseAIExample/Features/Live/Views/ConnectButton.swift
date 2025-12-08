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

struct ConnectButton: View {
  var state: LiveViewModelState
  var onConnect: () async -> Void
  var onDisconnect: () async -> Void

  @State private var gradientAngle: Angle = .zero

  private var isConnected: Bool { state == .connected }

  private var title: String {
    switch state {
    case .connected: "Stop"
    case .connecting: "Connecting..."
    case .idle: "Start"
    }
  }

  private var image: String {
    switch state {
    case .connected: "stop.fill"
    case .connecting: "wifi.square.fill"
    case .idle: "play.square.fill"
    }
  }

  private var color: Color {
    switch state {
    case .connected: Color.red
    case .connecting: Color.secondary
    case .idle: Color.accentColor
    }
  }

  private var gradientColors: [Color] {
    switch state {
    case .connected: []
    case .connecting: [.secondary, .white]
    case .idle: [.red, .blue, .green, .yellow, .red]
    }
  }

  var body: some View {
    Button(action: onClick) {
      Label(title, systemImage: image)
        .font(.title2.bold())
        .frame(maxWidth: .infinity)
        .padding()
    }.disabled(state == .connecting).overlay(
      RoundedRectangle(cornerRadius: 35)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: gradientColors),
            center: .center,
            startAngle: gradientAngle,
            endAngle: gradientAngle + .degrees(360)
          ),
          lineWidth: 3
        )
    ).tint(color)
      .onAppear {
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
          self.gradientAngle = .degrees(360)
        }
      }
  }

  private func onClick() {
    Task {
      if isConnected {
        await onDisconnect()
      } else {
        await onConnect()
      }
    }
  }
}

#Preview {
  VStack(spacing: 30) {
    ConnectButton(state: .idle, onConnect: {}, onDisconnect: {})
    ConnectButton(state: .connecting, onConnect: {}, onDisconnect: {})
    ConnectButton(state: .connected, onConnect: {}, onDisconnect: {})
  }.padding(.horizontal)
}
