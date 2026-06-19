import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class UsageViewModel {
    /// サービス → Provider のマップ（4サービス以上も柔軟に対応）
    private nonisolated let providers: [Service: any UsageProvider]
    let codeStatsService = CodeStatsService()

    var snapshot: UsageSnapshot = .empty
    var isLoading: Bool = false
    var pollingInterval: PollingInterval {
        didSet { persistInterval() }
    }

    init(providers: [Service: any UsageProvider] = [
        .claude: ClaudeUsageProvider(),
        .codex: CodexUsageProvider(),
        .grok: GrokUsageProvider()
    ]) {
        self.providers = providers
        self.pollingInterval = Self.loadPersistedInterval()
    }

    /// `task(id: pollingInterval)` から駆動するメインループ。
    func runPollingLoop() async {
        await refresh()
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: UInt64(pollingInterval.seconds * 1_000_000_000))
            } catch {
                return
            }
            await refresh()
        }
    }

    /// アプリ終了時に子プロセスや永続接続を解放するためのクロージャを返す。
    nonisolated func makeShutdownHandler() -> @Sendable () async -> Void {
        let provs = providers
        return {
            for (_, p) in provs {
                await p.shutdown()
            }
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        var results: [Service: Result<ServiceUsage, DomainError>] = [:]

        for (service, provider) in providers {
            results[service] = await fetch(for: service, provider: provider)
        }

        snapshot = UsageSnapshot(results: results, fetchedAt: Date())
    }

    private func fetch(for service: Service, provider: any UsageProvider) async -> Result<ServiceUsage, DomainError> {
        do {
            let res = try await provider.fetch()
            Logger.service(for: service).info("fetch success")
            return .success(res)
        } catch let err as DomainError {
            Logger.service(for: service).error("fetch failed: \(err.localizedDescription, privacy: .public)")
            return .failure(err)
        } catch {
            let netErr = DomainError.network(error.localizedDescription)
            Logger.service(for: service).error("fetch failed: \(netErr.localizedDescription, privacy: .public)")
            return .failure(netErr)
        }
    }

    // 旧 fetchClaude / fetchCodex は refresh() 内の動的ループに置き換え済み

    // MARK: - ログインボタン

    /// どのサービスを再ログインするかは enum 型で表現する。
    /// 任意文字列を AppleScript に渡せないようにしてインジェクションを「型として」不能にする。
    enum LoginTarget {
        case claude
        case codex
        case grok

        var command: String {
            switch self {
            case .claude: return "claude login"
            case .codex:  return "codex login"
            case .grok:   return "~/.grok/bin/grok login || echo 'grok login command not confirmed yet'"
            }
        }

        var displayName: String {
            switch self {
            case .claude: return "Claude Code"
            case .codex:  return "Codex"
            case .grok:   return "Grok Build"
            }
        }
    }

    func openLogin(for service: Service) {
        let target: LoginTarget = switch service {
        case .claude: .claude
        case .codex:  .codex
        case .grok:   .grok
        }
        spawnLogin(target)
    }

    private func spawnLogin(_ target: LoginTarget) {
        let script = """
        tell application "Terminal"
            activate
            do script "\(target.command)"
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        do { try process.run() } catch {
            Logger.ui.error("login spawn failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 永続化

    private static let intervalKey = "pollingInterval"

    private static func loadPersistedInterval() -> PollingInterval {
        let raw = UserDefaults.standard.integer(forKey: intervalKey)
        return PollingInterval(rawValue: raw) ?? .default
    }

    private func persistInterval() {
        UserDefaults.standard.set(pollingInterval.rawValue, forKey: Self.intervalKey)
    }
}
