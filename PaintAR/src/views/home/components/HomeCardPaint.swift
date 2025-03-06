//
//  HomeCardPaint.swift
//  PaintAR
//
//  Created by André  Lucas on 27/02/25.
//

import SwiftUI
import PencilKit
import CoreData

struct DrawingViewContainer: UIViewRepresentable {
    var drawingData: Data
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.isUserInteractionEnabled = false
        if let drawing = try? PKDrawing(data: drawingData) {
            canvasView.drawing = drawing
        }
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}



struct HomeCardPaint: View {
    
    let paintEntity: PaintEntity
    let onDelete: () -> Void
    let onRefresh: () -> Void
    
    @State var showAlertDelete = false
    @State var isEditing = false
    @State var showRename = false
    @State var name = ""
    @State var navigatorAr = false
    let canvasView = PKCanvasView()
    
    private let coreDataController = CoreDataController()
    let shareController = ShareFileController()
    
    @State var urlShare = URL(fileURLWithPath: "")
    
    
    private func canvasInit() -> Void {
        if let paintData = paintEntity.drawing {
            if let drawing = try? PKDrawing(data: paintData) {
                canvasView.drawing = drawing
            }
        }
    }
    
    func urlShareInit() -> Void {
        if let fileURL = shareController.exportPaintEntityAsJson(paintEntity: paintEntity) {
            urlShare = fileURL
        }
    }
    

    
    
    var body: some View {
        NavigationLink(
            destination: PaintAR(canvas: canvasView),
            isActive: $navigatorAr){
            VStack{
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(height: 300)
                    .shadow(radius: 5)
                    .overlay(
                        DrawingViewContainer(drawingData: paintEntity.drawing!)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    )
                    .overlay{
                        VStack{
                            HStack{
                                Spacer()
                                Menu {
                                    ShareLink(item: urlShare, preview: SharePreview(paintEntity.name!, image: urlShare)) {
                                        Label(LocalizedStringKey("export"), systemImage: "square.and.arrow.up")
                                    }
                                    Button{
                                        isEditing.toggle()
                                    } label: {
                                        Text(LocalizedStringKey("edit"))
                                    }
                                    Button{
                                        showRename.toggle()
                                    } label: {
                                        Text(LocalizedStringKey("rename"))
                                    }
                                    Button(role: .destructive, action: {
                                        showAlertDelete = true
                                    }) {
                                        Text(LocalizedStringKey("delete"))
                                    }
                                    
                                } label: {
                                    Circle()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.blue)
                                        .overlay{
                                            Image(systemName: "ellipsis")
                                                .foregroundColor(.white)
                                        }
                                }
              
                                .navigationDestination(isPresented: $isEditing){
                                     PaintView(
                                        paintEntity: paintEntity
                                     )
                                     .onDisappear{
                                         onRefresh()
                                     }
                                }
                                .alert(LocalizedStringKey("deleteDrawing"), isPresented: $showAlertDelete) {
                                    Button(LocalizedStringKey("delete"), role: .destructive) {
                                        onDelete()
                                    }
                                    Button(LocalizedStringKey("cancel"), role: .cancel) { }
                                }
                                .alert(LocalizedStringKey("rename") ,isPresented: $showRename){
                                    VStack{
                                        TextField(LocalizedStringKey("nameDrawing"), text: $name)
                                  
                                        Button(LocalizedStringKey("cancel"), action: {
                                            name = ""
                                        })
                                        
                                        
                                        Button(LocalizedStringKey("save"), action: {
                                            coreDataController.updatePaint(
                                                paint: paintEntity,
                                                id: paintEntity.id!,
                                                name: name,
                                                date: Date(),
                                                drawing: paintEntity.drawing!
                                            )
                                            name = ""
                                        })
                                        
                                    }
                     
                                }
                                
                            }
                            .padding()
                            Spacer()
                        }
                    }
                    .onTapGesture {
                        isEditing.toggle()                        
                    }
                    .padding()
                HStack{
                    Text(paintEntity.name!)
                        .foregroundStyle(.black)
                    Spacer()
                    Text(paintEntity.date!.formatted())
                        .foregroundStyle(.black)
                }
                .padding(.horizontal)
            }
            .onAppear{
                canvasInit()
                urlShareInit()
            }
            .padding(.top)
        }
        
    }
}
    #Preview {
        NavigationStack{
            HomeCardPaint(
                paintEntity: PaintEntity(context: CoreDataController.shared.context,name: "Andre Lucas", date: Date(), drawing: Data()),
                onDelete: {
                    
                },
                onRefresh: {
                    
                }
            )
        }
    }
