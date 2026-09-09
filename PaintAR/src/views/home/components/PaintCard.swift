import SwiftUI
import UIKit

@MainActor
struct PaintCard: View {
    let paint: Paint
    let fileService: PaintFileService
    let thumbnailStore: DrawingThumbnailStore
    let namespace: Namespace.ID
    let onDelete: () async -> Void
    let onRename: (String) async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var thumbnail: UIImage?
    @State private var shareURL: URL?
    @State private var showDeleteAlert = false
    @State private var showRenameAlert = false
    @State private var newName = ""

    var body: some View {
        transitionSource
            .contextMenu {
                Button {} label: {
                    Label(LocalizedStringKey("viewInAR"), systemImage: "arkit")
                }

                NavigationLink(value: paint) {
                    Label(LocalizedStringKey("edit"), systemImage: "pencil")
                }

                Button {
                    newName = paint.name
                    showRenameAlert = true
                } label: {
                    Label(LocalizedStringKey("rename"), systemImage: "text.cursor")
                }

                exportAction

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label(LocalizedStringKey("delete"), systemImage: "trash")
                }
            }
            .task(id: paint.id) {
                thumbnail = await thumbnailStore.thumbnail(
                    for: paint,
                    size: CGSize(width: 320, height: 220)
                )
                shareURL = try? fileService.export(paint)
            }
            .alert(
                LocalizedStringKey("deleteDrawing"),
                isPresented: $showDeleteAlert
            ) {
                Button(LocalizedStringKey("delete"), role: .destructive) {
                    Task {
                        await onDelete()
                    }
                }
                Button(LocalizedStringKey("cancel"), role: .cancel) {}
            }
            .alert(LocalizedStringKey("rename"), isPresented: $showRenameAlert) {
                TextField(LocalizedStringKey("nameDrawing"), text: $newName)
                Button(LocalizedStringKey("cancel"), role: .cancel) {
                    newName = ""
                }
                Button(LocalizedStringKey("save")) {
                    let name = newName
                    newName = ""

                    Task {
                        await onRename(name)
                        thumbnailStore.invalidate(id: paint.id)
                    }
                }
            }
    }

    @ViewBuilder
    private var transitionSource: some View {
        if reduceMotion {
            cardContent
        } else {
            cardContent
                .matchedTransitionSource(id: paint.id, in: namespace)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Color.white.opacity(0.55))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(18)
                } else {
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Theme.graphite.opacity(0.36))
                }
            }
            .frame(height: 146)

            VStack(alignment: .leading, spacing: 5) {
                Text(paint.name)
                    .font(.headline)
                    .foregroundStyle(Theme.graphite)
                    .lineLimit(1)

                Text(paint.date, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(Theme.graphite.opacity(0.62))
            }
            .padding(14)
        }
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(
            color: .black.opacity(Theme.CardShadow.paper.opacity),
            radius: Theme.CardShadow.paper.radius,
            x: Theme.CardShadow.paper.offset.width,
            y: Theme.CardShadow.paper.offset.height
        )
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
            Button {} label: {
                Label(LocalizedStringKey("export"), systemImage: "square.and.arrow.up")
            }
            .disabled(true)
        }
    }
}
