import SwiftUI

struct RootView: View {
    @ObservedObject private var player = PlayerCore.shared
    @State private var showPlayer = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
            SearchView()
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
        }
        .overlay(alignment: .bottom) {
            if player.currentSong != nil {
                MiniPlayerView()
                    .onTapGesture { showPlayer = true }
                    .padding(.bottom, 49)  // 浮在 TabBar 上方(真机微调)
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView()
        }
    }
}
