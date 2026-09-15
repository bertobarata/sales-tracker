import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: Screen = .hoje

    /// Nome próprio para não tapar o `Tab` do SwiftUI usado abaixo.
    enum Screen: Hashable {
        case hoje, semana, relatorio, tendencias
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Hoje", systemImage: "square.and.pencil", value: Screen.hoje) {
                DailyInputView()
            }
            Tab("Semana", systemImage: "chart.bar.fill", value: Screen.semana) {
                DashboardView()
            }
            Tab("Relatório", systemImage: "doc.text.fill", value: Screen.relatorio) {
                WeeklyReportView()
            }
            Tab("Tendências", systemImage: "chart.xyaxis.line", value: Screen.tendencias) {
                TrendsView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshReminders() }
        }
    }

    private func refreshReminders() async {
        let store = EntryStore(context)
        let horizon = WeekMath.week(offsetBy: 0).days + WeekMath.week(offsetBy: 1).days
        let filled = Set(
            horizon
                .compactMap { store.entry(for: $0) }
                .filter { !$0.isEmpty }
                .map(\.dayKey)
        )
        await ReminderScheduler.reschedule(settings: .current, filledDayKeys: filled)
    }
}
