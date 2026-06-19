import Foundation

/// tokei 返回的单语言统计结构
struct LanguageStats: Codable, Equatable, Sendable, Identifiable {
    let name: String
    let files: Int
    let lines: Int
    let code: Int
    let comments: Int
    let blanks: Int

    var id: String { name }

    var codePercent: Double {
        guard lines > 0 else { return 0 }
        return Double(code) / Double(lines)
    }
    var commentPercent: Double {
        guard lines > 0 else { return 0 }
        return Double(comments) / Double(lines)
    }
    var blankPercent: Double {
        guard lines > 0 else { return 0 }
        return Double(blanks) / Double(lines)
    }
}

/// tokei 完整报告（--output json）
struct CodeStatsReport: Codable, Equatable, Sendable {
    let languages: [LanguageStats]
    let total: LanguageStats
    let timestamp: Date

    init(languages: [LanguageStats], total: LanguageStats, timestamp: Date = Date()) {
        self.languages = languages
        self.total = total
        self.timestamp = timestamp
    }

    /// 入口：仅 languages 存在时（--output json 有时只返回数组）
    static func parse(from json: Data) throws -> CodeStatsReport {
        // 尝试作为顶层对象解析
        if let report = try? JSONDecoder().decode(CodeStatsReport.self, from: json) {
            return report
        }
        // 兼容：某些版本直接返回 [LanguageStats]
        if let langs = try? JSONDecoder().decode([LanguageStats].self, from: json) {
            return CodeStatsReport(languages: langs, total: CodeStatsReport.computeTotal(langs))
        }
        // 兼容：某些版本返回包含 languages/total/timestamp 的对象
        if let raw = try? JSONDecoder().decode(_RawReport.self, from: json) {
            return fromRaw(raw)
        }
        throw CodeStatsError.invalidJSON
    }

    struct _RawReport: Codable {
        let languages: [LanguageStats]
        let total: LanguageStats?
        let timestamp: Date?
    }

    private static func fromRaw(_ raw: _RawReport) -> CodeStatsReport {
        let total = raw.total ?? computeTotal(raw.languages)
        return CodeStatsReport(languages: raw.languages, total: total, timestamp: raw.timestamp ?? Date())
    }

    private static func computeTotal(_ languages: [LanguageStats]) -> LanguageStats {
        let totalFiles = languages.reduce(0) { $0 + $1.files }
        let totalLines = languages.reduce(0) { $0 + $1.lines }
        let totalCode = languages.reduce(0) { $0 + $1.code }
        let totalComments = languages.reduce(0) { $0 + $1.comments }
        let totalBlanks = languages.reduce(0) { $0 + $1.blanks }
        return LanguageStats(
            name: "Total",
            files: totalFiles,
            lines: totalLines,
            code: totalCode,
            comments: totalComments,
            blanks: totalBlanks
        )
    }
}

enum CodeStatsError: LocalizedError, Equatable, Sendable {
    case binaryNotFound
    case processFailed(String)
    case invalidJSON
    case pathNotFound

    var errorDescription: String? {
        switch self {
        case .binaryNotFound: return "tokei binary not found in bundle"
        case .processFailed(let msg): return "tokei failed: \(msg)"
        case .invalidJSON: return "Failed to parse tokei JSON output"
        case .pathNotFound: return "Target path does not exist"
        }
    }
}