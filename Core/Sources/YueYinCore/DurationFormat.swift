import Foundation

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
