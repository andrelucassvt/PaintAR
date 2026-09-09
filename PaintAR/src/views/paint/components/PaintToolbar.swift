import SwiftUI

@MainActor
struct PaintToolbar: View {
    let canvasState: CanvasState
    @Binding var toolPickerShows: Bool
    let isSaving: Bool
    let onClear: () -> Void
    let onViewAR: () -> Void
    let onSave: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var actionID = 0

    // Alvo visual compacto para caber na pílula sem estourar em telas estreitas.
    private let buttonSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 4) {
            toolbarButton("undo", systemImage: "arrow.uturn.backward", isEnabled: canvasState.canUndo) {
                canvasState.undo()
            }

            toolbarButton("redo", systemImage: "arrow.uturn.forward", isEnabled: canvasState.canRedo) {
                canvasState.redo()
            }

            barDivider

            toolbarButton(
                "tools",
                systemImage: toolPickerShows ? "paintpalette.fill" : "paintpalette",
                isEnabled: true,
                isActive: toolPickerShows
            ) {
                toolPickerShows.toggle()
            }

            toolbarButton("clear", systemImage: "trash", isEnabled: !canvasState.isEmpty) {
                onClear()
            }

            barDivider

            toolbarButton("viewInAR", systemImage: "arkit", isEnabled: true) {
                onViewAR()
            }

            saveButton
        }
        .padding(6)
        .background(barBackground)
    }

    // Fundo em cápsula flutuante com fallback opaco para Reduce Transparency.
    private var barBackground: some View {
        Capsule(style: .continuous)
            .fill(reduceTransparency ? AnyShapeStyle(Theme.graphiteElevated) : AnyShapeStyle(.ultraThinMaterial))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    private var barDivider: some View {
        Divider()
            .frame(height: 24)
            .foregroundStyle(Color.white.opacity(0.2))
            .padding(.horizontal, 2)
    }

    private var saveButton: some View {
        Button {
            actionID += 1
            onSave()
        } label: {
            if isSaving {
                ProgressView()
                    .tint(.white)
                    .frame(width: buttonSize, height: buttonSize)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Circle().fill(Theme.accentInk))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.accentInk.opacity(0.4), radius: 8, x: 0, y: 3)
            }
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .opacity(isSaving ? 0.7 : 1)
        .accessibilityLabel(LocalizedStringKey("save"))
        .symbolEffect(.bounce, value: actionID)
    }

    private func toolbarButton(
        _ titleKey: String,
        systemImage: String,
        isEnabled: Bool,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            actionID += 1
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    Circle()
                        .fill(buttonFill(isActive: isActive, isEnabled: isEnabled))
                )
                .foregroundStyle(isEnabled ? Theme.textPrimary : Theme.textSecondary)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .accessibilityLabel(LocalizedStringKey(titleKey))
        .symbolEffect(.bounce, value: actionID)
    }

    private func buttonFill(isActive: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else {
            return .clear
        }

        if isActive {
            return Theme.accentInk.opacity(0.32)
        }

        return Color.white.opacity(0.1)
    }
}
