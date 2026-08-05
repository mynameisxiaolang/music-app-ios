# 悦音音乐 iOS 版 · 阶段 1(核心骨架)实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建可编译、可安装到越狱 iPhone 的 iOS 工程骨架,实现首页热门、B 站搜索、流式播放(播放页 + 迷你播放栏 + 队列 + 倍速 + 循环模式 + 基础锁屏控制),全部由 GitHub Actions 云编译出 unsigned .ipa。

**Architecture:** 镜像 Android 版分层(Networking / Player / Views)。纯逻辑(模型、HTML/JSON 解析、时间格式化)放入 `Core/` SPM 包(无外部依赖,可 `swift test` 快速验证);URLSession 网络层与 AVPlayer 播放器在 App target;`.xcodeproj` 由 XcodeGen 从 `project.yml` 生成(不提交 git),CI 每次重新生成。

**Tech Stack:** Swift 5.9 / SwiftUI(iOS 15.0+)/ AVPlayer / URLSession / XcodeGen / GitHub Actions(macos-14)/ XCTest

**测试环境说明:** 开发机是 Windows,无 Xcode。每个任务的验证 = 推 GitHub 等 CI 绿 + 按"真机验证"步骤在手机上测。Core 包测试可在 CI `swift test` 跑(约 1 分钟),App 测试在 CI 模拟器跑。可选:装 Swift for Windows 工具链后可在本机 `cd Core && swift test` 快速迭代纯逻辑。

## Global Constraints

- iOS 部署目标 15.0,Swift 5.9
- GitHub Actions(macos-14 runner)免费编译;`CODE_SIGNING_ALLOWED=NO`,产出 **unsigned .ipa**(`Payload/` 目录结构),不经签名直接装越狱机
- **公开 GitHub 仓库**(免费 macOS runner 的前提);真实 DeepSeek key 绝不提交(阶段 3 用 CI secret `DEEPSEEK_API_KEY`)
- B 站请求必须带 UA 头(`Mozilla/5.0 ... Chrome/126.0.0.0 Safari/537.36`);图床(封面)请求带 `Referer: https://www.bilibili.com/`
- `UIBackgroundModes: audio`(未签名 App 同样生效);`NSAllowsLocalNetworking: true`(阶段 3 本地服务器用)
- 解析/网络失败返回空结果,不崩溃(容错策略镜像 Android)
- 目录结构镜像 Android:`Models / Networking / Repositories / Player / Persistence / Views / Mascot`
- `.xcodeproj` 由 XcodeGen 生成,gitignore,CI 里 `xcodegen generate`
- 阶段 1 播放为**流式**(playurl 直连 AVPlayer);阶段 2 改为下载后播本地文件(AVPlayer API 相同,PlayerCore 无需改动)

---

### Task 1: 工程骨架 + CI 流水线(产出可安装空壳 ipa)

**Files:**
- Create: `project.yml`
- Create: `.github/workflows/build.yml`
- Create: `.gitignore`
- Create: `YueYin/YueYinApp.swift`
- Create: `YueYin/RootView.swift`(占位,Task 5 充实)
- Create: `YueYinTests/SmokeTests.swift`
- Test: GitHub Actions 绿 + 下载 artifact 内 `.ipa`

**Interfaces:**
- Consumes: 无
- Produces: `YueYin` app target + `YueYinTests` test target + CI 产物 `YueYin-unsigned-ipa` artifact;后续任务都在此工程内加文件,`xcodegen` 自动包含新文件

- [ ] **Step 1: 创建 `project.yml`**

```yaml
name: YueYin
options:
  bundleIdPrefix: com.yueyin
  deploymentTarget:
    iOS: "15.0"
  createIntermediateGroups: true
packages:
  YueYinCore:
    path: Core
targets:
  YueYin:
    type: application
    platform: iOS
    sources: [YueYin]
    dependencies:
      - package: YueYinCore
    info:
      path: YueYin/Info.plist
      properties:
        CFBundleDisplayName: 悦音音乐
        UIBackgroundModes: [audio]
        NSAppTransportSecurity:
          NSAllowsLocalNetworking: true
        UILaunchScreen: {}
        UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yueyin.music
        SWIFT_VERSION: "5.9"
        TARGETED_DEVICE_FAMILY: "1"
        CODE_SIGNING_ALLOWED: "NO"
  YueYinTests:
    type: bundle.unit-test
    platform: iOS
    sources: [YueYinTests]
    dependencies:
      - target: YueYin
      - package: YueYinCore
    settings:
      base:
        SWIFT_VERSION: "5.9"
        CODE_SIGNING_ALLOWED: "NO"
schemes:
  YueYin:
    build:
      targets:
        YueYin: all
    run:
      config: Debug
    test:
      targets:
        - YueYinTests
```

- [ ] **Step 2: 创建 `.github/workflows/build.yml`**

```yaml
name: Build unsigned IPA
on:
  push:
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Install XcodeGen
        run: brew install xcodegen
      - name: Test YueYinCore package
        run: cd Core && swift test
      - name: Generate project
        run: xcodegen generate
      - name: Unit tests (simulator)
        run: xcodebuild test -project YueYin.xcodeproj -scheme YueYin -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
      - name: Build Release (device, unsigned)
        run: xcodebuild build -project YueYin.xcodeproj -scheme YueYin -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO -derivedDataPath build
      - name: Package IPA
        run: |
          mkdir -p Payload
          cp -R build/Build/Products/Release-iphoneos/YueYin.app Payload/
          zip -qr YueYin.ipa Payload
      - uses: actions/upload-artifact@v4
        with:
          name: YueYin-unsigned-ipa
          path: YueYin.ipa
```

