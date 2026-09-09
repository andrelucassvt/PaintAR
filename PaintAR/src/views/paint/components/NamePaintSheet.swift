import SwiftUI

@MainActor
struct NamePaintSheet: View {
    @Binding var name: String
    let isSaving: Bool
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFieldFocused: Bool

    private var trimmedNameIsValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("saveDrawing"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField(LocalizedStringKey("nameDrawing"), text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(Text(LocalizedStringKey("nameDrawing")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("save"), action: save)
                        .disabled(!trimmedNameIsValid || isSaving)
                }
            }
        }
        .presentationDetents([.height(220)])
        .task {
            isNameFieldFocused = true
        }
    }

    private func save() {
        guard trimmedNameIsValid, !isSaving else {
            return
        }

        onSave(name)
    }
}
