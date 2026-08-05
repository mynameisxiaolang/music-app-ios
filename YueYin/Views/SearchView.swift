import SwiftUI
import YueYinCore

struct SearchView: View {
    @State private var keyword = ""
    @State private var results: [BiliVideo] = []
    @State private var searching = false
    @State private var searched = false

    var body: some View {
        NavigationView {
            Group {
                if searching {
                    ProgressView("搜索中…")
                } else if searched && results.isEmpty {
                    Text("没有找到结果")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(results) { v in
                            SongRow(song: Song.fromVideo(v))
                                .onTapGesture { play(v) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $keyword, prompt: "搜索 B 站音乐")
            .navigationTitle("搜索")
            .onSubmit(of: .search) {
                Task { await doSearch() }
            }
        }
    }

    private func doSearch() async {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searching = true
        searched = true
        results = await BiliClient.shared.search(keyword: trimmed)
        searching = false
    }

    private func play(_ v: BiliVideo) {
        let songs = results.map(Song.fromVideo)
        guard let index = results.firstIndex(of: v) else { return }
        PlayerCore.shared.play(songs, startAt: index)
    }
}
