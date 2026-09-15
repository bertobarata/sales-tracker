import SwiftUI
import SwiftData

@main
struct SalesTrackerApp: App {
    private let container: ModelContainer

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    /// Tenta o contentor partilhado com sincronização iCloud. Se o iCloud não estiver
    /// disponível (sem sessão, sem entitlement em debug), cai para armazenamento local
    /// em vez de rebentar — a app é utilizável offline por definição.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([DailyEntry.self, WeeklySummary.self])

        #if DEBUG
        // Capturas de ecrã da App Store: base em memória, semeada, sem tocar
        // na base real nem no iCloud. Nunca existe numa build de distribuição.
        if DemoData.isRequested {
            let demoConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let container = try? ModelContainer(for: schema, configurations: demoConfig) {
                DemoData.seed(into: ModelContext(container))
                return container
            }
        }
        #endif

        // O App Group só existe em builds assinados. Sem ele, `groupContainer:`
        // não falha — rebenta — por isso nem se tenta.
        if AppGroup.isAvailable {
            let cloudConfig = ModelConfiguration(
                "SalesTracker",
                schema: schema,
                groupContainer: .identifier(AppGroup.identifier),
                cloudKitDatabase: .private(AppGroup.cloudKitContainer)
            )
            if let container = try? ModelContainer(for: schema, configurations: cloudConfig) {
                return container
            }

            let localGroupConfig = ModelConfiguration(
                "SalesTracker",
                schema: schema,
                groupContainer: .identifier(AppGroup.identifier),
                cloudKitDatabase: .none
            )
            if let container = try? ModelContainer(for: schema, configurations: localGroupConfig) {
                return container
            }
        }

        // Sem App Group: base local no contentor da própria app. O widget não a vê,
        // mas a app continua a gravar e a ler normalmente.
        let localConfig = ModelConfiguration("SalesTracker", schema: schema, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: localConfig) {
            return container
        }

        // Último recurso: memória. Perde-se persistência, mas a app abre.
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: memoryConfig)
    }
}
