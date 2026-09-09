import Observation
import PencilKit
import SwiftUI
import UIKit

@MainActor
@Observable
final class CanvasState {
    private weak var canvasView: PKCanvasView?

    private(set) var canUndo = false
    private(set) var canRedo = false
    private(set) var isEmpty = true

    var drawingData: Data {
        canvasView?.drawing.dataRepresentation() ?? Data()
    }

    var drawing: PKDrawing {
        canvasView?.drawing ?? PKDrawing()
    }

    var canvas: PKCanvasView {
        canvasView ?? PKCanvasView()
    }

    func undo() {
        canvasView?.undoManager?.undo()
        refresh()
    }

    func redo() {
        canvasView?.undoManager?.redo()
        refresh()
    }

    func clear() {
        canvasView?.drawing = PKDrawing()
        refresh()
    }

    func attach(to canvasView: PKCanvasView) {
        self.canvasView = canvasView
        refresh()
    }

    func refresh() {
        guard let canvasView else {
            canUndo = false
            canRedo = false
            isEmpty = true
            return
        }

        canUndo = canvasView.undoManager?.canUndo ?? false
        canRedo = canvasView.undoManager?.canRedo ?? false
        isEmpty = canvasView.drawing.strokes.isEmpty
    }
}

@MainActor
struct DrawingCanvasView: UIViewRepresentable {
    let paint: Paint?
    let canvasState: CanvasState
    @Binding var toolPickerShows: Bool
    let onChange: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasState: canvasState, onChange: onChange)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = UIColor(Theme.paper)
        canvasView.isOpaque = true
        canvasView.minimumZoomScale = 1
        canvasView.maximumZoomScale = 3

        if let paint,
           let drawing = try? PKDrawing(data: paint.drawingData) {
            canvasView.drawing = drawing
        }

        canvasState.attach(to: canvasView)
        canvasView.delegate = context.coordinator
        context.coordinator.setToolPickerVisibility(toolPickerShows, for: canvasView)

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.setToolPickerVisibility(toolPickerShows, for: canvasView)
        canvasState.refresh()
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private let canvasState: CanvasState
        private let onChange: () -> Void
        private let toolPicker = PKToolPicker()
        private weak var observedCanvasView: PKCanvasView?

        init(canvasState: CanvasState, onChange: @escaping () -> Void) {
            self.canvasState = canvasState
            self.onChange = onChange
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            canvasState.refresh()
            onChange()
        }

        func setToolPickerVisibility(_ isVisible: Bool, for canvasView: PKCanvasView) {
            if observedCanvasView !== canvasView {
                toolPicker.addObserver(canvasView)
                observedCanvasView = canvasView
            }
            toolPicker.setVisible(isVisible, forFirstResponder: canvasView)

            if isVisible {
                canvasView.becomeFirstResponder()
            } else {
                canvasView.resignFirstResponder()
            }
        }
    }
}
