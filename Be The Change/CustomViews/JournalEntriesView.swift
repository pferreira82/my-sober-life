import SwiftUI
import FirebaseFirestore

struct JournalEntriesView: View {
    @State private var journalEntries: [JournalEntry] = []
    @State private var isAddingEntry = false
    @State private var selectedEntry: JournalEntry? = nil
    @Environment(\.colorScheme) var colorScheme

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM dd, yyyy h:mm a"
        return formatter
    }()

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack {
                    if journalEntries.isEmpty {
                        Text("No Journal Entries Yet")
                            .foregroundColor(.gray)
                            .font(Font.custom("ShadowsIntoLight", size: 30))
                            .padding()
                    } else {
                        List {
                            ForEach(journalEntries) { entry in
                                VStack(alignment: .leading) {
                                    Text(entry.title)
                                        .font(Font.custom("ShadowsIntoLight", size: 25))
                                    Text(dateFormatter.string(from: entry.date))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .onTapGesture {
                                    selectedEntry = entry
                                }
                            }
                            .onDelete(perform: deleteEntry)
                        }
                    }
                }
                .navigationTitle("Entries")

                // Floating Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isAddingEntry = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(colorScheme == .dark ? Color.blue : Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(16)
                    }
                }
            }
            .sheet(isPresented: $isAddingEntry) {
                AddJournalEntryView(
                    isNewEntry: true,
                    onSave: { newEntry in
                        journalEntries.append(newEntry)
                        fetchJournalEntries()
                        isAddingEntry = false
                    },
                    onCancel: {
                        isAddingEntry = false
                    }
                )
            }
            .sheet(item: $selectedEntry) { entry in
                AddJournalEntryView(
                    initialEntry: entry,
                    isNewEntry: false,
                    onSave: { updatedEntry in
                        if let index = journalEntries.firstIndex(where: { $0.id == updatedEntry.id }) {
                            journalEntries[index] = updatedEntry
                        }
                        fetchJournalEntries()
                        selectedEntry = nil
                    },
                    onCancel: {
                        selectedEntry = nil
                    }
                )
            }
            .onAppear(perform: fetchJournalEntries)
        }
    }

    private func fetchJournalEntries() {
        let firestore = Firestore.firestore()
        firestore.collection("journalEntries").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching entries: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }
            do {
                let entries = try documents.compactMap { doc in
                    try doc.data(as: JournalEntry.self)
                }
                self.journalEntries = entries.sorted(by: { $0.date > $1.date })
            } catch {
                print("Error decoding entries: \(error.localizedDescription)")
            }
        }
    }

    private func deleteEntry(at offsets: IndexSet) {
        offsets.forEach { index in
            let entry = journalEntries[index]
            let firestore = Firestore.firestore()

            // Remove the entry from Firestore
            firestore.collection("journalEntries").document(entry.id).delete { error in
                if let error = error {
                    print("Error deleting entry: \(error.localizedDescription)")
                } else {
                    print("Entry deleted successfully")
                }
            }
        }

        // Remove the entry from the list
        journalEntries.remove(atOffsets: offsets)
    }
}

#Preview {
    JournalEntriesView()
}
