//
//  SidebarView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/21/24.
//

import SwiftUI

struct SidebarLayout<Content: View>: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isSidebarVisible: Bool = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content
                content
                    .blur(radius: isSidebarVisible ? 5 : 0)
                    .overlay(
                        Color.black.opacity(isSidebarVisible ? 0.4 : 0)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    isSidebarVisible = false
                                }
                            }
                    )

                // Sidebar
                if isSidebarVisible {
                    SidebarMenu(isSidebarVisible: $isSidebarVisible)
                        .frame(maxWidth: 300)
                        .transition(.move(edge: .leading))
                }

                // Hamburger Button
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation {
                                isSidebarVisible.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title)
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

struct SidebarMenu: View {
    @Binding var isSidebarVisible: Bool
    @EnvironmentObject var authViewModel: AuthViewModel // Access the AuthViewModel for logout
    @Environment(\.colorScheme) var colorScheme
    @State private var dateOfBirth: Date = Date()
    @State private var sobrietyDate: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            NavigationLink(destination: MainAppView()) {
                SidebarMenuItem(icon: "gauge", title: "Dashboard")
            }
            NavigationLink(destination: UserProfileView(
                dateOfBirth: $dateOfBirth,
                sobrietyDate: $sobrietyDate
            )) {
                SidebarMenuItem(icon: "person.crop.circle", title: "Profile")
            }
            NavigationLink(destination: JournalEntriesView()) {
                SidebarMenuItem(icon: "book", title: "My Sober Journal")
            }
//            NavigationLink(destination: AchievementsView()) {
//                SidebarMenuItem(icon: "star.circle", title: "Achievements")
//            }
//            NavigationLink(destination: CommunityView()) {
//                SidebarMenuItem(icon: "person.3", title: "Community")
//            }
//            NavigationLink(destination: SettingsView()) {
//                SidebarMenuItem(icon: "gearshape", title: "Settings")
//            }

            Spacer()
            
            Button(action: {
                authViewModel.signOut() // Call the sign-out function
                withAnimation {
                    isSidebarVisible = false
                }
            }) {
                SidebarMenuItem(icon: "arrowshape.turn.up.left", title: "Logout")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color.black : Color.white) // Dynamic background
        .edgesIgnoringSafeArea(.vertical)
    }
}

struct SidebarMenuItem: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
            Text(title)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black) // Dynamic text color
            Spacer()
        }
        .foregroundColor(colorScheme == .dark ? Color.white : Color.black) // Dynamic text color
        .padding(.vertical, 10)
    }
}

#Preview {
    SidebarLayout {
        Text("Sample Content")
            .font(.largeTitle)
            .padding()
    }
}
