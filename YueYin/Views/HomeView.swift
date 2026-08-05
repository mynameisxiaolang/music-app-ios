import SwiftUI
import YueYinCore

struct HomeView: View {
    @State private var videos: [BiliVideo] = []
    @State private var loading = true

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("加载中…")
                } else {
                    List {
                        if videos.isEmpty {
                            Text("加载失败,下拉重试")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(videos) { v in
                                SongRow(song: Song.fromVideo(v))
                                    .onTapGesture { play(v) }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("悦音音乐")
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        loading = true
        videos = await BiliClient.shared.hotMusic()
        loading = false
    }

    private func play(_ v: BiliVideo) {
        let songs = videos.map(Song.fromVideo)
        guard let index = videos.firstIndex(of: v) else { return }
        PlayerCore.shared.play(songs, startAt: index)
    }
}
