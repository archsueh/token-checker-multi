import SwiftUI

struct ServiceSectionView: View {
    let title: String
    let brand: Service
    let result: Result<ServiceUsage, DomainError>?
    let loginAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: brand.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button {
                    loginAction()
                } label: {
                    Image(systemName: "person.badge.key")
                }
                .buttonStyle(.borderless)
                .help(L("Sign in to %@", title))
            }

            switch result {
            case .none:
                Text(L("Loading…"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            case .some(.success(let usage)):
                usageBlock(usage)
            case .some(.failure(let err)):
                errorBlock(err)
            }
        }
    }

    @ViewBuilder
    private func usageBlock(_ usage: ServiceUsage) -> some View {
        if let five = usage.fiveHour {
            limitRow(label: L("5 hours"), limit: five)
        } else {
            Text(L("No data for the 5-hour window"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }

        if let weekly = usage.weekly {
            secondaryRow(label: L("Weekly"), limit: weekly)
        }
        if let sonnet = usage.weeklySonnet {
            secondaryRow(label: L("Weekly (Sonnet)"), limit: sonnet)
        }
    }

    private func limitRow(label: String, limit: RateLimit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(limit.percent)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color(for: limit.utilization))
            }
            ProgressBarView(value: limit.utilization)
            Text(resetLabel(limit.resetsAt))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private func secondaryRow(label: String, limit: RateLimit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(limit.percent)%")
                    .font(.system(size: 11))
                    .foregroundStyle(color(for: limit.utilization))
            }
            Text(resetLabel(limit.resetsAt))
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }

    private func errorBlock(_ err: DomainError) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(L("Fetch failed"))
                    .font(.system(size: 12, weight: .medium))
            }
            Text(err.errorDescription ?? L("Unknown cause"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func color(for value: Double) -> Color {
        if value < 0.7 { return .green }
        if value < 0.85 { return .orange }
        return .red
    }

    private func resetLabel(_ date: Date) -> String {
        let now = Date()
        if date <= now { return L("Resets soon") }
        let interval = date.timeIntervalSince(now)
        let f = DateComponentsFormatter()
        f.unitsStyle = .abbreviated
        if interval >= 86400 {
            // Weekly/long window: show remaining days (feature: display days left until weekly token reset)
            f.allowedUnits = [.day, .hour]
        } else {
            f.allowedUnits = [.hour, .minute]
        }
        let rel = f.string(from: now, to: date) ?? "—"
        // 长周期（周重置）显示日期+时间，便于知道具体哪天重置；短周期只显示时间
        let dateStyle: DateFormatter.Style = (interval >= 86400 ? .short : .none)
        let absolute = DateFormatter.localizedString(from: date, dateStyle: dateStyle, timeStyle: .short)
        return L("%@ left (resets %@)", rel, absolute)
    }
}
