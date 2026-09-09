import SwiftUI

@MainActor
struct HomeView: View {
    private let repository: any PaintRepository
    private let fileService: PaintFileService
    @State private var viewModel: HomeViewModel

    init(
        repository: any PaintRepository,
        fileService: PaintFileService = .init()
    ) {
        self.repository = repository
        self.fileService = fileService
        _viewModel = State(
            initialValue: HomeViewModel(
                repository: repository,
                fileService: fileService
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ScrollView {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            Spacer(minLength: 60)
                        }
                    }
                case .error(let errorMessage):
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button(LocalizedStringKey("Try Again")) {
                            Task {
                                await viewModel.fetchPaints()
                            }
                        }
                    }
                case .loaded(let paints):
                    if paints.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "paintbrush")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text(LocalizedStringKey("noDrawing"))
                                .font(.headline)
                            NavigationLink {
                                PaintView(repository: repository)
                                    .onDisappear {
                                        Task {
                                            await viewModel.fetchPaints()
                                        }
                                    }
                            } label: {
                                Label(
                                    LocalizedStringKey("addFirst"),
                                    systemImage: "applepencil.and.scribble"
                                )
                                .font(.title3)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                NavigationLink {
                                    PaintView(repository: repository)
                                        .onDisappear {
                                            Task {
                                                await viewModel.fetchPaints()
                                            }
                                        }
                                } label: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.blue)
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .overlay {
                                            Text(LocalizedStringKey("add"))
                                                .foregroundStyle(.white)
                                        }
                                        .padding(.horizontal)
                                }

                                ForEach(paints) { paint in
                                    HomeCardPaint(
                                        paint: paint,
                                        repository: repository,
                                        fileService: fileService,
                                        onDelete: {
                                            await viewModel.deletePaint(paint)
                                        },
                                        onRename: { name in
                                            await viewModel.renamePaint(paint, to: name)
                                        },
                                        onRefresh: {
                                            await viewModel.fetchPaints()
                                        }
                                    )
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .refreshable {
                            await viewModel.fetchPaints()
                        }
                    }
                }
            }
            .navigationTitle("TraceAR")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showImportView.toggle()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showImportView) {
                importSheetView(viewModel: viewModel)
            }
            .alert(item: $viewModel.activeAlert) { alertType in
                switch alertType {
                case .error(let message):
                    Alert(
                        title: Text("Error"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                case .success:
                    Alert(
                        title: Text(LocalizedStringKey("sucess")),
                        message: Text(LocalizedStringKey("drawingAdd")),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .task {
            await viewModel.fetchPaints()
        }
        .ignoresSafeArea(.keyboard)
    }

    private func importSheetView(viewModel: HomeViewModel) -> some View {
        VStack {
            Spacer()
            Text(LocalizedStringKey("importDrawing"))
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .bottom])

            Text(LocalizedStringKey("importDrawingUsers"))
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 30)

            Button {
                viewModel.importActivated.toggle()
            } label: {
                Label(LocalizedStringKey("import"), systemImage: "document")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .fileImporter(
                isPresented: Binding(
                    get: { viewModel.importActivated },
                    set: { viewModel.importActivated = $0 }
                ),
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let file):
                    Task {
                        await viewModel.importPaint(from: file)
                    }
                case .failure(let error):
                    viewModel.handleError(error)
                }
            }
            Spacer()
        }
        .padding()
    }
}
