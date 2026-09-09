import SwiftUI

/// Botão de ação flutuante para criar um desenho novo.
///
/// Recebe o repositório e um callback de fechamento; nunca o ViewModel pai.
struct NewDrawingFab: View {
    let repository: any PaintRepository
    let onClosed: () -> Void

    var body: some View {
        NavigationLink {
            PaintView(repository: repository)
                .onDisappear {
                    onClosed()
                }
        } label: {
            Label {
                Text(LocalizedStringKey("draw"))
            } icon: {
                Image(systemName: "applepencil.and.scribble")
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 60, height: 60)
            .modifier(FabBackground())
        }
        .accessibilityLabel(LocalizedStringKey("draw"))
    }
}

private struct FabBackground: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if #available(iOS 26, *), !reduceTransparency {
            content.glassEffect(.regular.tint(Theme.accentInk).interactive(), in: Circle())
        } else {
            content
                .background(Theme.accentInk, in: Circle())
                .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 6)
        }
    }
}
