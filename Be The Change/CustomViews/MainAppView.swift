//
//  MainAppView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/21/24.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        SidebarLayout {
            VStack {
                Text("Welcome to My Sober Life!")
                    .font(.largeTitle)
                    .padding()

                Button(action: authViewModel.signOut) {
                    Text("Sign Out")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(AuthViewModel())
}