- [ ] **Step 3: 创建 `.gitignore`**

```
# Xcode 生成物(xcodeproj 由 XcodeGen 生成,不提交)
YueYin.xcodeproj/
build/
DerivedData/
*.xcuserstate
.DS_Store
# Swift Package 生成物
Core/.build/
Core/.swiftpm/
# SDD 工作区(ledger/briefs/reports)
.superpowers/
```

- [ ] **Step 4: 创建 `YueYin/YueYinApp.swift` 与占位 `YueYin/RootView.swift`**

```swift
// YueYin/YueYinApp.swift
import SwiftUI

@main
struct YueYinApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

```swift
// YueYin/RootView.swift(占位,Task 5 替换为真实实现)
import SwiftUI

struct RootView: View {
    var body: some View {
        Text("悦音音乐")
    }
}
```

- [ ] **Step 5: 创建 `YueYinTests/SmokeTests.swift`(编译冒烟,Task 4 起被真实测试取代)**

```swift
import XCTest

final class SmokeTests: XCTestCase {
    func testTargetCompiles() {
        XCTAssertEqual(1 + 1, 2)
    }
}
```

- [ ] **Step 6: 建 GitHub 仓库并推送(需要用户操作一次)**

1. 在 https://github.com/new 创建一个**公开**仓库 `music-app-ios`(不要勾选任何初始化文件)
2. 在项目根目录执行:

```bash
git init -b main
git add .
git commit -m "feat: 工程骨架 + CI 流水线

Co-Authored-By: Claude <noreply@anthropic.com>"
git branch -M main
git remote add origin git@github.com:<你的用户名>/music-app-ios.git
git push -u origin main
```

(如果本机没有配置 SSH key,改用 `git remote add origin https://github.com/<你的用户名>/music-app-ios.git` 并用 HTTPS 凭据推送)

- [ ] **Step 7: 验证 CI 绿**

打开 https://github.com/<你的用户名>/music-app-ios/actions ,等待 "Build unsigned IPA" 跑完。
Expected: 5 个 step 全绿;Artifacts 里出现 `YueYin-unsigned-ipa`。
若失败,点开失败 step 读日志修到绿为止(常见问题:XcodeGen 未装好 / Core 目录不存在——Core 是 Task 2 才创建,若 CI 先于 Task 2 失败属预期,直接进入 Task 2,Task 2 完成后 CI 自愈)。

- [ ] **Step 8: 真机安装验证(需用户操作)**

1. 手机已越狱并装好 AppSync Unified(无 Sileo? 用 palera1n 默认的 Sileo 搜索安装)
2. Actions 页 → 打开 `YueYin-unsigned-ipa` → 下载 `YueYin.ipa`
3. 隔空投送到 iPhone(或手机浏览器下载)→ 用 **Filza** 打开 → 点安装
4. Expected: 桌面出现「悦音音乐」图标,打开显示"悦音音乐"文字

- [ ] **Step 9: Commit**

```bash
git add project.yml .github .gitignore YueYin YueYinTests
git commit -m "feat: 工程骨架 + CI 流水线

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

---

### Task 2: YueYinCore 包 — 模型 + HTML/JSON 解析 + 时间/标题工具(TDD)

**Files:**
- Create: `Core/Package.swift`
- Create: `Core/Sources/YueYinCore/BiliModels.swift`
- Create: `Core/Sources/YueYinCore/Song.swift`
- Create: `Core/Sources/YueYinCore/BiliHTMLParser.swift`
- Create: `Core/Sources/YueYinCore/BiliJSONParsers.swift`
- Create: `Core/Sources/YueYinCore/DurationFormat.swift`
- Create: `Core/Sources/YueYinCore/TitleCleaner.swift`
- Create: `Core/Tests/YueYinCoreTests/Fixtures.swift`
- Create: `Core/Tests/YueYinCoreTests/BiliHTMLParserTests.swift`
- Create: `Core/Tests/YueYinCoreTests/BiliJSONParsersTests.swift`
- Create: `Core/Tests/YueYinCoreTests/DurationFormatTests.swift`
- Create: `Core/Tests/YueYinCoreTests/TitleCleanerTests.swift`
- Test: `cd Core && swift test`(CI 同款命令)

**Interfaces:**
- Consumes: 无
- Produces: library product `YueYinCore`(App 与 App 测试 target 均已声明依赖):
  - `BiliVideo`(Codable, Identifiable by bvid, Hashable, Sendable)
  - `Song` + `Song.fromVideo(_:)` + `Song.stableID(from:) -> Int64`
  - `BiliHTMLParser.parseSearchCards(html: String) -> [BiliVideo]`
  - `BiliJSONParsers.parseRanking(_ data: Data) -> [BiliVideo]`
  - `BiliJSONParsers.parseAudioUrl(_ data: Data) -> String?`
  - `BiliJSONParsers.parseCid(_ data: Data) -> Int64?`
  - `DurationFormat.format(seconds: Int64) -> String`、`DurationFormat.parse(_ duration: String) -> Int64`
  - `TitleCleaner.displayTitle(_ title: String) -> String`

- [ ] **Step 1: 写失败测试 — 全部测试文件**

`Core/Package.swift`:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YueYinCore",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "YueYinCore", targets: ["YueYinCore"])
    ],
    targets: [
        .target(name: "YueYinCore"),
        .testTarget(name: "YueYinCoreTests", dependencies: ["YueYinCore"])
    ]
)
```

