import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject private var player = PlayerCore.shared

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: player.currentSong?.coverUrl)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentSong?.name ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(player.currentSong?.artist ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 8)
    }
}
