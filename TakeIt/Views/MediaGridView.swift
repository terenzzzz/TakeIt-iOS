import SwiftUI

struct MediaGridView: View {
    let media: [MediaItem]
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: sizeClass == .compact ? 1 : 2
        )
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(media) { item in
                MediaCardView(item: item)
            }
        }
    }
}
