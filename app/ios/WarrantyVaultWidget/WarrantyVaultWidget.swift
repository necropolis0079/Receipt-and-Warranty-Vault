// WarrantyVaultWidget.swift
// iOS WidgetKit extension for Warranty Vault
//
// NOTE: This file is a ready-to-integrate placeholder.
// To enable on iOS:
// 1. Open ios/Runner.xcworkspace in Xcode on a Mac
// 2. File > New > Target > Widget Extension > "WarrantyVaultWidget"
// 3. Set App Group to "group.io.cronos.warrantyvault" on both Runner and Widget targets
// 4. Replace the generated Swift code with this file
// 5. Build and run

import WidgetKit
import SwiftUI

// MARK: - Data

struct WarrantyVaultEntry: TimelineEntry {
    let date: Date
    let statsText: String
}

// MARK: - Provider

struct WarrantyVaultProvider: TimelineProvider {
    private let appGroupId = "group.io.cronos.warrantyvault"
    private let statsKey = "stats_text"
    private let defaultStats = "0 receipts · 0 active warranties"

    func placeholder(in context: Context) -> WarrantyVaultEntry {
        WarrantyVaultEntry(date: Date(), statsText: defaultStats)
    }

    func getSnapshot(in context: Context, completion: @escaping (WarrantyVaultEntry) -> Void) {
        let entry = WarrantyVaultEntry(date: Date(), statsText: readStats())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WarrantyVaultEntry>) -> Void) {
        let entry = WarrantyVaultEntry(date: Date(), statsText: readStats())
        // Refresh every 24 hours; primary updates come from Flutter via HomeWidget.updateWidget()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readStats() -> String {
        let defaults = UserDefaults(suiteName: appGroupId)
        return defaults?.string(forKey: statsKey) ?? defaultStats
    }
}

// MARK: - Widget View

struct WarrantyVaultWidgetView: View {
    var entry: WarrantyVaultEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("Warranty Vault")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.176, green: 0.353, blue: 0.239)) // #2D5A3D

            Text(entry.statsText)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.216, green: 0.255, blue: 0.318)) // #374151

            Link(destination: URL(string: "warrantyvault://capture?source=camera")!) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(red: 0.176, green: 0.353, blue: 0.239)) // #2D5A3D
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.980, green: 0.969, blue: 0.949)) // #FAF7F2
    }
}

// MARK: - Widget Configuration

@main
struct WarrantyVaultWidget: Widget {
    let kind: String = "WarrantyVaultWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WarrantyVaultProvider()) { entry in
            WarrantyVaultWidgetView(entry: entry)
        }
        .configurationDisplayName("Warranty Vault")
        .description("Quick capture and warranty stats at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
