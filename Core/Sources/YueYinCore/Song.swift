import Foundation

/// 应用层歌曲模型(镜像 Android Song;bvid 为阶段 1 流式播放所用,阶段 2 下载仍走 bvid)
public struct Song: Hashable, Identifiable, Sendable {
    public let id: Int64
    public let name: String
    public let artist: String
    public let album: String
    public let coverUrl: String?
    public let durationMs: Int64
    public let isLocal: Bool
    public let localPath: String?
    public let bvid: String

    public init(
        id: Int64 = 0,
        name: String = "",
        artist: String = "",
        album: String = "",
        coverUrl: String? = nil,
        durationMs: Int64 = 0,
        isLocal: Bool = false,
        localPath: String? = nil,
        bvid: String = ""
    ) {
        self.id = id
        self.name = name
        self.artist = artist
        self.album = album
        self.coverUrl = coverUrl
        self.durationMs = durationMs
        self.isLocal = isLocal
        self.localPath = localPath
        self.bvid = bvid
    }

    public static func fromVideo(_ v: BiliVideo) -> Song {
        Song(
            id: stableID(from: v.bvid),
            name: TitleCleaner.displayTitle(v.title),
            coverUrl: v.cover,
            durationMs: DurationFormat.parse(v.duration),
            bvid: v.bvid
        )
    }

    /// bvid -> 稳定 Int64 id(阶段 1 无数据库;阶段 2 起由 GRDB 主键接管)
    public static func stableID(from bvid: String) -> Int64 {
        var hash: UInt64 = 5381
        for byte in bvid.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        return Int64(bitPattern: hash & 0x7FFF_FFFF_FFFF_FFFF)
    }
}
