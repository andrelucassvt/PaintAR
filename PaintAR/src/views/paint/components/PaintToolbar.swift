import SwiftUI

@MainActor
struct PaintToolbar: View {
    let canvasState: CanvasState
    @Binding var toolPickerShows: Bool
    let isSaving: Bool
    let onClear: () -> Void
    let onViewAR: () -> Void
    let onSave: () -> Void

    @State private var actionID = 0

    var body: some View {
        HStack(spacing: 4) {
            editorButton("undo", systemImage: "arrow.uturn.backward") {
                canvasState.undo()
            }
            .disabled(!canvasState.canUndo)

            editorButton("redo", systemImage: "arrow.uturn.forward") {
                canvasState.redo()
            }
            .disabled(!canvasState.canRedo)

            Divider()
                .frame(height: 28)
                .padding(.horizontal, 4)

            editorButton("tools", systemImage: "paintpalette") {
                toolPickerShows.toggle()
            }

            editorButton("clear", systemImage: "trash") {
                onClear()
            }
            .disabled(canvasState.isEmpty)

            Spacer(minLength: 4)

            editorButton("viewInAR", systemImage: "arkit") {
                onViewAR()
            }

            Button {
                actionID += 1
                onSave()
            } label: {
                Label(LocalizedStringKey("save"), systemImage: "checkmark")
                    .font(.headline)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentInk)
            .disabled(isSaving)
            .accessibilityLabel(LocalizedStringKey("save"))
            .symbolEffect(.bounce, value: actionID)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .foregroundStyle(Theme.textPrimary)
        .background(.ultraThinMaterial)
    }

    private func editorButton(
        _ titleKey: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            actionID += 1
            action()
        } label: {
            Label(LocalizedStringKey(titleKey), systemImage: systemImage)
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.bordered)
        .tint(Theme.textPrimary)
        .accessibilityLabel(LocalizedStringKey(titleKey))
        .symbolEffect(.bounce, value: actionID)
    }
}