`Core/Tests/YueYinCoreTests/Fixtures.swift`(fixture 内容基于 Android 端实际用到的 B 站页面结构):

```swift
import Foundation

enum Fixtures {
    /// 搜索页 HTML 片段:2 张普通卡片 + 1 张无时长/无封面的卡片 + 1 个非 hdslb 图床(不应匹配)
    static let searchHTML = """
    <div class="bili-video-card is-rcmd">
      <div class="bili-video-card__image">
        <a href="//www.bilibili.com/video/BV1GJ411x7h7/" class="bili-video-card__cover">
          <img data-src="https://i0.hdslb.com/bfs/archive/abc123.jpg@672w_378h_1c.webp" />
          <span class="bili-video-card__stats__duration">04:22</span>
        </a>
      </div>
      <h3 class="bili-video-card__info--tit" title="【钢琴】告白气球 - 周杰伦">【钢琴】告白气球 - 周杰伦</h3>
    </div>
    <div class="bili-video-card is-rcmd">
      <a href="//www.bilibili.com/video/BV1Zx411w7KC/">
        <img data-src="https://i1.hdslb.com/bfs/archive/def456.jpg" />
        <span class="bili-video-card__stats__duration">1:03:41</span>
      </a>
      <h3 class="bili-video-card__info--tit" title="[4K] 星空音乐会全场">[4K] 星空音乐会全场</h3>
    </div>
    <div class="bili-video-card is-rcmd">
      <a href="//www.bilibili.com/video/BV1wK411a7s2/">
        <img src="https://img.example.com/not-hdslb.jpg" />
        <h3 class="bili-video-card__info--tit" title="纯音乐直播">纯音乐直播</h3>
      </a>
    </div>
    <img src="https://i0.hdslb.com/bfs/other/not-in-card.jpg" />
    """

    /// ranking/v2 接口返回(JSON,真实字段子集)
    static let rankingJSON = """
    {"code":0,"message":"0","data":{"list":[
      {"bvid":"BV1GJ411x7h7","title":"【钢琴】告白气球 - 周杰伦","duration":262,"pic":"https://i0.hdslb.com/bfs/archive/abc.jpg"},
      {"bvid":"BV1Zx411w7KC","title":"[4K] 星空音乐会","duration":3821,"pic":""}
    ]}}
    """.data(using: .utf8)!

    /// playurl 接口返回:dash.audio 两条,带宽大的在后且只有 base_url
    static let playurlJSON = """
    {"code":0,"data":{"dash":{"audio":[
      {"id":30216,"baseUrl":"https://upos-sz-mirror08c.bilivideo.com/30216.m4a","bandwidth":142808},
      {"id":30232,"bandwidth":320162,"base_url":"https://legacy.example.com/30232.m4a"}
    ]}}}
    """.data(using: .utf8)!

    /// pagelist 接口返回
    static let pagelistJSON = """
    {"code":0,"data":[{"cid":251767522,"page":1,"part":"正片","duration":262}]}
    """.data(using: .utf8)!
}
```

`Core/Tests/YueYinCoreTests/BiliHTMLParserTests.swift`:

```swift
import XCTest
@testable import YueYinCore

final class BiliHTMLParserTests: XCTestCase {
    func testParsesThreeCards() {
        let cards = BiliHTMLParser.parseSearchCards(html: Fixtures.searchHTML)
        XCTAssertEqual(cards.count, 3)
        XCTAssertEqual(cards[0].bvid, "BV1GJ411x7h7")
        XCTAssertEqual(cards[0].title, "【钢琴】告白气球 - 周杰伦")
        XCTAssertEqual(cards[0].duration, "04:22")
        XCTAssertEqual(cards[0].cover, "https://i0.hdslb.com/bfs/archive/abc123.jpg@672w_378h_1c.webp")
        XCTAssertEqual(cards[1].bvid, "BV1Zx411w7KC")
        XCTAssertEqual(cards[1].duration, "1:03:41")
        XCTAssertEqual(cards[1].cover, "https://i1.hdslb.com/bfs/archive/def456.jpg")
        XCTAssertEqual(cards[2].bvid, "BV1wK411a7s2")
        XCTAssertNil(cards[2].cover)
        XCTAssertEqual(cards[2].duration, "")
    }

    func testJunkHTMLReturnsEmpty() {
        XCTAssertTrue(BiliHTMLParser.parseSearchCards(html: "<html>nothing here</html>").isEmpty)
        XCTAssertTrue(BiliHTMLParser.parseSearchCards(html: "").isEmpty)
    }
}
```

`Core/Tests/YueYinCoreTests/BiliJSONParsersTests.swift`:

