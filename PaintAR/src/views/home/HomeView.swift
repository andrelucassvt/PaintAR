//
//  HomeView.swift
//  PaintAR
//
//  Created by André  Lucas on 27/02/25.
//

import SwiftUI

struct HomeView: View {
    
    @ObservedObject var viewModel: HomeViewModel = .init()

    var body: some View {
        NavigationStack{
            Group {
                switch viewModel.state {
                case .loading:
                    ScrollView(){
                        VStack{
                            ProgressView()
                                .scaleEffect(1)
                                .font(.title)
                        }
            
                    }
                case .error(let error):
                    Text("Error: \(error)")
                case .loaded(let paints):
                    if paints.isEmpty {
                        NavigationLink  {
                            PaintView()
                                .onDisappear{
                                    viewModel.fetchPaints()
                                }
                        } label: {
                            Label(LocalizedStringKey("addFirst"), systemImage: "applepencil.and.scribble")
                        }
                        
                    } else {
                        ScrollView(showsIndicators: false){
                            VStack{
                                ForEach(paints, id: \.id) { paint in
                                    HomeCardPaint(
                                        paintEntity: paint,
                                        onDelete: {
                                            withAnimation {
                                                viewModel.deletePaint(paint)
                                            }
                                        },
                                        onRefresh: {
                                            viewModel.fetchPaints()
                                        }
                                    )
                                }
                            }
                        }
                        .refreshable {
                            viewModel.fetchPaints()
                        }
                    }
                }
            }
            .navigationTitle("PaintAR")
            .toolbar {
                NavigationLink{
                    PaintView()
                        .onDisappear{
                            viewModel.fetchPaints()
                        }
                } label: {
                    Text(LocalizedStringKey("add"))
                }
                
                Button{
                    viewModel.showImportView.toggle()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .sheet(isPresented: $viewModel.showImportView){
                    VStack{
                        Text(LocalizedStringKey("importDrawing"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                        
                        Text(LocalizedStringKey("importDrawingUsers"))
                            .font(.title3)
                        
                        
                        Button {
                            viewModel.importActivated.toggle()
                        } label: {
                            Label(LocalizedStringKey("import"), systemImage: "document")
                                .padding(.top)
                        }
                        .fileImporter(isPresented: $viewModel.importActivated , allowedContentTypes: [.json]) { result in
                            switch result {
                                case .success(let file):
                                    viewModel.addImportFile(path: file.absoluteString)
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }
                        }
                       
                        

                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    HomeView()
}
