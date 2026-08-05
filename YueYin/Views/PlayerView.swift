import SwiftUI
import YueYinCore

struct PlayerView: View {
    @ObservedObject private var player = PlayerCore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showQueue = false
    @State private var showSpeedMenu = false
    @State private var dragTime: TimeInterval?

    var body: some View {
        VStack(spacing: 24) {
            // 顶部栏
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down").font(.title3)
                }
                Spacer()
                Text("正在播放").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Button { showQueue = true } label: {
                    Image(systemName: "list.bullet").font(.title3)
                }
            }
            .padding(.horizontal)

            CoverImage(url: player.currentSong?.coverUrl)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

            VStack(spacing: 6) {
                Text(player.currentSong?.name ?? "")
                    .font(.title2)
                    .bold()
                    .lineLimit(1)
                Text(player.currentSong?.artist ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // 进度条
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { dragTime ?? player.currentTime },
                        set: { dragTime = $0 }
                    ),
                    in: 0...max(player.duration, 1),
                    onEditingChanged: { editing in
                        if !editing, let t = dragTime {
                            player.seek(to: t)
                            dragTime = nil
                        }
                    }
                )
                HStack {
                    Text(DurationFormat.format(seconds: Int64(dragTime ?? player.currentTime)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(DurationFormat.format(seconds: Int64(player.duration)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)

            // 控制按钮行
            HStack(spacing: 36) {
                Button { player.cycleMode() } label: {
                    Image(systemName: modeIcon).font(.title3)
                }
                Button { player.previous() } label: {
                    Image(systemName: "backward.fill").font(.system(size: 30))
                }
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                Button { player.next() } label: {
                    Image(systemName: "forward.fill").font(.system(size: 30))
                }
                Button { showSpeedMenu = true } label: {
                    Text("\(player.speed, specifier: "%.1f")x").font(.subheadline).bold()
                }
            }
            .padding(.bottom, 8)

            Spacer()
        }
        .padding(.top, 8)
        .confirmationDialog("播放速度", isPresented: $showSpeedMenu, titleVisibility: .visible) {
            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { s in
                Button("\(s, specifier: "%.2f")x") { player.setSpeed(Float(s)) }
            }
        }
        .sheet(isPresented: $showQueue) { queueSheet }
    }

    private var modeIcon: String {
        switch player.mode {
        case .order: return "arrow.rectanglepath"
        case .shuffle: return "shuffle"
        case .repeatOne: return "repeat.1"
        }
    }

    private var queueSheet: some View {
        NavigationView {
            List {
                ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, song in
                    HStack {
                        SongRow(song: song)
                        if index == player.currentIndex {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { player.jumpTo(index) }
                }
            }
            .navigationTitle("播放队列 (\(player.queue.count))")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
