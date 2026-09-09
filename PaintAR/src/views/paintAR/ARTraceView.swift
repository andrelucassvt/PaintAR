import ARKit
import PencilKit
import SwiftUI

@MainActor
struct ARTraceView: View {
    let drawing: PKDrawing

    @Environment(\.dismiss) private var dismiss
    @State private var opacity = 0.8
    @State private var isLocked = false
    @State private var recenterID = UUID()

    var body: some View {
        if ARWorldTrackingConfiguration.isSupported {
            ZStack {
                ARTraceSceneController(
                    drawing: drawing,
                    opacity: opacity,
                    isLocked: isLocked,
                    recenterID: recenterID
                )
                .ignoresSafeArea()

                ARTraceOverlay(
                    opacity: $opacity,
                    isLocked: $isLocked,
                    onRecenter: {
                        recenterID = UUID()
                    },
                    onClose: {
                        dismiss()
                    }
                )
            }
            .statusBarHidden()
        } else {
            ContentUnavailableView {
                Label(LocalizedStringKey("arUnavailable"), systemImage: "arkit")
            } actions: {
                Button(LocalizedStringKey("close")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
