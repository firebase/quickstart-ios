//
//  HomeView.swift
//  FunctionsExample
//
//  Created by Gran Luo on 11/16/21.
//

import SwiftUI

struct HomeView: View {

  @AppStorage("signin") var isSignInViewActive: Bool = true
    var body: some View {

      VStack{
        Button(action: {isSignInViewActive = true}){
          Text("restart")
        }
        AddNumbers()
//        AddMessage()
//        NavigationView {
//          NavigationLink(destination: Text("Second View")) {
//            Text("Hello, World!")
//          }
//          .navigationTitle("Navigation")
//        }
        Spacer()
      }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
