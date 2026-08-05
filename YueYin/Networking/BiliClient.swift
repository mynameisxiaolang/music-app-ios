import Foundation
import YueYinCore

/// B 站音乐源(镜像 Android BiliRepository:搜索解析 HTML + ranking 免登录接口 + playurl 音频流)
struct BiliClient {
    static let shared = BiliClient()

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    private let ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

    private func makeRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(ua, forHTTPHeaderField: "User-Agent")
        return req
    }

    private func isOK(_ resp: URLResponse?) -> Bool {
        (resp as? HTTPURLResponse)?.statusCode == 200
    }

    /// 搜索 B 站视频;失败/非 200 返回空列表(容错镜像 Android)
    func search(keyword: String) async -> [BiliVideo] {
        guard var comps = URLComponents(string: "https://search.bilibili.com/all") else { return [] }
        comps.queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        guard let url = comps.url else { return [] }
        do {
            let (data, resp) = try await session.data(for: makeRequest(url))
            guard isOK(resp), let html = String(data: data, encoding: .utf8) else { return [] }
            return BiliHTMLParser.parseSearchCards(html: html)
        } catch {
            return []
        }
    }

    /// B 站音乐排行榜(rid=3 免登录),首页推荐
    func hotMusic(limit: Int = 12) async -> [BiliVideo] {
        guard let url = URL(string: "https://api.bilibili.com/x/web-interface/ranking/v2?rid=3") else { return [] }
        do {
            let (data, resp) = try await session.data(for: makeRequest(url))
            guard isOK(resp) else { return [] }
            return Array(BiliJSONParsers.parseRanking(data).prefix(limit))
        } catch {
            return []
        }
    }

    /// bvid -> 音频流 URL(cid -> playurl),失败返回 nil
    func audioStreamURL(bvid: String) async -> URL? {
        guard let cid = await cid(of: bvid) else { return nil }
        guard let url = URL(string: "https://api.bilibili.com/x/player/playurl?bvid=\(bvid)&cid=\(cid)&qn=16&fnval=16") else { return nil }
        do {
            let (data, resp) = try await session.data(for: makeRequest(url))
            guard isOK(resp), let s = BiliJSONParsers.parseAudioUrl(data), !s.isEmpty,
                  let streamURL = URL(string: s) else { return nil }
            return streamURL
        } catch {
            return nil
        }
    }

    private func cid(of bvid: String) async -> Int64? {
        guard let url = URL(string: "https://api.bilibili.com/x/player/pagelist?bvid=\(bvid)") else { return nil }
        do {
            let (data, resp) = try await session.data(for: makeRequest(url))
            guard isOK(resp) else { return nil }
            return BiliJSONParsers.parseCid(data)
        } catch {
            return nil
        }
    }
}
