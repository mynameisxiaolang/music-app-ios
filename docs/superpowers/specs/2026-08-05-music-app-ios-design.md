# 悦音音乐 iOS 版 — 设计文档

- 日期:2026-08-05
- 状态:已获用户批准(分三节确认)
- 参照:Android 原版 `E:\trae_workspace\music-app`(Kotlin + Compose,功能完整)

## 1. 背景与目标

把 Android 音乐播放器「悦音音乐」移植为 iPhone 版,功能**全对齐**(搜索/下载/播放/歌词/歌单/收藏/本地音乐/后台播放/看板娘/AI 推荐/设置)。

关键环境约束:

- **用户只有 Windows**,无 Mac → 无法本地跑 Xcode
- **用户 iPhone 已越狱**(palera1n,iOS 16 及以下,A11 或更老芯片)→ 可用 AppSync Unified 安装未签名 .ipa,绕开 Apple 开发者账号和 7 天重签
- **构建方式**:GitHub Actions 免费 macOS runner 云端编译 → 产物 unsigned .ipa → 手机 Filza 安装

## 2. 技术选型

| 模块 | iOS 方案 | 对应 Android 原版 |
|---|---|---|
| UI | SwiftUI(iOS 15.0+ 部署目标) | Jetpack Compose |
| 播放 | AVPlayer + AVAudioSession(.playback) | Media3 ExoPlayer |
| 锁屏/控制中心 | MPNowPlayingInfoCenter + MPRemoteCommandCenter | MediaSession 通知栏 |
| 后台模式 | Info.plist `UIBackgroundModes = audio`(未签名 App 同样生效) | 前台服务 |
| 网络 | URLSession(UA/Referer 头) | OkHttp |
| 存储 | GRDB(SQLite),六张表:收藏/历史/歌单/下载/歌词缓存/歌词偏移 | Room |
| 下载 | URLSession 后台下载任务(App 退后台继续),m4a 存沙盒 | OkHttp 流式 + MediaStore |
| 看板娘 | WKWebView + GCDWebServer 本地服务器 + Live2D/VRM 资产**原样拷贝自 Android** | WebView + LocalAssetServer |
| TTS | AVSpeechSynthesizer | TextToSpeech |
| AI 推荐 | DeepSeek API(模型 deepseek-v4-flash;**key 经 GitHub Actions secret `DEEPSEEK_API_KEY` 注入,源码不含真实 key**) | DeepSeekApi.kt |
| 定时关闭 | 播放器内定时器(关闭/10/15/30/60 分钟) | 同 |
| 本地音乐 | MPMediaLibrary 权限 + MPMediaQuery 扫描系统音乐库 | MediaStore |

## 3. 项目架构(镜像 Android 结构)

```
YueYinIOS/
├── YueYinApp.swift            # App 入口
├── Models/                    # Song / BiliVideo / Playlist / LyricLine / LyricOffset
├── Networking/                # BiliClient(搜索+热门) / QQLyricClient / DeepSeekClient
├── Repositories/              # BiliRepository / LyricRepository / DownloadRepository / RecommendationRepository
├── Player/                    # PlayerCore(ObservableObject 单例) / NowPlayingCenter
├── Persistence/               # Database(GRDB) / SettingsStore
├── Views/                     # Home / Search / Player / Queue / Library / Playlists / Favorites / History / Settings
├── Mascot/                    # MascotView(WKWebView) / AssetServer(GCDWebServer) / MascotSpeaker
└── Resources/                 # live2d/ + vrm/ 资产(从 Android app/src/main/assets 拷贝)
```

核心设计:

- **PlayerCore**:ObservableObject 单例,持有 AVPlayer + 播放队列 + 循环/随机/倍速/定时关闭状态,通过 `@Published` 发布状态(对应 Android 的 StateFlow 语义)
- **数据流与 Android 完全一致**:搜索 → 下载 m4a 到沙盒 → 播放本地文件;歌单/收藏存 songId + localPath;歌词按歌曲 key(localPath)缓存并持久化偏移;DeepSeek 分析歌单+收藏 → 推荐 10 首 → B 站搜索下载播放
- **看板娘桥接照搬 Android 方案**:单击说话(TTS 台词与气泡字幕一致,JS `showTip` 注入),300ms 双击窗口触发 AI 推荐;模型切换走设置;15s 加载超时兜底 NativeMascot 透出;Live2D 用 settings 文件加载(不是 model.moc),渲染完成信号用 draw 钩子——这些坑 Android 版已趟平,直接照抄

## 4. 功能映射

