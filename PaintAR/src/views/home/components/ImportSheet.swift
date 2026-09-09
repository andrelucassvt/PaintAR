import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ImportSheet: View {
    let onImport: (URL) async -> Void
    let onFailure: (Error) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var importActivated = false

    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("importDrawing"))
                .font(.title2.weight(.bold))

            Text(LocalizedStringKey("importDrawingUsers"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                importActivated = true
            } label: {
                Label(LocalizedStringKey("import"), systemImage: "document")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentInk)
            .fileImporter(
                isPresented: $importActivated,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let file):
                    Task {
                        await onImport(file)
                        dismiss()
                    }
                case .failure(let error):
                    onFailure(error)
                }
            }
        }
        .padding(24)
        .presentationDetents([.height(280)])
        .presentationCornerRadius(Theme.Radius.sheet)
    }
}
