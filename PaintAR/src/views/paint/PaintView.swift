import SwiftUI

@MainActor
struct PaintView: View {
    let paint: Paint?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PaintViewModel
    @State private var canvasState = CanvasState()
    @State private var toolPickerShows = true
    @State private var name = ""
    @State private var showNameSheet = false
    @State private var showClearConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var showAR = false

    init(paint: Paint? = nil, repository: any PaintRepository) {
        self.paint = paint

        let mode: PaintViewModel.Mode = if let paint {
            .editing(paint)
        } else {
            .new
        }
        _viewModel = State(initialValue: PaintViewModel(mode: mode, repository: repository))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            DrawingCanvasView(
                paint: paint,
                canvasState: canvasState,
                toolPickerShows: $toolPickerShows,
                onChange: viewModel.markDirty
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .shadow(
                color: .black.opacity(Theme.CardShadow.paper.opacity),
                radius: Theme.CardShadow.paper.radius,
                x: Theme.CardShadow.paper.offset.width,
                y: Theme.CardShadow.paper.offset.height
            )
            .padding(20)
        }
        .navigationTitle(Text(LocalizedStringKey("draw")))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Theme.graphite, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    requestDismissal()
                } label: {
                    Label(LocalizedStringKey("back"), systemImage: "chevron.backward")
                }
                .tint(Theme.textPrimary)
            }
        }
        // Pílula centralizada no topo para não ficar sob o PKToolPicker flutuante da base.
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer(minLength: 0)
                PaintToolbar(
                    canvasState: canvasState,
                    toolPickerShows: $toolPickerShows,
                    isSaving: viewModel.isSaving,
                    onClear: {
                        showClearConfirmation = true
                    },
                    onViewAR: {
                        showAR = true
                    },
                    onSave: save
                )
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(.clear)
        }
        .sheet(isPresented: $showNameSheet) {
            NamePaintSheet(
                name: $name,
                isSaving: viewModel.isSaving,
                onSave: saveNewPaint(named:)
            )
        }
        .confirmationDialog(
            LocalizedStringKey("clearDrawing"),
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(LocalizedStringKey("clear"), role: .destructive) {
                canvasState.clear()
                viewModel.markDirty()
            }
            Button(LocalizedStringKey("cancel"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("clearDrawingMessage"))
        }
        .confirmationDialog(
            LocalizedStringKey("discardChanges"),
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button(LocalizedStringKey("discard"), role: .destructive) {
                dismiss()
            }
            Button(LocalizedStringKey("continueEditing"), role: .cancel) {}
        }
        .alert(
            LocalizedStringKey("errorSaving"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(LocalizedStringKey("ok"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey(viewModel.errorMessage ?? "errorSaving"))
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        .navigationDestination(isPresented: $showAR) {
            ARTraceView(drawing: canvasState.drawing)
        }
    }

    private func save() {
        if paint == nil {
            showNameSheet = true
        } else {
            saveExistingPaint()
        }
    }

    private func saveNewPaint(named name: String) {
        Task {
            guard await viewModel.save(drawingData: canvasState.drawingData, name: name) != nil else {
                return
            }

            self.name = ""
            showNameSheet = false
            dismiss()
        }
    }

    private func saveExistingPaint() {
        Task {
            guard await viewModel.save(drawingData: canvasState.drawingData, name: "") != nil else {
                return
            }

            dismiss()
        }
    }

    private func requestDismissal() {
        if viewModel.hasUnsavedChanges {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }
}
