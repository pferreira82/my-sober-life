//
// UserProfileView.swift
// Favourites
//
// Created by Peter Friese on 08.07.2022
// Copyright © 2022 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct UserProfileView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var phoneNumber: String = ""
    @Binding var dateOfBirth: Date
    @Binding var sobrietyDate: Date
    @State private var isEditing: Bool = false
    @State private var hasChanges: Bool = false
    @State private var isLoading: Bool = true
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var accomplishment: String = ""
    @State private var doingThisFor: String = ""

    let db = Firestore.firestore()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // Customize as needed
        return formatter
    }()

    var body: some View {
        SidebarLayout {
            VStack(spacing: 10) {
                // Profile Picture Section
                ZStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }

                    if isEditing {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Edit")
                                .font(.caption)
                                .padding(5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .onChange(of: selectedPhotoItem) {
                            loadSelectedImage()
                        }
                        .offset(y: 60)
                    }
                }
                .padding(.bottom, 10)

                // Editable or Static Name
                VStack() {
                    Text("Name")
                        .font(.headline)
                    if isEditing {
                        TextField("Name", text: $name, onEditingChanged: { _ in hasChanges = true })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(name.isEmpty ? "No Name Provided" : name)
                    }
                }

                // Editable or Static Email
                VStack() {
                    Text("Email")
                        .font(.headline)
                    if isEditing {
                        TextField("Email", text: $email, onEditingChanged: { _ in hasChanges = true })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    } else {
                        Text(email.isEmpty ? "No Email Provided" : email)
                    }
                }
                
                VStack() {
                    Text("Phone")
                        .font(.headline)
                    if isEditing {
                        TextField("Phone", text: $phoneNumber, onEditingChanged: { _ in hasChanges = true })
                            .textFieldStyle(RoundedBorderTextFieldStyle())                    } else {
                        Text(phoneNumber.isEmpty ? "No Phone Provided" : phoneNumber)
                    }
                }


                Divider()

                // Editable or Static Prompt Answers
                // Birthday Section
                VStack(alignment: .leading) {
                    Text("Birthday")
                        .font(.headline)
                    if isEditing {
                        DatePicker(
                            "Pick Birthday",
                            selection: $dateOfBirth,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: dateOfBirth) {
                            hasChanges = true
                        }
                    } else {
                        Text(dateFormatter.string(from: dateOfBirth))
                            .font(.body)
                    }
                }

                // Sobriety Date Section
                VStack(alignment: .leading) {
                    Text("Sobriety Date")
                        .font(.headline)
                    if isEditing {
                        DatePicker(
                            "Pick Sobriety Date",
                            selection: $sobrietyDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: sobrietyDate) {
                            hasChanges = true
                        }
                    } else {
                        Text(dateFormatter.string(from: sobrietyDate))
                            .font(.body)
                    }
                }

                
                Divider()
                
                VStack() {
                    Text("What is one thing you want to accomplish once sober?")
                        .font(.headline)
                    if isEditing {
                        TextField("What is one thing you want to accomplish once sober?", text: $accomplishment, onEditingChanged: { _ in hasChanges = true })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)                    } else {
                                Text(accomplishment.isEmpty ? "No Answer Provided" : accomplishment)
                    }
                }
                
                Divider()
                
                VStack() {
                    Text("What is motivating you to get sober?")
                        .font(.headline)
                    if isEditing {
                        TextField("What is motivating you to get sober?", text: $doingThisFor, onEditingChanged: { _ in hasChanges = true })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    } else {
                        Text(doingThisFor.isEmpty ? "No Answer Provided" : doingThisFor)
                    }
                }

                Divider()

                // Save Button (only visible if changes are made)
                if hasChanges {
                    Button(action: saveProfile) {
                        Text("Save Changes")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!hasChanges)
                }

                // Edit Button
                Button(action: toggleEditMode) {
                    Text(isEditing ? "Cancel" : "Edit")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isEditing ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .onAppear {
            loadUserProfile()
        }
    }

    // MARK: - Functions
    
    func toggleEditMode() {
        withAnimation {
            if isEditing {
                // If exiting edit mode without saving, reload profile
                loadUserProfile()
                hasChanges = false
            }
            isEditing.toggle()
        }
    }

    func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.name = data["name"] as? String ?? ""
                self.email = data["email"] as? String ?? ""
                self.phoneNumber = data["phone"] as? String ?? ""
                self.dateOfBirth = (data["dateOfBirth"] as? Timestamp)?.dateValue() ?? Date()
                self.sobrietyDate = (data["sobrietyDate"] as? Timestamp)?.dateValue() ?? Date()
                self.accomplishment = data["accomplishment"] as? String ?? ""
                self.doingThisFor = data["doingThisFor"] as? String ?? ""

                if let profileImageUrl = data["profileImageUrl"] as? String {
                    downloadProfileImage(from: profileImageUrl)
                }
            }
            isLoading = false
        }
    }

    func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let updatedData: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phoneNumber,
            "dateOfBirth": dateOfBirth, // Provide a fallback or handle absence
            "sobrietyDate": sobrietyDate, // Provide a fallback or handle absence
            "accomplishment": accomplishment,
            "doingThisFor": doingThisFor
        ]

        // Save profile fields
        db.collection("users").document(userId).updateData(updatedData) { error in
            if let error = error {
                print("Error saving profile: \(error.localizedDescription)")
                return
            }
            
            // Upload profile image if available
            if let selectedImage = profileImage {
                Task {
                    await uploadProfileImage(profileImage: selectedImage)
                    completeSaveAndReload()
                }
            } else {
                completeSaveAndReload()
            }
        }
    }

    func loadSelectedImage() {
        if let selectedPhotoItem = selectedPhotoItem {
            Task {
                do {
                    if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        self.profileImage = image
                        await uploadProfileImage(profileImage: image)
                        hasChanges = true
                    } else {
                        print("[ERROR] Could not load image data.")
                    }
                } catch {
                    print("[ERROR] \(error.localizedDescription)")
                }
            }
        }
    }


    func uploadProfileImage(profileImage: UIImage) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            return
        }

        // Get a reference to Firebase Storage
        let storage = Storage.storage()
        let imageReference = storage.reference(withPath: "profileImages/\(userId)/avatar.png")

        // Prepare metadata and image data
        let metaData = StorageMetadata()
        var imageData: Data

        if let pngData = profileImage.pngData() {
            metaData.contentType = "image/png"
            imageData = pngData
        } else if let jpegData = profileImage.jpegData(compressionQuality: 1.0) {
            metaData.contentType = "image/jpeg"
            imageData = jpegData
        } else {
            print("Error: Unable to retrieve image data in supported format")
            return
        }

        do {
            // Upload the image
            let resultMetaData = try await imageReference.putDataAsync(imageData, metadata: metaData) { progress in
                if let progress {
                    print("Upload Progress: \(progress.fractionCompleted * 100)%")
                    if progress.isFinished {
                        print("Upload completed.")
                    }
                }
            }
            print("Upload finished. Metadata: \(resultMetaData)")

            // Get the download URL

            // Save the URL to Firestore
            do {
                let downloadURL = try await imageReference.downloadURL()
                print("Download URL: \(downloadURL.absoluteString)")
                
                let firestore = Firestore.firestore()
                try await firestore.collection("users").document(userId).setData([
                    "profileImageUrl": downloadURL.absoluteString
                ], merge: true)
                print("Image URL saved successfully to Firestore.")
            } catch {
                print("Error saving image URL to Firestore: \(error.localizedDescription)")
            }
        } catch {
            print("An error occurred while uploading: \(error.localizedDescription)")
        }
    }

    func downloadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
    
    func completeSaveAndReload() {
        loadUserProfile()
        withAnimation {
            isEditing = false
            hasChanges = false
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    @State static var dateOfBirth: Date = Date()
    @State static var sobrietyDate: Date = Date()

    static var previews: some View {
        NavigationView {
            UserProfileView(
                dateOfBirth: $dateOfBirth,
                sobrietyDate: $sobrietyDate
            )
            .environmentObject(AuthViewModel())
        }
    }
}