```swift
import XCTest
@testable import YueYinCore

final class BiliJSONParsersTests: XCTestCase {
    func testParseRanking() {
        let items = BiliJSONParsers.parseRanking(Fixtures.rankingJSON)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].bvid, "BV1GJ411x7h7")
        XCTAssertEqual(items[0].duration, "04:22")
        XCTAssertEqual(items[0].cover, "https://i0.hdslb.com/bfs/archive/abc.jpg")
        XCTAssertEqual(items[1].duration, "1:03:41")
        XCTAssertNil(items[1].cover)
    }

    func testParseRankingJunkReturnsEmpty() {
        XCTAssertTrue(BiliJSONParsers.parseRanking(Data("not json".utf8)).isEmpty)
    }

    func testParseAudioUrlPicksMaxBandwidth() {
        XCTAssertEqual(BiliJSONParsers.parseAudioUrl(Fixtures.playurlJSON), "https://legacy.example.com/30232.m4a")
    }

    func testParseAudioUrlJunkReturnsNil() {
        XCTAssertNil(BiliJSONParsers.parseAudioUrl(Data("not json".utf8)))
    }

    func testParseCid() {
        XCTAssertEqual(BiliJSONParsers.parseCid(Fixtures.pagelistJSON), 251_767_522)
    }

    func testParseCidJunkReturnsNil() {
        XCTAssertNil(BiliJSONParsers.parseCid(Data("not json".utf8)))
    }
}
```

`Core/Tests/YueYinCoreTests/DurationFormatTests.swift`:

```swift
import XCTest
@testable import YueYinCore

final class DurationFormatTests: XCTestCase {
    func testFormat() {
        XCTAssertEqual(DurationFormat.format(seconds: 0), "")
        XCTAssertEqual(DurationFormat.format(seconds: 90), "01:30")
        XCTAssertEqual(DurationFormat.format(seconds: 262), "04:22")
        XCTAssertEqual(DurationFormat.format(seconds: 3821), "1:03:41")
    }

    func testParse() {
        XCTAssertEqual(DurationFormat.parse("04:22"), 262_000)
        XCTAssertEqual(DurationFormat.parse("1:03:41"), 3_821_000)
        XCTAssertEqual(DurationFormat.parse("junk"), 0)
        XCTAssertEqual(DurationFormat.parse(""), 0)
    }
}
```

`Core/Tests/YueYinCoreTests/TitleCleanerTests.swift`:

```swift
import XCTest
@testable import YueYinCore

final class TitleCleanerTests: XCTestCase {
    func testStripsTagsAndCollapsesWhitespace() {
        XCTAssertEqual(TitleCleaner.displayTitle("【钢琴】告白气球 - 周杰伦"), "告白气球 - 周杰伦")
        XCTAssertEqual(TitleCleaner.displayTitle("[4K] 星空  音乐会"), "4K 星空 音乐会")
    }

    func testBlankFallsBackToOriginal() {
        XCTAssertEqual(TitleCleaner.displayTitle("【】"), "【】")
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Core && swift test`
Expected: 编译失败(cannot find 'YueYinCore' 等)

- [ ] **Step 3: 写实现 — Core 源码文件**

`Core/Sources/YueYinCore/BiliModels.swift`:

```swift
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
```

`Core/Sources/YueYinCore/Song.swift`:

```swift
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
```

`Core/Sources/YueYinCore/TitleCleaner.swift`:

```swift
/// 列表显示用标题:去掉【】[] 标签、压缩空白(保留完整标题用于下载/歌词匹配)
public enum TitleCleaner {
    public static func displayTitle(_ title: String) -> String {
        let cleaned = title
            .replacingOccurrences(of: #"【[^】]*】"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\[[^\]]*\]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? title : cleaned
    }
}
```

`Core/Sources/YueYinCore/DurationFormat.swift`:

```swift
/// 时长格式化(镜像 Android BiliRepository.formatDuration / parseDuration)
public enum DurationFormat {
    /// 秒 -> "06:12" / "1:03:41";<=0 返回空串
    public static func format(seconds: Int64) -> String {
        guard seconds > 0 else { return "" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    /// "06:12" / "1:03:41" -> 毫秒;非法返回 0
    public static func parse(_ duration: String) -> Int64 {
        let parts = duration.split(separator: ":")
        let nums = parts.compactMap { Int64($0) }
        guard nums.count == parts.count, !nums.isEmpty else { return 0 }
        if nums.count == 3 {
            return nums[0] * 3_600_000 + nums[1] * 60_000 + nums[2] * 1_000
        }
        if nums.count == 2 {
            return nums[0] * 60_000 + nums[1] * 1_000
        }
        return 0
    }
}
```

`Core/Sources/YueYinCore/BiliHTMLParser.swift`(正则逐字镜像 Android parseCards):

