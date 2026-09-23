import Foundation
import SwiftData

/// Contentor SwiftData partilhado entre a app, o widget e os App Intents.
/// Todos apontam ao mesmo ficheiro no App Group, por isso o widget vê
/// as gravações da app sem qualquer camada de cache pelo meio.
enum SharedContainer {
    static let shared: ModelContainer? = {
        guard AppGroup.isAvailable else { return nil }
        let schema = Schema([DailyEntry.self, WeeklySummary.self])
        let config = ModelConfiguration(
            "SalesTracker",
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier),
            cloudKitDatabase: .private(AppGroup.cloudKitContainer)
        )
        return try? ModelContainer(for: schema, configurations: config)
    }()
}
