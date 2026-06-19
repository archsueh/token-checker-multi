import SwiftUI

/// 代码统计展示视图
struct CodeStatsView: View {
    let report: CodeStatsReport
    let targetPath: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            Divider()

            // 总计行
            totalRow(report.total)

            Divider()

            // 按语言排序（代码行数降序）
            let sorted = report.languages.sorted { $0.code > $1.code }
            ForEach(sorted.prefix(8)) { lang in
                languageRow(lang)
            }

            if sorted.count > 8 {
                Text("… and \(sorted.count - 8) more languages")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.blue)
            Text("Code Statistics")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if let path = targetPath {
                Text((path as NSString).lastPathComponent)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 160)
            }
        }
    }

    private func totalRow(_ total: LanguageStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Total")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(total.files) files • \(formatNumber(total.lines)) lines")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                statPill(label: "Code", value: total.code, color: .green, total: total.lines)
                statPill(label: "Comments", value: total.comments, color: .orange, total: total.lines)
                statPill(label: "Blanks", value: total.blanks, color: .gray, total: total.lines)
            }
        }
    }

    private func languageRow(_ lang: LanguageStats) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(colorForLanguage(lang.name))
                .frame(width: 8, height: 8)
            Text(lang.name)
                .font(.system(size: 11))
                .foregroundStyle(.primary)
                .frame(width: 90, alignment: .leading)
            Spacer()
            Text("\(formatNumber(lang.code))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.green)
            Text("(\(Int(lang.codePercent * 100))%)")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private func statPill(label: String, value: Int, color: Color, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text("\(formatNumber(value))")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.15))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geo.size.width * (total > 0 ? CGFloat(value) / CGFloat(total) : 0), height: 4)
            }
            .frame(height: 4)
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = ","
        return fmt.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func colorForLanguage(_ name: String) -> Color {
        // 简单哈希生成稳定颜色
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.85)
    }
}

/// 交互式目录选择 + 统计触发
struct CodeStatsPicker: View {
    @Bindable var service: CodeStatsService
    @State private var currentReport: CodeStatsReport?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPath: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Code Statistics")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }

            HStack(spacing: 8) {
                TextField("Drop folder or enter path…", text: $selectedPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity)
                    .onSubmit { Task { await runStats() } }

                Button("Run") { Task { await runStats() } }
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(selectedPath.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }

            if let err = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(err).font(.system(size: 10)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(6)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let report = currentReport {
                CodeStatsView(report: report, targetPath: selectedPath)
            }
        }
        .padding(12)
    }

    private func runStats() async {
        let path = selectedPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentReport = try await service.stats(for: path)
        } catch let err as CodeStatsError {
            errorMessage = err.errorDescription
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
    }
}