//
//  PhotosPickerView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 12/12/24.
//

import SwiftUI
import PhotosUI

struct PhotosPickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // Set to 0 to allow unlimited selection of images
        configuration.filter = .images  // Restrict picker to only show images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotosPickerView

        init(_ parent: PhotosPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        } else if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PhotosPickerPreview()
}

struct PhotosPickerPreview: View {
    @State private var selectedImages: [UIImage] = []

    var body: some View {
        PhotosPickerView(selectedImages: $selectedImages)
    }
}