```swift
import Foundation

/// 搜索页 HTML 卡片解析(镜像 Android BiliRepository.parseCards)
public enum BiliHTMLParser {
    private static let cardPattern =
        #"<a href="//www\.bilibili\.com/video/(BV[0-9A-Za-z]+)/"[^>]*>[\s\S]*?<h3 class="bili-video-card__info--tit" title="([^"]*)""#
    private static let durationPattern = #"bili-video-card__stats__duration"[^>]*>([\d:]+)<"#
    private static let coverPattern = #"(?:data-src|src)="(https?://i[0-9a-z.]*hdslb\.com[^"]+)""#

    /// 最多 20 条
    public static func parseSearchCards(html: String) -> [BiliVideo] {
        guard let cardRe = try? NSRegularExpression(pattern: cardPattern),
              let durRe = try? NSRegularExpression(pattern: durationPattern),
              let coverRe = try? NSRegularExpression(pattern: coverPattern)
        else { return [] }

        let ns = html as NSString
        let matches = cardRe.matches(in: html, range: NSRange(location: 0, length: ns.length))
        var cards: [BiliVideo] = []

        for m in matches where m.numberOfRanges >= 3 {
            let bvid = ns.substring(with: m.range(at: 1))
            let title = ns.substring(with: m.range(at: 2))
            // 卡片匹配起点向后 4000 字符内找时长/封面(镜像 Android)
            let start = m.range.location
            let windowEnd = min(start + m.range.length + 4000, ns.length)
            let window = ns.substring(with: NSRange(location: start, length: windowEnd - start))
            let winNS = window as NSString
            let winRange = NSRange(location: 0, length: winNS.length)

            var duration = ""
            if let dm = durRe.firstMatch(in: window, range: winRange) {
                duration = winNS.substring(with: dm.range(at: 1))
            }
            var cover: String?
            if let cm = coverRe.firstMatch(in: window, range: winRange) {
                cover = winNS.substring(with: cm.range(at: 1))
            }
            cards.append(BiliVideo(bvid: bvid, title: title, duration: duration, cover: cover))
            if cards.count >= 20 { break }
        }
        return cards
    }
}
```

`Core/Sources/YueYinCore/BiliJSONParsers.swift`:

```swift
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
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd Core && swift test`
Expected: 全部 PASS(4 个测试类)

- [ ] **Step 5: 推送 CI 验证 + Commit**

```bash
git add Core
git commit -m "feat: YueYinCore 模型与解析器(HTML/JSON/时长/标题)

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

Expected: Actions 绿(此时 Task 1 的 `swift test` step 从"找不到 Core"变为真正跑测试)。

---

### Task 3: BiliClient 网络层

**Files:**
- Create: `YueYin/Networking/BiliClient.swift`
- Test: 推 CI 编译绿(网络层解析逻辑已在 Task 2 用 fixture 覆盖;网络请求不写单测——CI 访问 B 站不可靠)

**Interfaces:**
- Consumes: `BiliVideo`、`BiliHTMLParser`、`BiliJSONParsers`(YueYinCore)
- Produces: `BiliClient.shared`:
  - `func search(keyword: String) async -> [BiliVideo]`
  - `func hotMusic(limit: Int = 12) async -> [BiliVideo]`
  - `func audioStreamURL(bvid: String) async -> URL?`

- [ ] **Step 1: 创建 `YueYin/Networking/BiliClient.swift`**

```swift
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
```

- [ ] **Step 2: 推送 CI 验证 + Commit**

```bash
git add YueYin/Networking
git commit -m "feat: BiliClient 网络层(搜索/热门/音频流 URL)

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

Expected: Actions 绿。

- [ ] **Step 3: 真机冒烟(可选但推荐)**

装最新包后暂时无法从 UI 触发——阶段 1 的 UI 从 Task 5 开始可测,本步可跳过。若想提前验证网络,临时在 `RootView` 加 `.task { print(await BiliClient.shared.hotMusic()) }`,看 Xcode 控制台不可行(无 Xcode)——改为看设备日志(设置→开发者→日志),或直接等 Task 5。

---

### Task 4: PlayerCore(队列/模式/倍速/进度)+ 基础锁屏控制(TDD)

**Files:**
- Create: `YueYin/Player/PlayMode.swift`
- Create: `YueYin/Player/QueueLogic.swift`
- Create: `YueYin/Player/PlayerCore.swift`
- Create: `YueYin/Player/NowPlayingCenter.swift`
- Create: `YueYinTests/QueueLogicTests.swift`
- Create: `YueYinTests/PlayerCoreTests.swift`
- Modify: 删除 `YueYinTests/SmokeTests.swift`
- Test: `xcodebuild test`(CI)

**Interfaces:**
- Consumes: `Song`、`BiliClient.shared.audioStreamURL(bvid:)`;Task 5/6 的 View 依赖本任务产出
- Produces(后续任务使用的精确接口):
  - `enum PlayMode: Int, CaseIterable { case order, shuffle, repeatOne }`
  - `struct QueueLogic { static func autoNextIndex(current: Int?, count: Int, mode: PlayMode, shuffled: [Int]) -> Int?; static func userNextIndex(...); static func userPreviousIndex(...) }`
  - `final class PlayerCore: ObservableObject`(单例 `PlayerCore.shared`):
    - 属性:`queue: [Song]`、`currentIndex: Int?`、`mode: PlayMode`、`isPlaying: Bool`、`currentTime: TimeInterval`、`duration: TimeInterval`、`speed: Float`、`shuffled: [Int]`(全部 `@Published private(set)`)、`currentSong: Song?`
    - 方法:`play(_ songs: [Song], startAt: Int = 0)`、`togglePlayPause()`、`next()`、`previous()`、`seek(to: TimeInterval)`、`setSpeed(_: Float)`、`cycleMode()`、`jumpTo(_ index: Int)`(内部可见,播放队列行点击用)
  - `final class NowPlayingCenter`:`update(song:isPlaying:time:duration:)`

- [ ] **Step 1: 写失败测试**

