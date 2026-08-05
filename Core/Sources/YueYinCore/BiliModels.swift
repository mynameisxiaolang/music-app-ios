import Foundation

/// B 站搜索结果条目(镜像 Android BiliVideo)
public struct BiliVideo: Codable, Hashable, Identifiable, Sendable {
    public let bvid: String
    public let title: String
    public let duration: String
    public let cover: String?

    public var id: String { bvid }

    public init(bvid: String = "", title: String = "", duration: String = "", cover: String? = nil) {
        self.bvid = bvid
        self.title = title
        self.duration = duration
        self.cover = cover
    }
}
