import PencilKit
import SwiftUI

struct DrawingView: UIViewRepresentable {
    @Binding var toolPickerShows: Bool
    let canvasView: PKCanvasView
    let toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        canvasView.minimumZoomScale = 1
        canvasView.maximumZoomScale = 3

        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)

        if toolPickerShows {
            canvasView.becomeFirstResponder()
        }

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)

        if toolPickerShows {
            canvasView.becomeFirstResponder()
        } else {
            canvasView.resignFirstResponder()
        }
    }
}

struct PaintView: View {
    let paint: Paint?
    let repository: any PaintRepository

    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var toolPickerShows = true
    @State private var showAlertSave = false
    @State private var name = ""
    @State private var saveError: String?
    @Environment(\.dismiss) private var dismiss

    init(paint: Paint? = nil, repository: any PaintRepository) {
        self.paint = paint
        self.repository = repository
    }

    var body: some View {
        DrawingView(
            toolPickerShows: $toolPickerShows,
            canvasView: canvasView,
            toolPicker: toolPicker
        )
        .navigationTitle(Text("Paint"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        if canvasView.undoManager?.canUndo ?? false {
                            canvasView.undoManager?.undo()
                        }
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                    }
                    Button {
                        if canvasView.undoManager?.canRedo ?? false {
                            canvasView.undoManager?.redo()
                        }
                    } label: {
                        Image(systemName: "arrow.uturn.forward.circle")
                    }
                }
            }
            ToolbarItem {
                HStack(spacing: 10) {
                    Button {
                        toolPickerShows.toggle()
                    } label: {
                        Image(systemName: "paintpalette")
                    }
                    Button("", systemImage: "eraser") {
                        canvasView.drawing.strokes.removeAll()
                    }
                    NavigationLink {
                        PaintAR(canvas: canvasView)
                    } label: {
                        Image(systemName: "arkit")
                    }
                    Button {
                        if paint == nil {
                            showAlertSave = true
                        } else {
                            updatePaint()
                        }
                    } label: {
                        Text(paint == nil ? LocalizedStringKey("save") : LocalizedStringKey("update"))
                    }
                    .alert(LocalizedStringKey("nameDrawing"), isPresented: $showAlertSave) {
                        TextField(LocalizedStringKey("nameDrawing"), text: $name)
                        Button(LocalizedStringKey("cancel")) {
                            name = ""
                        }
                        Button(LocalizedStringKey("save")) {
                            createPaint()
                        }
                    } message: {
                        Text(LocalizedStringKey("saveDrawing"))
                    }
                }
            }
        }
        .alert(
            Text("Error"),
            isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
        .onAppear {
            toolPickerShows = true
            loadCanvas()
        }
    }

    private func loadCanvas() {
        guard
            let paint,
            let drawing = try? PKDrawing(data: paint.drawingData)
        else {
            return
        }

        canvasView.drawing = drawing
    }

    private func createPaint() {
        let drawingData = canvasView.drawing.dataRepresentation()
        let paintName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !paintName.isEmpty else {
            return
        }

        Task {
            do {
                _ = try await repository.create(name: paintName, drawingData: drawingData)
                name = ""
                showAlertSave = false
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }

    private func updatePaint() {
        guard let paint else {
            return
        }

        let drawingData = canvasView.drawing.dataRepresentation()
        Task {
            do {
                try await repository.updateDrawing(id: paint.id, drawingData: drawingData)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}