`YueYinTests/QueueLogicTests.swift`:

```swift
import XCTest
@testable import YueYin

final class QueueLogicTests: XCTestCase {
    func testAutoNextOrderWraps() {
        XCTAssertEqual(QueueLogic.autoNextIndex(current: 0, count: 3, mode: .order, shuffled: []), 1)
        XCTAssertEqual(QueueLogic.autoNextIndex(current: 2, count: 3, mode: .order, shuffled: []), 0)
    }

    func testAutoNextRepeatOneStays() {
        XCTAssertEqual(QueueLogic.autoNextIndex(current: 1, count: 3, mode: .repeatOne, shuffled: []), 1)
    }

    func testAutoNextShuffleWalksPermutation() {
        let shuffled = [2, 0, 1]
        var seen: [Int] = []
        var current = 0
        for _ in 0..<3 {
            guard let next = QueueLogic.autoNextIndex(current: current, count: 3, mode: .shuffle, shuffled: shuffled) else {
                return XCTFail("unexpected nil")
            }
            seen.append(next)
            current = next
        }
        XCTAssertEqual(Set(seen), [0, 1, 2])
    }

    func testUserNextIgnoresRepeatOne() {
        XCTAssertEqual(QueueLogic.userNextIndex(current: 1, count: 3, mode: .repeatOne, shuffled: []), 2)
    }

    func testUserPreviousWraps() {
        XCTAssertEqual(QueueLogic.userPreviousIndex(current: 0, count: 3, mode: .order, shuffled: []), 2)
        XCTAssertEqual(QueueLogic.userPreviousIndex(current: 2, count: 3, mode: .order, shuffled: []), 1)
    }
}
```

`YueYinTests/PlayerCoreTests.swift`:

```swift
import XCTest
@testable import YueYin

final class PlayerCoreTests: XCTestCase {
    // 只断言队列/索引/当前曲目(不触发真实网络播放;bvid 无效时 playCurrent 静默失败,不阻塞断言)
    func testPlaySetsQueueAndIndex() {
        let core = PlayerCore.shared
        let songs = [
            Song(name: "A", bvid: "BV1"),
            Song(name: "B", bvid: "BV2"),
            Song(name: "C", bvid: "BV3"),
        ]
        core.play(songs, startAt: 1)
        XCTAssertEqual(core.queue.count, 3)
        XCTAssertEqual(core.currentIndex, 1)
        XCTAssertEqual(core.currentSong?.name, "B")
    }

    func testNextAndPreviousMove() {
        let core = PlayerCore.shared
        let songs = [Song(name: "A", bvid: "BV1"), Song(name: "B", bvid: "BV2"), Song(name: "C", bvid: "BV3")]
        core.play(songs, startAt: 0)
        core.next()
        XCTAssertEqual(core.currentIndex, 1)
        core.previous()
        XCTAssertEqual(core.currentIndex, 0)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: 推 CI(`xcodebuild test` step)
Expected: FAIL(cannot find 'QueueLogic' in scope)

- [ ] **Step 3: 写实现**

`YueYin/Player/PlayMode.swift`:

```swift
import Foundation

enum PlayMode: Int, CaseIterable {
    case order = 0
    case shuffle = 1
    case repeatOne = 2
}
```

`YueYin/Player/QueueLogic.swift`:

```swift
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
```

`YueYin/Player/NowPlayingCenter.swift`:

```swift
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
            info[MPMediaItemPropertyArtist] = song.artist.isEmpty ? "悦音音乐" : song.artist
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
```

`YueYin/Player/PlayerCore.swift`:

```swift
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
            self.duration = self.player.currentItem?.duration.seconds ?? 0
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
            player.play()
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
        player.defaultRate = s
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

    private func playCurrent() {
        guard let song = currentSong else { return }
        Task { @MainActor in
            let url: URL?
            if song.isLocal, let p = song.localPath {
                url = URL(fileURLWithPath: p)
            } else {
                url = await BiliClient.shared.audioStreamURL(bvid: song.bvid)
            }
            guard let url else { return }  // 解析失败静默(容错,后续可加提示)
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            player.defaultRate = speed
            player.play()
            isPlaying = true
            currentTime = 0
            nowPlaying.update(song: song, isPlaying: true, time: 0, duration: 0)
        }
    }

    private func advanceAfterEnd() {
        if mode == .repeatOne {
            player.seek(to: .zero)
            player.play()
            return
        }
        guard let i = currentIndex,
              let target = QueueLogic.autoNextIndex(current: i, count: queue.count, mode: mode, shuffled: shuffled)
        else { return }
        if target == i {
            player.seek(to: .zero)
            player.play()
            return
        }
        currentIndex = target
        playCurrent()
    }
}
```

- [ ] **Step 4: 删除 `YueYinTests/SmokeTests.swift`**

```bash
rm YueYinTests/SmokeTests.swift
```

- [ ] **Step 5: 推送 CI 验证 + Commit**

```bash
git add YueYin/Player YueYinTests
git commit -m "feat: PlayerCore 播放器(队列/模式/倍速/进度)+ 基础锁屏控制

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

Expected: Actions 绿(QueueLogicTests + PlayerCoreTests 通过)。

---

### Task 5: 首页 + 搜索界面(可点歌播放)

