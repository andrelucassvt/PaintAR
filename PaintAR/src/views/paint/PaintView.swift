//
//  PaintView.swift
//  PaintAR
//
//  Created by André  Lucas on 27/02/25.
//

import SwiftUI
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var toolPickerShows: Bool
    
    public let canvasView: PKCanvasView
    public let toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Allow finger drawing
        canvasView.drawingPolicy = .anyInput
        
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        

        if toolPickerShows {
            canvasView.becomeFirstResponder()
        }
        

        canvasView.minimumZoomScale = 1
        canvasView.maximumZoomScale = 3.0
     
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        if toolPickerShows {
            canvasView.becomeFirstResponder()
        } else {
            canvasView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: DrawingView
        
        init(_ parent: DrawingView) {
            self.parent = parent
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let canvasView = gesture.view as? PKCanvasView else { return }
            
            if gesture.state == .began || gesture.state == .changed {
                let scale = gesture.scale
                let currentScale = canvasView.zoomScale
                let newScale = max(canvasView.minimumZoomScale, min(canvasView.maximumZoomScale, currentScale * scale))
                
                canvasView.zoomScale = newScale
                gesture.scale = 1.0
                
                if newScale < currentScale {
                    expandCanvas(canvasView)
                }
            }
        }
        
        private func expandCanvas(_ canvasView: PKCanvasView) {
            let currentSize = canvasView.contentSize
            let newSize = CGSize(width: currentSize.width * 1.2, height: currentSize.height * 1.2)
            
            canvasView.contentSize = newSize
        }
    }

}
struct PaintView: View {
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var toolPickerShows = true
    @State var showAlertSave = false
    @State var name = ""
    @Environment(\.dismiss) var dismiss
    private let coreDataController = CoreDataController()
    var paintEntity: PaintEntity?
    
    private func canvasInit() -> Void {
        if paintEntity != nil {
            if let paintData = paintEntity!.drawing {
                if let drawing = try? PKDrawing(data: paintData) {
                    canvasView.drawing = drawing
                }
            }

        }
    }
    
    var body: some View {
        DrawingView(toolPickerShows: $toolPickerShows, canvasView: canvasView, toolPicker: toolPicker)
            .navigationTitle(Text("Paint"))
            .toolbar{
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
                    if paintEntity != nil {
                        coreDataController.updatePaint(
                            paint: paintEntity!,
                            id: paintEntity!.id!,
                            name: paintEntity!.name!,
                            date: Date(),
                            drawing: canvasView.drawing.dataRepresentation()
                        )
                        dismiss()
                    } else {
                        showAlertSave.toggle()
                    }
                } label: {
                    Text(paintEntity != nil ? LocalizedStringKey("update")  :  LocalizedStringKey("save"))
                }
                .alert(LocalizedStringKey("nameDrawing"), isPresented: $showAlertSave) {
                    VStack{
                        TextField(LocalizedStringKey("nameDrawing"), text: $name)
                        
                        HStack{
                            Button(LocalizedStringKey("cancel"), action: {
                                self.showAlertSave.toggle()
                                name = ""
                            })
                            Button(LocalizedStringKey("save"), action: {
                                coreDataController.savePaint(
                                    name: name,
                                    date: Date(),
                                    drawing: canvasView.drawing.dataRepresentation()
                                )
                                showAlertSave.toggle()
                                canvasView.drawing.strokes.removeAll()
                                dismiss()
                               
                            })
                        }

                    }
     
                } message: {
                    Text(LocalizedStringKey("saveDrawing"))
                }

            }
            .onAppear{
                toolPickerShows = true
                canvasInit()
            }
    }
    
}

#Preview {
    NavigationView{
        PaintView()
    }
}
