import Foundation
import MediaPlayer
import YueYinCore

/// 锁屏/控制中心媒体信息与遥控(阶段 1 基础版;阶段 4 完善封面/进度)
final class NowPlayingCenter {
    private var configured = false

    func update(song: Song?, isPlaying: Bool, time: TimeInterval, duration: TimeInterval) {
        setupRemoteCommands()
        var info: [String: Any] = [:]
        if let song {
            info[MPMediaItemPropertyTitle] = song.name
            info[MPMediaItemPropertyArtist] = song.artist.isEmpty ? "伟大音乐" : song.artist
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommands() {
        guard !configured else { return }
        configured = true
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { _ in
            PlayerCore.shared.togglePlayPause()
            return .success
        }
        center.pauseCommand.addTarget { _ in
            PlayerCore.shared.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { _ in
            PlayerCore.shared.next()
            return .success
        }
        center.previousTrackCommand.addTarget { _ in
            PlayerCore.shared.previous()
            return .success
        }
    }
}
