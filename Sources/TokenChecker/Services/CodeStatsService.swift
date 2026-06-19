import Foundation
import OSLog

/// 负责调用 tokei 并管理缓存
@MainActor
@Observable
final class CodeStatsService {
    private let logger = Logger(subsystem: "com.token-checker.app", category: "CodeStatsService")

    /// 缓存键：路径 → (报告, 过期时间)
    private var cache: [String: (CodeStatsReport, Date)] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 分钟

    /// tokei 二进制在 bundle 中的相对路径
    private let binaryName = "tokei"

    /// 运行 tokei 统计指定路径
    /// - Parameter path: 要统计的文件或目录路径
    /// - Returns: 解析后的报告，失败抛出 CodeStatsError
    func stats(for path: String) async throws -> CodeStatsReport {
        let absPath = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: absPath) else {
            throw CodeStatsError.pathNotFound
        }

        // 缓存命中
        if let (report, expiry) = cache[absPath], expiry > Date() {
            logger.debug("Cache hit for \(absPath)")
            return report
        }

        // 定位 tokei 二进制
        guard let binaryURL = Bundle.main.url(forResource: binaryName, withExtension: nil, subdirectory: "bin") else {
            // 调试模式：尝试 PATH 中的 tokei（开发时便利）
            logger.warning("Bundle binary not found, trying PATH...")
            return try await runTokei(["--output", "json", absPath], usePath: true)
        }

        logger.info("Running tokei on \(absPath)")
        return try await runTokei([binaryURL.path, "--output", "json", absPath], usePath: false)
    }

    /// 执行 tokei 并解析输出
    private func runTokei(_ args: [String], usePath: Bool) async throws -> CodeStatsReport {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: usePath ? "/usr/bin/env" : args[0])
        process.arguments = usePath ? ["tokei", "--output", "json", args[2]] : Array(args.dropFirst())

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw CodeStatsError.processFailed("launch failed: \(error.localizedDescription)")
        }

        guard process.terminationStatus == 0 else {
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8) ?? "unknown error"
            throw CodeStatsError.processFailed("exit \(process.terminationStatus): \(errMsg)")
        }

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        do {
            let report = try CodeStatsReport.parse(from: outData)
            cache[args.last ?? ""] = (report, Date().addingTimeInterval(cacheTTL))
            return report
        } catch {
            throw CodeStatsError.invalidJSON
        }
    }

    /// 清理过期缓存
    func cleanupCache() {
        let now = Date()
        cache = cache.filter { $0.value.1 > now }
    }
}