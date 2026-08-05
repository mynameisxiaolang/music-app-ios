# 伟大音乐 iOS(iPhone 越狱版)

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
3. Filza 打开 ipa → 安装 → 桌面出现「伟大音乐」

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
