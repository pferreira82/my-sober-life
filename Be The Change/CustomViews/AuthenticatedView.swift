import SwiftUI

struct AuthenticatedView<Content, Unauthenticated>: View where Content: View, Unauthenticated: View {
    @StateObject private var viewModel = AuthViewModel() // `@StateObject` owns the view model lifecycle
    @State private var presentingLoginScreen = false
    @State private var presentingProfileScreen = false
    @State private var dateOfBirth: Date = Date()
    @State private var sobrietyDate: Date = Date()

    var unauthenticated: Unauthenticated?
    @ViewBuilder var content: () -> Content

    public init(unauthenticated: Unauthenticated?, @ViewBuilder content: @escaping () -> Content) {
        self.unauthenticated = unauthenticated
        self.content = content
    }

    public init(@ViewBuilder unauthenticated: @escaping () -> Unauthenticated, @ViewBuilder content: @escaping () -> Content) {
        self.unauthenticated = unauthenticated()
        self.content = content
    }

    var body: some View {
        switch viewModel.authenticationState {
        case .unauthenticated, .authenticating:
            VStack {
                if let unauthenticated {
                    unauthenticated
                } else {
                    Text("You're not logged in.")
                }
                Button("Tap here to log in") {
                    viewModel.reset() // Access `reset` directly
                    presentingLoginScreen.toggle()
                }
            }
            .sheet(isPresented: $presentingLoginScreen) {
                AuthView()
                    .environmentObject(viewModel)
            }
        case .authenticated:
            VStack {
                content()
                Text("You're logged in as \(viewModel.displayName).")
                Button("Tap here to view your profile") {
                    presentingProfileScreen.toggle()
                }
            }
            .sheet(isPresented: $presentingProfileScreen) {
                NavigationView {
                    UserProfileView(
                        dateOfBirth: $dateOfBirth,
                        sobrietyDate: $sobrietyDate
                    ).environmentObject(viewModel)
                }
            }
        }
    }
}

extension AuthenticatedView where Unauthenticated == EmptyView {
    init(@ViewBuilder content: @escaping () -> Content) {
        self.unauthenticated = nil
        self.content = content
    }
}

struct AuthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedView {
            Text("You're signed in.")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(.yellow)
        }
    }
}
