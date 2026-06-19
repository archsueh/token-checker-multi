import SwiftUI
import AppKit

struct UsagePopoverView: View {
    @Bindable var viewModel: UsageViewModel
    @ObservedObject var launchAtLogin: LaunchAtLoginStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            // 動的に表示
            let services: [Service] = [.claude, .codex, .grok]
            ForEach(Array(services.enumerated()), id: \.offset) { index, service in
                if index > 0 { Divider() }

                ServiceSectionView(
                    title: service.displayName,
                    brand: service,
                    result: viewModel.snapshot.results[service],
                    loginAction: { viewModel.openLogin(for: service) }
                )
            }

            Divider()

            // 代码统计
            CodeStatsPicker(service: viewModel.codeStatsService)

            Divider()

            settingsBlock
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 360)
    }

    private var header: some View {
        HStack {
            Text("Token Checker")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
    }

    private var settingsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L("Refresh interval"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $viewModel.pollingInterval) {
                    ForEach(PollingInterval.allCases) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            HStack {
                Text(L("Launch at login"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { _ in launchAtLogin.toggle() }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
        }
    }

    private var footer: some View {
        HStack {
            if viewModel.snapshot.fetchedAt > .distantPast {
                Text(L("Updated: %@", DateFormatter.localizedString(from: viewModel.snapshot.fetchedAt, dateStyle: .none, timeStyle: .short)))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                Task { await viewModel.refresh() }
            } label: {
                if viewModel.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderless)
            .help(L("Refresh now"))

            Button(L("Quit")) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
    }
}
