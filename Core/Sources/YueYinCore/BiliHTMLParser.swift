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
