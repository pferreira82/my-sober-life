import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

struct JournalEntry: Identifiable, Codable {
    var id: String // Firestore document ID
    var title: String
    var content: String
    var imageURLs: [String] // Supports multiple images
    var date: Date
    var location: String
    var weatherDescription: String? // Optional weather description
    var weatherIcon: String? // Optional weather icon
}

class AddJournalEntryModel {
    /// Save or update a journal entry
    static func saveJournalEntry(
        entry: JournalEntry,
        images: [UIImage]? = nil, // Supports optional images
        completion: @escaping (Result<JournalEntry, Error>) -> Void
    ) {
        let firestore = Firestore.firestore()
        let documentRef = firestore.collection("journalEntries").document(entry.id)

        if let images = images, !images.isEmpty {
            uploadImages(images, entryID: entry.id) { result in
                switch result {
                case .success(let imageURLs):
                    var updatedEntry = entry
                    updatedEntry.imageURLs = imageURLs
                    saveToFirestore(entry: updatedEntry, documentRef: documentRef, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            // Save entry directly if no images are provided
            saveToFirestore(entry: entry, documentRef: documentRef, completion: completion)
        }
    }

    /// Upload multiple images to Firebase Storage
    private static func uploadImages(
        _ images: [UIImage],
        entryID: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        let storageRef = Storage.storage().reference().child("journalEntries/\(entryID)")
        var uploadedURLs: [String] = []
        let dispatchGroup = DispatchGroup()

        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            let imageRef = storageRef.child("image_\(index).jpg")
            dispatchGroup.enter()

            imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Image upload error: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }

                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Failed to get download URL: \(error.localizedDescription)")
                    } else if let url = url {
                        uploadedURLs.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if uploadedURLs.count == images.count {
                completion(.success(uploadedURLs))
            } else {
                completion(.failure(NSError(
                    domain: "ImageUpload",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to upload all images."]
                )))
            }
        }
    }

    /// Load a single journal entry by ID
    static func loadJournalEntry(
        entryId: String,
        completion: @escaping (Result<JournalEntry, Error>) -> Void
    ) {
        print("Model load journal entry")
        let db = Firestore.firestore()
        db.collection("journalEntries").document(entryId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists,
                  let entry = try? snapshot.data(as: JournalEntry.self) else {
                completion(.failure(NSError(
                    domain: "Firestore",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Entry not found or decoding failed."]
                )))
                return
            }

            completion(.success(entry))
        }
    }

    /// Load all journal entries
    static func loadJournalEntries(completion: @escaping (Result<[JournalEntry], Error>) -> Void) {
        print("Model load journal entries")
        let db = Firestore.firestore()
        db.collection("journalEntries")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let entries = snapshot?.documents.compactMap { doc -> JournalEntry? in
                        try? doc.data(as: JournalEntry.self)
                    } ?? []
                    completion(.success(entries))
                }
            }
    }

    /// Save to Firestore
    private static func saveToFirestore(
        entry: JournalEntry,
        documentRef: DocumentReference,
        completion: @escaping (Result<JournalEntry, Error>) -> Void
    ) {
        do {
            try documentRef.setData(from: entry, merge: true)
            completion(.success(entry))
        } catch {
            completion(.failure(error))
        }
    }

    /// Delete a journal entry
    static func deleteJournalEntry(
        entryID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Firestore.firestore().collection("journalEntries").document(entryID).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
