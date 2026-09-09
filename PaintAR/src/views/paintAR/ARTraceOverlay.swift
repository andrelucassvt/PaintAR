import SwiftUI

@MainActor
struct ARTraceOverlay: View {
    @Binding var opacity: Double
    @Binding var isLocked: Bool
    let onRecenter: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = true
    @State private var isVisible = false

    var body: some View {
        VStack {
            Spacer()

            if isVisible {
                controls
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(20)
        .animation(Motion.respecting(reduceMotion, Motion.sheet), value: isExpanded)
        .task {
            withAnimation(Motion.respecting(reduceMotion, Motion.sheet)) {
                isVisible = true
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Label(LocalizedStringKey("tapToPlace"), systemImage: "hand.tap")
                    .font(.subheadline.weight(.medium))

                Spacer()

                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(
                    LocalizedStringKey(isExpanded ? "hideControls" : "showControls")
                )

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(LocalizedStringKey("close"))
            }

            if isExpanded {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Label(LocalizedStringKey("opacity"), systemImage: "circle.lefthalf.filled")
                            .labelStyle(.iconOnly)
                            .accessibilityHidden(true)

                        Slider(value: $opacity, in: 0.1...1)
                            .accessibilityLabel(LocalizedStringKey("opacity"))

                        Text(opacity, format: .percent.precision(.fractionLength(0)))
                            .font(.caption.monospacedDigit())
                            .frame(minWidth: 38, alignment: .trailing)
                    }

                    HStack(spacing: 10) {
                        Button {
                            isLocked.toggle()
                        } label: {
                            Label(
                                LocalizedStringKey(isLocked ? "unlock" : "lock"),
                                systemImage: isLocked ? "lock.fill" : "lock.open"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: onRecenter) {
                            Label(LocalizedStringKey("recenter"), systemImage: "scope")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Label(LocalizedStringKey("lookingForSurface"), systemImage: "viewfinder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(16)
        .foregroundStyle(.primary)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous))
    }
}
