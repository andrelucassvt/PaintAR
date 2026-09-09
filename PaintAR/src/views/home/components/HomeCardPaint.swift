import PencilKit
import SwiftUI

struct DrawingViewContainer: UIViewRepresentable {
    let drawingData: Data

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
    let paint: Paint
    let repository: any PaintRepository
    let fileService: PaintFileService
    let onDelete: () async -> Void
    let onRename: (String) async -> Void
    let onRefresh: () async -> Void

    @State private var showAlertDelete = false
    @State private var isEditing = false
    @State private var showRename = false
    @State private var name = ""
    @State private var shareURL: URL?

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(height: 300)
                .shadow(radius: 5)
                .overlay {
                    DrawingViewContainer(drawingData: paint.drawingData)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .overlay {
                    VStack {
                        HStack {
                            Spacer()
                            Menu {
                                exportAction
                                Button {
                                    isEditing = true
                                } label: {
                                    Text(LocalizedStringKey("edit"))
                                }
                                Button {
                                    name = paint.name
                                    showRename = true
                                } label: {
                                    Text(LocalizedStringKey("rename"))
                                }
                                Button(role: .destructive) {
                                    showAlertDelete = true
                                } label: {
                                    Text(LocalizedStringKey("delete"))
                                }
                            } label: {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)
                                    .overlay {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.white)
                                    }
                            }
                        }
                        .padding()
                        Spacer()
                    }
                }
                .onTapGesture {
                    isEditing = true
                }
                .alert(
                    LocalizedStringKey("deleteDrawing"),
                    isPresented: $showAlertDelete
                ) {
                    Button(LocalizedStringKey("delete"), role: .destructive) {
                        Task {
                            await onDelete()
                        }
                    }
                    Button(LocalizedStringKey("cancel"), role: .cancel) {}
                }
                .alert(LocalizedStringKey("rename"), isPresented: $showRename) {
                    TextField(LocalizedStringKey("nameDrawing"), text: $name)
                    Button(LocalizedStringKey("cancel")) {
                        name = ""
                    }
                    Button(LocalizedStringKey("save")) {
                        let updatedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !updatedName.isEmpty else {
                            return
                        }

                        name = ""
                        Task {
                            await onRename(updatedName)
                        }
                    }
                }
                .padding([.bottom, .leading, .trailing])

            HStack {
                Text(paint.name)
                    .foregroundStyle(.black)
                Spacer()
                Text(paint.date.formatted())
                    .foregroundStyle(.black)
            }
            .padding(.horizontal)
        }
        .navigationDestination(isPresented: $isEditing) {
            PaintView(paint: paint, repository: repository)
                .onDisappear {
                    Task {
                        await onRefresh()
                    }
                }
        }
        .onAppear {
            shareURL = try? fileService.export(paint)
        }
        .padding(.top)
    }

    @ViewBuilder
    private var exportAction: some View {
        if let shareURL {
            ShareLink(
                item: shareURL,
                preview: SharePreview(paint.name, image: shareURL)
            ) {
                Label(LocalizedStringKey("export"), systemImage: "square.and.arrow.up")
            }
        } else {
            Button {
                shareURL = try? fileService.export(paint)
            } label: {
                Label(LocalizedStringKey("export"), systemImage: "square.and.arrow.up")
            }
        }
    }
}
