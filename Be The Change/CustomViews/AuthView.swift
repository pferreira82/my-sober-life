//
//  AuthView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/12/24.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        VStack {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            switch viewModel.flow {
             case .login:
                 LoginView()
                     .environmentObject(viewModel)
             case .signUp:
                 SignupView()
                     .environmentObject(viewModel)
             }
        }
        .onAppear {
            print("AuthView loaded with flow: \(viewModel.flow)")
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
