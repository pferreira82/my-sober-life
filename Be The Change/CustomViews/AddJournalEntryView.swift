//
//  AddJournalEntryView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/26/24.
//

import SwiftUI
import PhotosUI
import CoreLocation
import FirebaseStorage
import FirebaseFirestore

struct ImageWrapper: Identifiable, Equatable {
    let id = UUID()
    let url: String?
    var loadedImage: UIImage?

    init(url: String?, loadedImage: UIImage? = nil) {
        self.url = url
        self.loadedImage = loadedImage
    }

    static func == (lhs: ImageWrapper, rhs: ImageWrapper) -> Bool {
        lhs.id == rhs.id
    }
}


struct WeatherData: Decodable {
    let main: Main
    let weather: [Weather]
}

struct Main: Decodable {
    let temp: Double
}

struct Weather: Decodable {
    let description: String
    let icon: String
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    private let callback: (CLLocationCoordinate2D?) -> Void

    init(callback: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.callback = callback
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted, .denied:
            callback(nil) // Notify that location is not available
        case .notDetermined:
            // Waiting for user to decide
            break
        @unknown default:
            callback(nil) // Handle unexpected cases
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first?.coordinate {
            callback(location)
            manager.stopUpdatingLocation() // Stop updates after getting location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to fetch location: \(error.localizedDescription)")
        callback(nil)
    }
}

struct AddJournalEntryView: View {
    var initialEntry: JournalEntry? = nil // Optional initial entry for editing
    let entryID: String? = nil // ID of the journal entry (for pulling data)
    let isNewEntry: Bool // Indicates if it's a new entry
    let onSave: (JournalEntry) -> Void
    let onCancel: () -> Void // Callback for cancel button
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var isPresentingImagePicker = false
    @State private var existingImageURLs: [String] = []
    @State private var isEditing: Bool = false
    @State private var location: String = ""
    @State private var initialDate: Date? = nil
    @State private var weatherDescription: String = "Fetching weather..."
    @State private var weatherIcon: String? = nil
    @State private var isLoading = true // Show loading indicator while fetching
    @State private var locationManagerDelegate: LocationManagerDelegate? // Retain the delegate
    @State private var allImages: [ImageWrapper] = []
    
    //    Aurora
    @State private var glowOpacity: Double = 0.6
    @State private var waveOpacity1: Double = 0.3
    @State private var waveOpacity2: Double = 0.2
    @State private var waveOpacity3: Double = 0.4
    @State private var waveOpacity4: Double = 0.2
    @State private var waveOffset1: CGFloat = -250
    @State private var waveOffset2: CGFloat = -150
    @State private var waveOffset3: CGFloat = -400
    @State private var waveOffset4: CGFloat = 100
    // For animated gradient and glow on the button
    @State private var waveOffset: CGFloat = 0.0
    @State private var buttonGlowOpacity: Double = 0.5 // Button glow animation state
    
    @State private var showAlert = false // For permission alerts
    
