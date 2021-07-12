//
//  NewPostsView.swift
//  DatabaseExample
//
//  Created by Judy Liu on 7/7/21.
//

import SwiftUI

struct NewPostsView: View {
  @StateObject var user = UserViewModel()
  @State private var newPostTitle: String = ""
  @State private var newPostBody: String = ""
  @State private var placeholderText: String = "Say something..."
  var screenWidth = UIScreen.main.bounds.width
  var screenHeight = UIScreen.main.bounds.height
  
  var body: some View {
    VStack {
      TextField("Add a title", text: $newPostTitle)
        .padding()
        .font(.title)
      ZStack {
        if newPostBody.isEmpty {
          TextEditor(text: $placeholderText)
            .foregroundColor(.gray)
            .padding()
            .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
        }
        TextEditor(text: $newPostBody)
          .padding()
          .opacity(self.newPostBody.isEmpty ? 0.25 : 1)
      }
    }
    .navigationTitle("New Post")
    .navigationBarItems(trailing:
                          Button(action: {
                            user.post(
                              title: newPostTitle,
                              body: newPostBody
                            )
                          }) {
                            Text("Post")
                          })
  }
}

struct NewPostsView_Previews: PreviewProvider {
  static var previews: some View {
    NewPostsView()
  }
}
