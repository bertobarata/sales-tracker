import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: Screen = .painel

    @AppStorage(SettingsKey.onboardingCompletedVersion, store: .shared)
    private var onboardingCompletedVersion = 0

    @AppStorage(SettingsKey.appearance, store: .shared)
    private var appearance = AppAppearance.system.rawValue

    /// Nome próprio para não tapar o `Tab` do SwiftUI usado abaixo.
    enum Screen: Hashable {
        case painel, hoje, semana, relatorio, tendencias
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Painel", systemImage: "gauge.with.dots.needle.50percent", value: Screen.painel) {
                FunnelView()
            }
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
        .fullScreenCover(isPresented: Binding(
            get: { onboardingCompletedVersion < SettingsKey.onboardingVersion },
            set: { _ in }
        )) {
            OnboardingView()
        }
        // Fica no topo para apanhar também a introdução, que é apresentada por cima.
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await ReminderScheduler.refresh(using: context) }
        }
    }


}
