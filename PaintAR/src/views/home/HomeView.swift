import SwiftUI

@MainActor
struct HomeView: View {
    private let repository: any PaintRepository
    private let fileService: PaintFileService

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var paintNamespace
    @State private var viewModel: HomeViewModel
    @State private var thumbnailStore = DrawingThumbnailStore()
    @State private var showImportSheet = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

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
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()

                content
            }
            .navigationTitle(Text(LocalizedStringKey("TraceAR")))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Paint.self) { paint in
                paintDestination(for: paint)
            }
            .searchable(text: $viewModel.searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .symbolEffect(.bounce, value: showImportSheet)
                    }
                    .accessibilityLabel(LocalizedStringKey("import"))
                }
            }
            .safeAreaInset(edge: .bottom) {
                NavigationLink {
                    PaintView(repository: repository)
                        .onDisappear {
                            Task {
                                await viewModel.load()
                            }
                        }
                } label: {
                    Label(LocalizedStringKey("draw"), systemImage: "applepencil.and.scribble")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentInk)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showImportSheet) {
                ImportSheet(
                    onImport: { url in
                        await viewModel.importFile(at: url)
                    },
                    onFailure: { error in
                        viewModel.handleError(error)
                    }
                )
            }
            .alert(item: $viewModel.activeAlert) { alert in
                switch alert {
                case .error(let message):
                    Alert(
                        title: Text(message),
                        dismissButton: .default(Text(LocalizedStringKey("OK")))
                    )
                case .success:
                    Alert(
                        title: Text(LocalizedStringKey("sucess")),
                        message: Text(LocalizedStringKey("drawingAdd")),
                        dismissButton: .default(Text(LocalizedStringKey("OK")))
                    )
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accentInk)
        case .error(let message):
            ContentUnavailableView {
                Label {
                    Text(message)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            } actions: {
                Button(LocalizedStringKey("retry")) {
                    Task {
                        await viewModel.load()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentInk)
            }
            .foregroundStyle(Theme.textPrimary)
        case .loaded:
            if !viewModel.hasPaints {
                emptyPaintsView
            } else if viewModel.visiblePaints.isEmpty {
                ContentUnavailableView.search
                    .foregroundStyle(Theme.textPrimary)
            } else {
                gallery
            }
        }
    }

    private var emptyPaintsView: some View {
        ContentUnavailableView {
            Label(LocalizedStringKey("noDrawing"), systemImage: "paintbrush")
        } description: {
            Text(LocalizedStringKey("addFirst"))
        } actions: {
            NavigationLink {
                PaintView(repository: repository)
                    .onDisappear {
                        Task {
                            await viewModel.load()
                        }
                    }
            } label: {
                Label(LocalizedStringKey("draw"), systemImage: "applepencil.and.scribble")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentInk)
        }
        .foregroundStyle(Theme.textPrimary)
    }

    private var gallery: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text(LocalizedStringKey("TraceAR"))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Text(viewModel.visiblePaints.count, format: .number)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }

                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(viewModel.visiblePaints) { paint in
                        paintLink(for: paint)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .animation(
                Motion.respecting(reduceMotion, Motion.listChange),
                value: viewModel.visiblePaints
            )
        }
        .refreshable {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func paintLink(for paint: Paint) -> some View {
        let link = NavigationLink(value: paint) {
            PaintCard(
                paint: paint,
                fileService: fileService,
                thumbnailStore: thumbnailStore,
                namespace: paintNamespace,
                onDelete: {
                    await viewModel.delete(paint)
                },
                onRename: { name in
                    await viewModel.rename(paint, to: name)
                }
            )
        }
        .buttonStyle(.plain)

        if reduceMotion {
            link
        } else {
            link.scrollTransition(.animated, axis: .vertical) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0)
                    .scaleEffect(phase.isIdentity ? 1 : 0.94)
            }
        }
    }

    @ViewBuilder
    private func paintDestination(for paint: Paint) -> some View {
        let editor = PaintView(paint: paint, repository: repository)
            .onDisappear {
                Task {
                    thumbnailStore.invalidate(id: paint.id)
                    await viewModel.load()
                }
            }

        if reduceMotion {
            editor
        } else {
            editor.navigationTransition(.zoom(sourceID: paint.id, in: paintNamespace))
        }
    }
}
