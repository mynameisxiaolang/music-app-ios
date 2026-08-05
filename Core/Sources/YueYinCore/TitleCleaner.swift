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