| 功能 | iOS 实现 | 注意点 |
|---|---|---|
| 首页热门 | B 站 ranking API(rid=3)JSON | 同 Android |
| 搜索 | search.bilibili.com HTML 解析 | 同 Android,解析容错返回空列表 |
| 下载 m4a | URLSession 后台下载任务 + 下载管理页实时进度 | iOS 优势:后台下载不中断;已下载自动播放 |
| 播放 | AVPlayer + 队列/顺序/随机/单曲循环/倍速/进度拖拽 | 逻辑照搬 |
| 歌词 | QQ 音乐接口 + 滚动/翻译/点击跳转/±3s 偏移(100ms 档)持久化 | 同 Android |
| 本地音乐 | MPMediaLibrary + MPMediaQuery | 需 NSAppleMusicUsageDescription |
| 歌单/收藏/最近播放 | GRDB 表 | 同 Android 逻辑 |
| 后台播放+锁屏 | UIBackgroundModes=audio + MPNowPlayingInfoCenter,锁屏上一首/播放暂停/下一首/进度 | 未签名 App 可用 |
| 看板娘 | WKWebView + GCDWebServer;4 个 Live2D 角色 + VRM 3D | 资产零改动 |
| AI 推荐 | DeepSeek API | key 内嵌(个人学习可接受) |
| 设置 | 深色模式/看板娘开关/模型切换/语音开关/定时关闭 | 同 Android |
| 封面 | URLSession + URLCache,带 `Referer: https://www.bilibili.com/` | 同 Android 踩过的坑 |

## 5. 构建与安装流水线

```
本地 Windows 写 Swift 代码
  → git push GitHub 公开仓库(免费 macOS runner)
  → GitHub Actions: xcodebuild -configuration Release CODE_SIGNING_ALLOWED=NO
    → 打包 unsigned .app → zip .ipa → 上传 Artifacts
  → 手机下载 .ipa(浏览器/隔空投送)→ Filza 打开 → AppSync 放行安装
  → 真机测试 → 迭代:改代码 → push → 等 CI 出包
```

- 需用户注册免费 GitHub 账号(若没有)
- CI 同时运行 `swift test` 单元测试
- 依赖:GCDWebServer 等通过 SPM 在 CI 上正常拉取

## 6. 实施阶段划分(供实施计划拆分)

全功能移植体量大,实施按四个阶段推进,每阶段产出可安装验证的版本:

1. **阶段 1 — 核心骨架**:Xcode 工程 + GitHub Actions 流水线(先出能装机的空壳 ipa)+ Models + Networking(B 站搜索/热门)+ PlayerCore + 搜索/首页/播放页
2. **阶段 2 — 数据与库**:GRDB 六表 + 下载管理 + 歌词 + 本地音乐库 + 歌单/收藏/最近播放 + 设置
3. **阶段 3 — 看板娘**:资源拷贝 + GCDWebServer + WKWebView 桥接 + TTS + 双击 AI 推荐(DeepSeek)
4. **阶段 4 — 打磨与真机验证**:锁屏控制完善、深色模式、定时关闭、错误态、真机全流程回归

## 7. 错误处理

- 网络失败:空态 + "加载失败"重试;下载失败清理半成品 + 提示
- B 站 HTML 变更:解析失败返回空列表,不崩溃
- 歌词匹配失败:"暂无歌词";偏移标签仅在有歌词时显示
- DeepSeek 失败:推荐对话框错误提示,不影响其他功能
- 看板娘超时:15s 兜底 + 重试
- 歌单旧数据无本地路径:提示"歌曲不可播"(Android 遗留事项直接带上修复)

## 8. 测试

- CI `swift test` 单元测试:LRC 解析、时间格式化、HTML 解析器(用本地 fixture 不依赖网络)
- UI 验证靠真机迭代:装进手机 → 日志 + 截图反馈
- 首次安装确认 AppSync Unified 与 Filza 可用;Plan B:Sideloadly + 免费 Apple ID 免越狱侧载(7 天重签)

## 9. 风险与对策

1. palera1n 环境 iOS 16 rootless 下 AppSync Unified 可用( Sileo 安装);装不上用 Plan B 侧载
2. CI 首次构建慢(拉依赖),属正常
3. ATS:本地 127.0.0.1 需 `NSAllowsLocalNetworking`,B 站 https 不受影响
4. B 站接口风控与 Android 版同风险,个人学习用途
5. DeepSeek key 经 CI secret 注入 .ipa,可被反编译提取(个人学习可接受,上线需服务端代理);仓库源码与 git 历史不落 key
