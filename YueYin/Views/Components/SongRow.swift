import SwiftUI
import YueYinCore

struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: song.coverUrl)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.body)
                    .lineLimit(1)
                Text(song.artist.isEmpty ? "B站" : song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if song.durationMs > 0 {
                Text(DurationFormat.format(seconds: song.durationMs / 1000))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
