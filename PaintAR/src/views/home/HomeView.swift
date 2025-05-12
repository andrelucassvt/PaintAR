import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel = .init()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
                            Text("Error: \(errorMessage)")
                                .multilineTextAlignment(.center)
                                .padding()
                            Button("Try Again") {
                                viewModel.fetchPaints()
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
                                    PaintView()
                                        .onDisappear {
                                            viewModel.fetchPaints()
                                        }
                                } label: {
                                    Label(LocalizedStringKey("addFirst"), systemImage: "applepencil.and.scribble")
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
                                      PaintView()
                                          .onDisappear {
                                              viewModel.fetchPaints()
                                          }
                                      } label: {
                                          RoundedRectangle(cornerRadius: 10)
                                              .fill(.blue)
                                              .frame(width: .infinity, height: 50)
                                              .overlay {
                                                  Text(LocalizedStringKey("add"))
                                                      .foregroundStyle(.white)
                                              }
                                              .padding(.horizontal)
                                      }

                       
                                    ForEach(paints.indices, id: \.self) { index in
                                        if index == 1 {
                                            BannerAdView(adUnitID: "ca-app-pub-3652623512305285/5727975953")
                                                .frame(width: 320, height: 50)
                                                .padding(.bottom, 5)
                                        }
                                        
                                        if index == 2 {
                                            BannerAdView(adUnitID: "ca-app-pub-3652623512305285/1088817392")
                                                .frame(width: 320, height: 50)
                                                .padding(.bottom, 5)
                                        }

                                        
                                        NavigationLink {
                                            PaintView()
                                                .onDisappear {
                                                    viewModel.fetchPaints()
                                                }
                                        } label: {
                                            HomeCardPaint(
                                                paintEntity: paints[index],
                                                onDelete: {
                                                    withAnimation(.easeInOut) {
                                                        viewModel.deletePaint(paints[index])
                                                    }
                                                },
                                                onRefresh: {
                                                    viewModel.fetchPaints()
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding(.bottom, 80) // espaço para o banner
                            }
                            .refreshable {
                                withAnimation {
                                    viewModel.fetchPaints()
                                }
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
                    importSheetView
                }
                .alert(item: $viewModel.activeAlert) { alertType in
                    switch alertType {
                    case .error(_):
                        return Alert(
                            title: Text("Error"),
                            message: Text(LocalizedStringKey("invalidJson")),
                            dismissButton: .default(Text("OK"))
                        )
                    case .success:
                        return Alert(
                            title: Text(LocalizedStringKey("sucess")),
                            message: Text(LocalizedStringKey("drawingAdd")),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }
            .navigationViewStyle(.stack)
        }
        .ignoresSafeArea(.keyboard) // evita conflito com o teclado
    }
    
    private var importSheetView: some View {
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
                isPresented: $viewModel.importActivated,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let file):
                    viewModel.addImportFile(path: file.absoluteString)
                case .failure(let error):
                    print("File import error: \(error.localizedDescription)")
                    viewModel.handleError("Failed to import file: \(error.localizedDescription)")
                }
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    HomeView(viewModel: HomeViewModel())
}
