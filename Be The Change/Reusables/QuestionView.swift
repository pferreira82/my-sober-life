//
//  QuestionView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/19/24.
//

import SwiftUI

struct QuestionView<Content: View>: View {
    let title: String
    let content: Content
    let onNext: () -> Void

    init(title: String, @ViewBuilder content: () -> Content, onNext: @escaping () -> Void) {
        self.title = title
        self.content = content()
        self.onNext = onNext
    }
    
    var body: some View {
        VStack(spacing: 20) {
              Text(title)
                  .font(.headline)
                  .multilineTextAlignment(.center)
                  .padding()

              content

              Button(action: onNext) {
                  Text("Next")
                      .padding()
                      .frame(maxWidth: .infinity)
                      .background(Color.blue)
                      .foregroundColor(.white)
                      .cornerRadius(10)
              }
              .padding(.top, 20)
          }
    }
}

#Preview {
    QuestionView(
        title: "What is your name?",
        content: {
            TextField("Enter your name", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
        },
        onNext: {
            print("Next button tapped")
        }
    )
}
