import Foundation

/// B 站 JSON 接口解析(镜像 Android BiliRepository 的 JSONObject 逻辑)
public enum BiliJSONParsers {

    /// ranking/v2:data.list -> [BiliVideo](duration 秒 -> 字符串)
    public static func parseRanking(_ data: Data) -> [BiliVideo] {
        struct Resp: Decodable {
            struct Item: Decodable {
                let bvid: String
                let title: String
                let duration: Int64
                let pic: String?
            }
            struct Payload: Decodable {
                let list: [Item]?
            }
            let data: Payload?
        }
        guard let resp = try? JSONDecoder().decode(Resp.self, from: data),
              let list = resp.data?.list else { return [] }
        return list.map { item in
            BiliVideo(
                bvid: item.bvid,
                title: item.title,
                duration: DurationFormat.format(seconds: item.duration),
                cover: (item.pic?.isEmpty == false) ? item.pic : nil
            )
        }
    }

    /// playurl:dash.audio 中带宽最大的音频 URL(baseUrl 优先,回退 base_url)
    public static func parseAudioUrl(_ data: Data) -> String? {
        struct Resp: Decodable {
            struct Dash: Decodable {
                struct Audio: Decodable {
                    let bandwidth: Int64
                    let baseUrl: String?
                    let legacyBaseUrl: String?
                    enum CodingKeys: String, CodingKey {
                        case bandwidth, baseUrl
                        case legacyBaseUrl = "base_url"
                    }
                }
                let audio: [Audio]?
            }
            struct Payload: Decodable {
                let dash: Dash?
            }
            let data: Payload?
        }
        guard let resp = try? JSONDecoder().decode(Resp.self, from: data),
              let audio = resp.data?.dash?.audio else { return nil }
        let best = audio.max { $0.bandwidth < $1.bandwidth }
        if let url = best?.baseUrl, !url.isEmpty { return url }
        return best?.legacyBaseUrl
    }

    /// pagelist:data[0].cid(>0)
    public static func parseCid(_ data: Data) -> Int64? {
        struct Resp: Decodable {
            struct Page: Decodable {
                let cid: Int64
            }
            let data: [Page]?
        }
        guard let resp = try? JSONDecoder().decode(Resp.self, from: data),
              let first = resp.data?.first, first.cid > 0 else { return nil }
        return first.cid
    }
}
