import AVFoundation
import Foundation
import MediaPlayer
import YueYinCore

final class PlayerCore: ObservableObject {
    static let shared = PlayerCore()

    @Published private(set) var queue: [Song] = []
    @Published private(set) var currentIndex: Int?
    @Published private(set) var mode: PlayMode = .order
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var speed: Float = 1.0
    @Published private(set) var shuffled: [Int] = []

    var currentSong: Song? {
        guard let i = currentIndex, queue.indices.contains(i) else { return nil }
        return queue[i]
    }

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var loadGeneration = 0
    private let nowPlaying = NowPlayingCenter()

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            let d = self.player.currentItem?.duration.seconds ?? 0
            self.duration = d.isFinite ? d : 0
            self.nowPlaying.update(
                song: self.currentSong,
                isPlaying: self.isPlaying,
                time: self.currentTime,
                duration: self.duration
            )
        }

        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.advanceAfterEnd()
        }
    }

    /// 播放一组歌曲(首页/搜索点歌)
    func play(_ songs: [Song], startAt index: Int = 0) {
        guard !songs.isEmpty, index >= 0, index < songs.count else { return }
        queue = songs
        currentIndex = index
        shuffled = Array(0..<songs.count).shuffled()
        playCurrent()
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            guard player.currentItem != nil else { return }
            resumePlayback()
            isPlaying = true
        }
        nowPlaying.update(song: currentSong, isPlaying: isPlaying, time: currentTime, duration: duration)
    }

    func next() {
        guard let i = currentIndex,
              let target = QueueLogic.userNextIndex(current: i, count: queue.count, mode: mode, shuffled: shuffled)
        else { return }
        jump(to: target)
    }

    func previous() {
        guard let i = currentIndex,
              let target = QueueLogic.userPreviousIndex(current: i, count: queue.count, mode: mode, shuffled: shuffled)
        else { return }
        jump(to: target)
    }

    func seek(to time: TimeInterval) {
        let seconds = max(0, min(time, duration > 0 ? duration : time))
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        currentTime = seconds
    }

    func setSpeed(_ s: Float) {
        speed = s
        if isPlaying { player.rate = s }
    }

    func cycleMode() {
        mode = PlayMode(rawValue: (mode.rawValue + 1) % PlayMode.allCases.count) ?? .order
        if mode == .shuffle {
            shuffled = Array(0..<queue.count).shuffled()
        }
    }

    /// 队列行点击:切到指定索引(内部可见,PlayerView 队列 sheet 用)
    func jumpTo(_ index: Int) {
        guard queue.indices.contains(index) else { return }
        currentIndex = index
        playCurrent()
    }

    // MARK: - private

    private func resumePlayback() {
        player.play()
        if speed != 1 { player.rate = speed }
    }

    private func playCurrent() {
        guard let song = currentSong else { return }
        loadGeneration += 1
        let gen = loadGeneration
        Task { @MainActor in
            let url: URL?
            if song.isLocal, let p = song.localPath {
                url = URL(fileURLWithPath: p)
            } else {
                url = await BiliClient.shared.audioStreamURL(bvid: song.bvid)
            }
            guard let url else { return }  // 解析失败静默(容错,后续可加提示)
            guard gen == loadGeneration else { return }  // 过期加载丢弃(竞态保护)
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            resumePlayback()
            isPlaying = true
            currentTime = 0
            duration = 0
            nowPlaying.update(song: song, isPlaying: true, time: 0, duration: 0)
        }
    }

    private func advanceAfterEnd() {
        if mode == .repeatOne {
            player.seek(to: .zero)
            resumePlayback()
            return
        }
        guard let i = currentIndex,
              let target = QueueLogic.autoNextIndex(current: i, count: queue.count, mode: mode, shuffled: shuffled)
        else { return }
        if target == i {
            player.seek(to: .zero)
            resumePlayback()
            return
        }
        currentIndex = target
        playCurrent()
    }
}
