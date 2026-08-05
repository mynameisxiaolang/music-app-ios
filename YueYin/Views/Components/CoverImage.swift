import SwiftUI

/// B 站封面(带 Referer 头 + 内存缓存;AsyncImage 不支持自定义 header)
struct CoverImage: View {
    let url: String?

    var body: some View {
        ZStack {
            Rectangle().fill(Color.gray.opacity(0.3))
            Image(systemName: "music.note").foregroundColor(.gray)
        }
        .overlay(
            Group {
                if let url, let u = URL(string: url) {
                    CoverImageInternal(url: u)
                }
            }
        )
        .clipped()
    }
}

private struct CoverImageInternal: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .task { image = await CoverLoader.shared.load(url) }
    }
}

final class CoverLoader {
    static let shared = CoverLoader()
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: cfg)
    }

    func load(_ url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        var req = URLRequest(url: url)
        req.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, resp) = try await session.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200, let img = UIImage(data: data) else { return nil }
            cache.setObject(img, forKey: url as NSURL)
            return img
        } catch {
            return nil
        }
    }
}
