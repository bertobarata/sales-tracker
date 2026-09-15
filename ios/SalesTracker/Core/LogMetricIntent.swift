import AppIntents
import SwiftData
import WidgetKit


/// Incrementa uma métrica do dia de hoje. Serve o Siri, os Atalhos, o botão
/// do widget e o control do Centro de Controlo — todos chamam este intent.
struct LogMetricIntent: AppIntent {
    static let title: LocalizedStringResource = "Registar métrica"
    static let description = IntentDescription("Soma ao registo de hoje uma reunião, contacto ou referência.")
    static let openAppWhenRun = false

    @Parameter(title: "Métrica")
    var metric: MetricAppEnum

    @Parameter(title: "Quantidade", default: 1)
    var amount: Int

    init() {}

    init(metric: MetricAppEnum, amount: Int = 1) {
        self.metric = metric
        self.amount = amount
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = SharedContainer.shared else {
            throw LogMetricError.storeUnavailable
        }
        let store = EntryStore(container.mainContext)
        let entry = store.entryOrCreate(for: .now)
        let target = metric.metric
        entry[target] = entry[target] + max(1, amount)
        store.save()
        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: "\(target.label): \(entry[target]) hoje.")
    }
}

enum LogMetricError: Error, CustomLocalizedStringResourceConvertible {
    case storeUnavailable

    var localizedStringResource: LocalizedStringResource {
        "Não foi possível aceder aos dados. Abre a app uma vez e tenta de novo."
    }
}

/// Espelho de `Metric` exposto ao sistema de intents. Fica separado do enum
/// do domínio para o vocabulário do Siri poder mudar sem mexer no modelo.
enum MetricAppEnum: String, AppEnum {
    case contactos
    case primeiraReuniao
    case segundaReuniao
    case terceiraReuniao
    case pesquisa
    case referencia

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Métrica")

    static let caseDisplayRepresentations: [MetricAppEnum: DisplayRepresentation] = [
        .contactos: "Contacto",
        .primeiraReuniao: "1.ª reunião realizada",
        .segundaReuniao: "2.ª reunião realizada",
        .terceiraReuniao: "3.ª reunião realizada",
        .pesquisa: "Pesquisa",
        .referencia: "Referência",
    ]

    var metric: Metric {
        switch self {
        case .contactos: .contactos
        case .primeiraReuniao: .primeirasReunioesRealizadas
        case .segundaReuniao: .segundasReunioesRealizadas
        case .terceiraReuniao: .terceirasReunioesRealizadas
        case .pesquisa: .pesquisas
        case .referencia: .referencias
        }
    }
}

struct SalesTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMetricIntent(metric: .primeiraReuniao),
            phrases: [
                "Registar primeira reunião no \(.applicationName)",
                "Marcar reunião no \(.applicationName)",
            ],
            shortTitle: "Registar 1.ª reunião",
            systemImageName: "person.2.fill"
        )
        AppShortcut(
            intent: LogMetricIntent(metric: .contactos),
            phrases: [
                "Registar contacto no \(.applicationName)",
            ],
            shortTitle: "Registar contacto",
            systemImageName: "phone.fill"
        )
    }
}
