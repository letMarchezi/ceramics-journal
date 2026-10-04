import SwiftUI
import PhotosUI

/// A tappable photo field: shows the current image (if any) and offers
/// "Take photo" (camera) and "Choose from Photos" (photo library).
///
/// Supports the two capture options from section 41.
struct PhotoSlot: View {
    let title: String
    @Binding var imagePath: String?

    @State private var pickedItem: PhotosPickerItem?
    @State private var showCamera = false

    private let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)

            HStack(spacing: 14) {
                thumbnail
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    if cameraAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take photo", systemImage: "camera")
                        }
                        .buttonStyle(CuteSecondaryButton(font: .caption.weight(.medium), compact: true))
                    }

                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(CuteSecondaryButton(font: .caption.weight(.medium), compact: true))

                    if imagePath != nil {
                        Button(role: .destructive) {
                            ImageStore.shared.delete(imagePath)
                            imagePath = nil
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                        .font(.caption)
                        .tint(Theme.burgundy)
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { image in
                imagePath = ImageStore.shared.save(image)
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    imagePath = ImageStore.shared.save(image)
                }
                pickedItem = nil
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let imagePath, let image = ImageStore.shared.load(imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.mustard.opacity(0.15))
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)
                        .foregroundStyle(Theme.mustardDark.opacity(0.6))
                }
            }
        }
        .frame(width: 104, height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Camera

/// Wraps `UIImagePickerController` in a camera-only sheet.
struct CameraCaptureView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureDevice = .rear
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView

        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
