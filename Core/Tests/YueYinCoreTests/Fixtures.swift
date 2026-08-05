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