**Files:**
- Create: `YueYin/Views/Components/CoverImage.swift`
- Create: `YueYin/Views/Components/SongRow.swift`
- Create: `YueYin/Views/HomeView.swift`
- Create: `YueYin/Views/SearchView.swift`
- Modify: `YueYin/RootView.swift`(替换占位,TabView 两页 + 迷你播放栏占位)
- Test: 推 CI 编译绿 + 真机验证清单

**Interfaces:**
- Consumes: `PlayerCore.shared.play(_:startAt:)`、`Song.fromVideo(_:)`、`BiliClient.shared.hotMusic()/search(keyword:)`、`DurationFormat.format(seconds:)`
- Produces: `HomeView`、`SearchView`、`RootView`(TabView:首页/搜索)、`CoverImage(url: String?)`、`SongRow(song: Song)`

- [ ] **Step 1: 创建 `YueYin/Views/Components/CoverImage.swift`**

B 站图床需要 Referer 头,AsyncImage 不支持自定义 header,自写加载器 + 内存缓存:

```swift
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
```

- [ ] **Step 2: 创建 `YueYin/Views/Components/SongRow.swift`**

```swift
import SwiftUI
import YueYinCore

struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: song.coverUrl)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.body)
                    .lineLimit(1)
                Text(song.artist.isEmpty ? "B站" : song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if song.durationMs > 0 {
                Text(DurationFormat.format(seconds: song.durationMs / 1000))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
```

- [ ] **Step 3: 创建 `YueYin/Views/HomeView.swift`**

```swift
import SwiftUI
import YueYinCore

struct HomeView: View {
    @State private var videos: [BiliVideo] = []
    @State private var loading = true

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("加载中…")
                } else if videos.isEmpty {
                    Text("加载失败,下拉重试")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(videos) { v in
                            SongRow(song: Song.fromVideo(v))
                                .onTapGesture { play(v) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("悦音音乐")
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        videos = await BiliClient.shared.hotMusic()
        loading = false
    }

    private func play(_ v: BiliVideo) {
        let songs = videos.map(Song.fromVideo)
        guard let index = videos.firstIndex(of: v) else { return }
        PlayerCore.shared.play(songs, startAt: index)
    }
}
```

- [ ] **Step 4: 创建 `YueYin/Views/SearchView.swift`**

```swift
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
```

- [ ] **Step 5: 替换 `YueYin/RootView.swift` 为 TabView + 迷你播放栏**

```swift
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
```

(`MiniPlayerView` 与 `PlayerView` 在 Task 6 创建,本任务先推 CI 会因缺这两个类型编译失败——**先完成 Task 6 再推本任务**,或者本任务先把下面两行占位注释掉、Task 6 时放开。推荐:Task 5、6 连续完成后再一起推送。若分开推送,本任务临时把 MiniPlayerView/PlayerView 引用注释,Task 6 恢复。)

- [ ] **Step 6: 真机验证清单(需 Task 6 完成后才有完整 UI)**

1. 打开 App → 首页显示热门音乐列表 + 封面图 + 时长
2. 下拉刷新列表
3. 点任意一首 → 底部出现迷你播放栏,开始出声
4. 切到搜索页 → 搜"周杰伦" → 结果列表出现 → 点一首 → 播放

---

### Task 6: 迷你播放栏 + 播放页(进度/模式/倍速/队列)

**Files:**
- Create: `YueYin/Views/MiniPlayerView.swift`
- Create: `YueYin/Views/PlayerView.swift`
- Test: 推 CI 编译绿 + 真机验证清单

**Interfaces:**
- Consumes: `PlayerCore` 全部公开属性/方法(`jumpTo(_:)` 用于队列行点击)
- Produces: `MiniPlayerView`(RootView 已引用)、`PlayerView`(RootView fullScreenCover 已引用)

- [ ] **Step 1: 创建 `YueYin/Views/MiniPlayerView.swift`**

```swift
import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject private var player = PlayerCore.shared

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: player.currentSong?.coverUrl)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentSong?.name ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(player.currentSong?.artist ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 8)
    }
}
```

- [ ] **Step 2: 创建 `YueYin/Views/PlayerView.swift`**

