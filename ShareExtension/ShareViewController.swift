import UIKit
import SwiftUI
import UniformTypeIdentifiers
import ClippingsKit

/// Principal class for the share extension. Hosts a SwiftUI sheet inside a custom
/// view controller (System Design §3.1) rather than the default compose view.
///
/// Phase 0 skeleton: it receives the first shared image and presents a placeholder
/// view, proving the extension appears in the Share sheet and gets the image (the
/// Phase 0 exit criterion). The Raw/Split formatting UI, OCR, and export are wired
/// in Phase 2.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        loadFirstImage { [weak self] result in
            DispatchQueue.main.async {
                self?.presentUI(for: result)
            }
        }
    }

    /// Result of pulling the first image out of the extension context.
    private enum LoadResult {
        case image(Data, multiple: Bool)
        case noImage
        case failed
    }

    private func presentUI(for result: LoadResult) {
        let root = PlaceholderView(
            result: result,
            onCancel: { [weak self] in self?.cancel() }
        )
        let hosting = UIHostingController(rootView: root)
        addChild(hosting)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }

    /// Pull the first image attachment from the extension's input items.
    private func loadFirstImage(completion: @escaping (LoadResult) -> Void) {
        let attachments = (extensionContext?.inputItems as? [NSExtensionItem])
            .map { $0.flatMap { $0.attachments ?? [] } } ?? []

        let imageProviders = attachments.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        }

        guard let first = imageProviders.first else {
            completion(.noImage)
            return
        }
        let multiple = imageProviders.count > 1

        first.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            if let data {
                completion(.image(data, multiple: multiple))
            } else {
                completion(.failed)
            }
        }
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "Clippings", code: 0))
    }

    /// Placeholder SwiftUI surface for the Phase 0 skeleton.
    private struct PlaceholderView: View {
        let result: LoadResult
        let onCancel: () -> Void

        var body: some View {
            NavigationStack {
                VStack(spacing: 16) {
                    switch result {
                    case let .image(data, multiple):
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 320)
                        }
                        if multiple {
                            Text("One image is handled at a time.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text("Formatting UI arrives in Phase 2.")
                            .foregroundStyle(.secondary)
                    case .noImage:
                        Text("No image was shared.")
                    case .failed:
                        Text("Couldn't read the shared image.")
                    }
                }
                .padding()
                .navigationTitle("Clippings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                }
            }
        }
    }
}
