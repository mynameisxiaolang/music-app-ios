import Foundation

/// 播放队列纯逻辑(不依赖 AVPlayer,可单测)
struct QueueLogic {
    /// 播完自动切下一首;返回 nil 表示停止
    static func autoNextIndex(current: Int?, count: Int, mode: PlayMode, shuffled: [Int]) -> Int? {
        guard count > 0 else { return nil }
        switch mode {
        case .repeatOne:
            return current ?? 0
        case .order:
            guard let c = current else { return 0 }
            return (c + 1) % count
        case .shuffle:
            guard let c = current, let pos = shuffled.firstIndex(of: c) else { return shuffled.first }
            return shuffled[(pos + 1) % shuffled.count]
        }
    }

    /// 用户点"下一首"(repeatOne 也前进)
    static func userNextIndex(current: Int?, count: Int, mode: PlayMode, shuffled: [Int]) -> Int? {
        guard count > 0 else { return nil }
        switch mode {
        case .shuffle:
            guard let c = current, let pos = shuffled.firstIndex(of: c) else { return shuffled.first }
            return shuffled[(pos + 1) % shuffled.count]
        case .order, .repeatOne:
            guard let c = current else { return 0 }
            return (c + 1) % count
        }
    }

    /// 用户点"上一首"(shuffle 后退一步,到头停住;其余模式回绕)
    static func userPreviousIndex(current: Int?, count: Int, mode: PlayMode, shuffled: [Int]) -> Int? {
        guard count > 0 else { return nil }
        switch mode {
        case .shuffle:
            guard let c = current, let pos = shuffled.firstIndex(of: c), pos > 0 else { return current ?? shuffled.first }
            return shuffled[pos - 1]
        case .order, .repeatOne:
            guard let c = current else { return 0 }
            return (c - 1 + count) % count
        }
    }
}