```swift
import SwiftUI
import YueYinCore

struct PlayerView: View {
    @ObservedObject private var player = PlayerCore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showQueue = false
    @State private var showSpeedMenu = false
    @State private var dragTime: TimeInterval?

    var body: some View {
        VStack(spacing: 24) {
            // 顶部栏
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down").font(.title3)
                }
                Spacer()
                Text("正在播放").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Button { showQueue = true } label: {
                    Image(systemName: "list.bullet").font(.title3)
                }
            }
            .padding(.horizontal)

            CoverImage(url: player.currentSong?.coverUrl)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

            VStack(spacing: 6) {
                Text(player.currentSong?.name ?? "")
                    .font(.title2)
                    .bold()
                    .lineLimit(1)
                Text(player.currentSong?.artist ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // 进度条
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { dragTime ?? player.currentTime },
                        set: { dragTime = $0 }
                    ),
                    in: 0...max(player.duration, 1),
                    onEditingChanged: { editing in
                        if !editing, let t = dragTime {
                            player.seek(to: t)
                            dragTime = nil
                        }
                    }
                )
                HStack {
                    Text(DurationFormat.format(seconds: Int64(dragTime ?? player.currentTime)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(DurationFormat.format(seconds: Int64(player.duration)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)

            // 控制按钮行
            HStack(spacing: 36) {
                Button { player.cycleMode() } label: {
                    Image(systemName: modeIcon).font(.title3)
                }
                Button { player.previous() } label: {
                    Image(systemName: "backward.fill").font(.system(size: 30))
                }
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                Button { player.next() } label: {
                    Image(systemName: "forward.fill").font(.system(size: 30))
                }
                Button { showSpeedMenu = true } label: {
                    Text("\(player.speed, specifier: "%.1f")x").font(.subheadline).bold()
                }
            }
            .padding(.bottom, 8)

            Spacer()
        }
        .padding(.top, 8)
        .confirmationDialog("播放速度", isPresented: $showSpeedMenu, titleVisibility: .visible) {
            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { s in
                Button("\(s, specifier: "%.2f")x") { player.setSpeed(Float(s)) }
            }
        }
        .sheet(isPresented: $showQueue) { queueSheet }
    }

    private var modeIcon: String {
        switch player.mode {
        case .order: return "arrow.rectanglepath"
        case .shuffle: return "shuffle"
        case .repeatOne: return "repeat.1"
        }
    }

    private var queueSheet: some View {
        NavigationView {
            List {
                ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, song in
                    HStack {
                        SongRow(song: song)
                        if index == player.currentIndex {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { player.jumpTo(index) }
                }
            }
            .navigationTitle("播放队列 (\(player.queue.count))")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

- [ ] **Step 3: 推送 CI 验证(连同 Task 5 一起)+ Commit**

```bash
git add YueYin/Views
git commit -m "feat: 首页/搜索/播放页/迷你播放栏 UI

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

Expected: Actions 绿。

- [ ] **Step 4: 真机验证清单**

1. 首页热门列表 → 点歌播放(迷你栏出现、出声)
2. 播放页:封面、标题、进度条拖拽(松手跳转)、时间显示
3. 播放/暂停、上一首/下一首
4. 循环模式三态切换(列表循环 → 随机 → 单曲循环),图标变化
5. 倍速 0.5/0.75/1.0/1.25/1.5/2.0
6. 播放队列:打开队列 sheet → 点行切歌、当前曲目标记
7. 锁屏/控制中心:标题出现、播放暂停/上一首/下一首可遥控
8. App 切后台 → 音乐继续播放(阶段 1 已有 UIBackgroundModes=audio)
9. 迷你播放栏:播放/暂停按钮、点栏打开播放页、下拉收起

---

### Task 7: README + 真机安装与验证文档

**Files:**
- Create: `README.md`
- Test: 文档自检(按文档步骤走一遍)

- [ ] **Step 1: 创建 `README.md`**

```markdown
# 悦音音乐 iOS(iPhone 越狱版)

Android 版「悦音音乐」的 iOS 移植(原生 SwiftUI,功能全对齐规划中)。
纯 B 站数据源:搜索/热门/音频流播放,无服务器。

## 环境与工具链

- 开发机:Windows(无 Xcode)
- 构建:GitHub Actions(macos-14 免费 runner)云编译
- 工程生成:XcodeGen(`project.yml` → `YueYin.xcodeproj`,后者不提交 git)
- 纯逻辑:Core/ Swift Package(可 `cd Core && swift test`)

## 构建

1. 推代码到 GitHub(公开仓库)→ Actions 自动跑:
   - `swift test`(Core 包测试)
   - `xcodebuild test`(App 单测,模拟器)
   - `xcodebuild build`(Release,unsigned)→ 打包 `YueYin.ipa`
2. Actions 页 → `YueYin-unsigned-ipa` artifact → 下载

## 安装(越狱机)

1. 手机装好 **AppSync Unified**(Sileo 搜索安装)与 **Filza**
2. 隔空投送/浏览器下载 `YueYin.ipa`
3. Filza 打开 ipa → 安装 → 桌面出现「悦音音乐」

无越狱 Plan B:Sideloadly + 免费 Apple ID 侧载(每 7 天需重签)。

## 阶段 1 已实现

- 首页:B 站音乐排行榜 + 下拉刷新
- 搜索:B 站搜索(HTML 解析)
- 播放:流式播放(playurl)、队列/顺序/随机/单曲循环、倍速 0.5–2.0、进度拖拽
- 迷你播放栏 + 播放页 + 播放队列
- 后台播放(UIBackgroundModes=audio)+ 锁屏/控制中心基础控制

## 后续阶段

- 阶段 2:下载 m4a 到本地、歌词(QQ 接口 + 偏移)、本地音乐库、歌单/收藏/最近播放、设置
- 阶段 3:看板娘(Live2D/VRM/TTS)+ DeepSeek AI 推荐
- 阶段 4:打磨(锁屏封面/完整遥控、深色模式、定时关闭、错误态)

## 设计文档

- [设计规格](docs/superpowers/specs/2026-08-05-music-app-ios-design.md)
- [阶段 1 实施计划](docs/superpowers/plans/2026-08-05-music-app-ios-stage1.md)
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: README(构建/安装/阶段说明)

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

- [ ] **Step 3: 阶段 1 完结验收**

按 Task 6 Step 4 的 9 项真机清单逐项打勾;全过后把结果告知,进入阶段 2 计划(下载/歌词/本地库/歌单/设置)。