    private let locationManager = CLLocationManager()
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss // Dismiss the view
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM dd, yyyy h:mm a"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                // Aurora Glow and Waves Background
                ZStack {
                    // Aurora Wave Layers
                    AuroraWave(offset: waveOffset1, amplitude: 80, colors: [.blue.opacity(0.3), .green.opacity(0.2), .clear])
                        .frame(height: 150)
                        .opacity(waveOpacity1)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                waveOpacity1 = 0.8
                            }
                        }
                    AuroraWave(offset: waveOffset2, amplitude: 90, colors: [.red.opacity(0.9), .purple.opacity(0.2), .clear])
                        .frame(height: 150)
                        .opacity(waveOpacity2)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                                waveOpacity2 = 0.9
                            }
                        }
                    AuroraWave(offset: waveOffset3, amplitude: 100, colors: [.green.opacity(0.05), .red.opacity(0.1), .clear])
                        .frame(height: 100)
                        .opacity(waveOpacity3)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                                waveOpacity3 = 0.6
                            }
                        }
                    AuroraWave(offset: waveOffset4, amplitude: 50, colors: [.blue.opacity(0.9), .green.opacity(0.1), .clear])
                        .frame(height: 100)
                        .opacity(waveOpacity4)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                                waveOpacity4 = 0.7
                            }
                        }
                    VStack {
                        // Display current date at the top
                        Text(dateFormatter.string(from: initialDate ?? Date()))
                            .font(Font.custom("Forum", size: 20))
                        
                        // Display Location
                        Text(location.isEmpty ? "Fetching Location..." : location)
                            .font(.subheadline)
                            .foregroundColor(location.contains("denied") ? .red : .gray)
                            .padding(.bottom, 2)
                        
                        // Display Weather
                        if let weatherIcon = weatherIcon {
                            HStack {
                                if #available(iOS 18.0, *) {
                                    Image(systemName: weatherIcon) // Replace with your weather icon logic
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.gray)
                                        .opacity(0.2)
//                                      .symbolEffect(.breathe)
                                } else {
                                    Image(systemName: weatherIcon) // Replace with your weather icon logic
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.gray)
                                        .opacity(0.2)
                                }
                                Text(weatherDescription)
                                    .foregroundColor(location.contains("denied") ? .red : .gray)
                                    .font(.subheadline)
                            }
                        } else {
                            Text(weatherDescription)
                                .font(.body)
                        }
                    }
                }
                // Display Title
                if isNewEntry || isEditing {
                    TextField("Title", text: $title)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .font(Font.custom("ShadowsIntoLight", size: 30))
                        .fontWeight(.heavy)
                        .cornerRadius(10)
                        .padding(.horizontal)
                } else {
                    Text(title.isEmpty ? "No Title" : title)
                        .font(Font.custom("ShadowsIntoLight", size: 28))
                        .fontWeight(.heavy)
                        .padding(6)
                        .multilineTextAlignment(.center)
                }
                
                // Display Content
                if isNewEntry || isEditing {
                    TextEditor(text: $content)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 5)
                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(minHeight: 150)
                        .padding(.horizontal, 16)
                        .font(Font.custom("Caveat", size: 24))
                } else {
                    Text(content.isEmpty ? "No Content" : content)
                        .padding()
                        .multilineTextAlignment(.leading)
                        .font(Font.custom("Caveat", size: 20))
                }
                
                // Image Display or Picker
                if isEditing || isNewEntry {
                    Button(action: {
                        isPresentingImagePicker = true
                    }) {
                        Label("Add Images", systemImage: "photo.on.rectangle")
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                imageThumbnailsView()
                
                // Update Location Button (only in edit mode)
                if isEditing {
                    Button("Update Location") {
                        fetchLocation()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Action Buttons
                HStack {
                    if isEditing || isNewEntry {
                        RectangularGradientButton(
                            title: "Cancel",
                            color1: Color.red,
                            color2: Color.purple,
                            color3: Color.red,
                            action: {
                                isEditing = false
                                onCancel() // Notify parent view about cancellation
                                dismiss()  // Close the view
                            })
                            .frame(maxWidth: .infinity)
                            .opacity(buttonGlowOpacity)
                            .shadow(color: Color.blue.opacity(buttonGlowOpacity), radius: 20, x: 0, y: 0) // Glow effect
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    if isEditing || isNewEntry {
                        RectangularGradientButton(title: "Save", color1: Color.blue, color2: Color.purple, color3: Color.blue, action: saveEntry)
                        .opacity(buttonGlowOpacity)
                        .frame(maxWidth: .infinity)
                        .shadow(color: Color.blue.opacity(buttonGlowOpacity), radius: 20, x: 0, y: 0) // Glow effect
                    }
                }
                .padding()
            }
            .onAppear {
                if let entryID = entryID {
                    print("WTF")
                    fetchJournalEntry(entryID: entryID) // Pass the unwrapped value
                }
                if isNewEntry {
                    requestLocationAccess()
                }
                
                if let entry = initialEntry {
                    loadEntryDetails(entry)
                    allImages = entry.imageURLs.map { ImageWrapper(url: $0) }
                    loadImages() // Ensure images are loaded for editing
                }
                
                startWaveAnimations()
                
                // Button Glow Animation
                withAnimation(
                    Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
                ) {
                    buttonGlowOpacity = 0.9
                }
            }
            .sheet(isPresented: $isPresentingImagePicker) {
                PhotosPickerView(selectedImages: $selectedImages)
                    .onDisappear {
                        for image in selectedImages {
                            if !allImages.contains(where: { $0.loadedImage == image }) {
                                var newImageWrapper = ImageWrapper(url: nil)
                                newImageWrapper.loadedImage = image
                                allImages.append(newImageWrapper)
                            }
                        }
                    }
            }
        }
    }
    
    private func deleteImageFromStorage(url: String) {
        let storageRef = Storage.storage().reference(forURL: url)
        storageRef.delete { error in
            if let error = error {
                print("Error deleting image: \(error.localizedDescription)")
            } else {
                print("Image deleted successfully.")
            }
        }
    }
    
    private func fetchJournalEntry(entryID: String) {
        AddJournalEntryModel.loadJournalEntry(entryId: entryID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entry):
                    title = entry.title
                    content = entry.content
                    location = entry.location
                    weatherDescription = entry.weatherDescription ?? "Weather not available"
                    weatherIcon = entry.weatherIcon
                    existingImageURLs = entry.imageURLs
                    print("Existing image URLs: \(existingImageURLs)")
                    
                    // Call the no-argument `loadImages` method
                    print("TEST WTF")
                    loadImages()
                    
                    isLoading = false
                case .failure(let error):
                    print("Error fetching entry: \(error.localizedDescription)")
                }
                isLoading = false
            }
        }
    }
    
    /// Loads the details of an existing journal entry
    private func loadEntryDetails(_ entry: JournalEntry) {
        title = entry.title
        content = entry.content
        initialDate = entry.date
        location = entry.location
        weatherDescription = entry.weatherDescription ?? "Weather not available"
        weatherIcon = entry.weatherIcon
        existingImageURLs = entry.imageURLs
    }
    
    private func imageThumbnailsView() -> some View {
        ScrollView(isEditing || isNewEntry ? .horizontal : .vertical) {
            if isEditing || isNewEntry {
                HStack(spacing: 10) {
                    ForEach(allImages, id: \.id) { imageWrapper in
                        ZStack(alignment: .topTrailing) {
                            if let loadedImage = imageWrapper.loadedImage {
                                Image(uiImage: loadedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                                    .clipped()
                            } else {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }

                            // Delete button
                            Button(action: {
                                removeImage(imageWrapper)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .offset(x: -8, y: 8)
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(allImages, id: \.id) { imageWrapper in
                        if let loadedImage = imageWrapper.loadedImage {
                            Image(uiImage: loadedImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .shadow(radius: 4)
                        } else {
                            ProgressView()
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func loadImagesIfNeeded() {
        for index in allImages.indices {
            guard allImages[index].loadedImage == nil,
                  let urlString = allImages[index].url,
                  let url = URL(string: urlString) else {
                print("Image already loaded or invalid URL at index \(index).")
                continue
            }

            print("Starting image load for URL: \(urlString) at index \(index).")

            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("Error loading image at index \(index): \(error.localizedDescription)")
                    return
                }

                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        print("Successfully loaded image for URL: \(urlString) at index \(index).")
                        allImages[index].loadedImage = uiImage
                        // Trigger a view update
                        allImages = allImages.map { $0 }
                    }
                } else {
                    print("Failed to decode image data for URL: \(urlString) at index \(index).")
                }
            }.resume()
        }
    }

    private func removeImage(_ imageWrapper: ImageWrapper) {
        if let index = allImages.firstIndex(where: { $0.id == imageWrapper.id }) {
            let removedImage = allImages.remove(at: index)
            if let url = removedImage.url {
                deleteImageFromStorage(url: url)
            }
        }
    }
    
    private func startWaveAnimations() {
        withAnimation(Animation.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
            waveOffset1 = 100
            waveOffset2 = -100
            waveOffset3 = 150
            waveOffset4 = -150
        }
    }

    private func fetchLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        let delegate = LocationManagerDelegate { coordinates in
            DispatchQueue.main.async {
                if let coordinates = coordinates {
                    // Use reverse geocoding to get the address
                    let geocoder = CLGeocoder()
                    let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        if let error = error {
                            print("Error reverse geocoding location: \(error.localizedDescription)")
                            self.location = "Unable to fetch address."
                        } else if let placemark = placemarks?.first {
                            // Construct address string from placemark
                            let address = [
                                placemark.name,            // Street name or place
                                placemark.locality,        // City
                                placemark.administrativeArea, // State
                                placemark.country          // Country
                            ].compactMap { $0 }.joined(separator: ", ")
                            
                            self.location = address.isEmpty ? "Address not available." : address
                            self.fetchWeather(latitude: coordinates.latitude, longitude: coordinates.longitude)
                        } else {
                            self.location = "No placemarks found."
                        }
                    }
                } else {
                    self.location = "Unable to fetch location."
                }
            }
        }

        locationManagerDelegate = delegate // Retain the delegate
        locationManager.delegate = delegate

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            location = "Waiting for location permission..."
        case .restricted, .denied:
            location = "Location access denied. Please enable it in Settings."
        @unknown default:
            location = "Unknown location status."
        }
    }

    
    /// Saves the journal entry
    private func saveEntry() {
        guard !title.isEmpty, !content.isEmpty else {
            print("Error: Title or content is empty.")
            return
        }

        let entryDate = initialEntry?.date ?? Date() // Use existing date if editing, otherwise use current date

        let newImages = allImages.compactMap { $0.loadedImage } // Extract new images for upload
        let existingURLs = allImages.compactMap { $0.url }   // Extract existing URLs

        uploadImages(newImages, entryID: initialEntry?.id ?? UUID().uuidString) { result in
            switch result {
            case .success(let uploadedURLs):
                let updatedEntry = JournalEntry(
                    id: initialEntry?.id ?? UUID().uuidString,
                    title: title,
                    content: content,
                    imageURLs: existingURLs + uploadedURLs, // Combine existing and new URLs
                    date: entryDate, // Use the determined date
                    location: location,
                    weatherDescription: weatherDescription,
                    weatherIcon: weatherIcon
                )

                AddJournalEntryModel.saveJournalEntry(entry: updatedEntry, images: []) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let savedEntry):
                            print("Saved entry successfully.")
                            onSave(savedEntry)
                            dismiss()
                        case .failure(let error):
                            print("Error saving entry: \(error.localizedDescription)")
                        }
                    }
                }

            case .failure(let error):
                print("Error uploading images: \(error.localizedDescription)")
            }
        }
    }

    private func saveJournalEntryToFirestore(entry: JournalEntry) async throws {
        let documentRef = Firestore.firestore().collection("journalEntries").document(entry.id)
        try documentRef.setData(from: entry, merge: true)
    }

    private func uploadJournalImages(images: [UIImage], entryID: String) async throws -> [String] {
        let storageRef = Storage.storage().reference().child("journalEntries/\(entryID)")
        var uploadedURLs: [String] = []

        try await withThrowingTaskGroup(of: String.self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let imageRef = storageRef.child("image_\(index).jpg")
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data."])
                    }

                    // Upload the image
                    _ = try await imageRef.putDataAsync(imageData)
                    
                    // Get the download URL
                    let url = try await imageRef.downloadURL()
                    return url.absoluteString
                }
            }

            for try await url in group {
                uploadedURLs.append(url)
            }
        }

        guard uploadedURLs.count == images.count else {
            throw NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload all images."])
        }

        return uploadedURLs
    }
    
    private func uploadImages(_ images: [UIImage], entryID: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("journalEntries/\(entryID)")
        var uploadedURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            let imageRef = storageRef.child("image_\(index).jpg")
            dispatchGroup.enter()
            
            imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("URL error: \(error.localizedDescription)")
                    } else if let url = url {
                        uploadedURLs.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(uploadedURLs))
        }
    }
    
    private func loadImages() {
        for index in allImages.indices {
            guard allImages[index].loadedImage == nil,
                  let urlString = allImages[index].url,
                  let url = URL(string: urlString) else {
                continue
            }

            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("Failed to load image at index \(index): \(error.localizedDescription)")
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        // Update the image in `allImages`
                        allImages[index].loadedImage = image
                    }
                }
            }.resume()
        }
    }

    private func requestLocationAccess() {
        location = "Waiting for location permission..." // Provide user feedback

        let delegate = LocationManagerDelegate { coordinates in
            DispatchQueue.main.async {
                if let coordinates = coordinates {
                    location = "Lat: \(coordinates.latitude), Lon: \(coordinates.longitude)"
                } else {
                    location = "Unable to fetch location."
                }
            }
        }

        locationManagerDelegate = delegate // Retain the delegate
        locationManager.delegate = delegate

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            fetchLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            location = "Location access denied. Please enable it in Settings."
        case .restricted:
            location = "Location access restricted."
        @unknown default:
            location = "Unknown location status."
        }
    }
    
    private func fetchWeather(latitude: Double, longitude: Double) {
        let apiKey = "0bbeb9bac554470fa76188b2a4601535" // Replace with your OpenWeatherMap API key
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=imperial")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching weather data: \(error)")
                return
            }

            guard let data = data else { return }
            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                DispatchQueue.main.async {
                    self.weatherDescription = "\(String(format: "%.0f°", (weatherData.main.temp)))F"
                    self.weatherIcon = self.mapWeatherIcon(iconCode: weatherData.weather.first?.icon)
                }
            } catch {
                print("Error decoding weather data: \(error)")
            }
        }.resume()
    }
    
    private func mapWeatherIcon(iconCode: String?) -> String {
        switch iconCode {
        case "01d":
                return "sun.max.fill"
            case "01n":
                return "moon.stars.fill"
            case "02d":
                return "cloud.sun.fill"
            case "02n":
                return "cloud.moon.fill"
            case "03d", "03n":
                return "cloud.fill"
            case "04d", "04n":
                return "cloud.fill"
            case "09d", "09n":
                return "cloud.drizzle.fill"
            case "10d":
                return "cloud.sun.rain.fill"
            case "10n":
                return "cloud.moon.rain.fill"
            case "11d", "11n":
                return "cloud.bolt.rain.fill"
            case "13d", "13n":
                return "cloud.snow.fill"
            case "50d":
                return "sun.haze.fill"
            case "50n":
                return "cloud.fog.fill"
            default:
                return "questionmark.circle" // Fallback icon
        }
    }
}

#Preview {
    AddJournalEntryView(
        isNewEntry: true, // Specify that this is a new entry
        onSave: { newEntry in
            print("Saved entry: \(newEntry)")
        },
        onCancel: {
            print("Canceled new entry")
        }
    )
}
