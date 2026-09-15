import Foundation

/// As nove métricas registadas por dia. A ordem do `allCases` é a ordem
/// de apresentação no formulário diário e no resumo.
enum Metric: String, CaseIterable, Identifiable, Sendable {
    case contactos
    case primeirasReunioesMarcadas
    case segundasReunioesMarcadas
    case terceirasReunioesMarcadas
    case primeirasReunioesRealizadas
    case segundasReunioesRealizadas
    case terceirasReunioesRealizadas
    case pesquisas
    case referencias

    var id: String { rawValue }

    var label: String {
        switch self {
        case .contactos: "Contactos efetuados"
        case .primeirasReunioesMarcadas: "1as reuniões marcadas"
        case .segundasReunioesMarcadas: "2as reuniões marcadas"
        case .terceirasReunioesMarcadas: "3as reuniões marcadas"
        case .primeirasReunioesRealizadas: "1as reuniões realizadas"
        case .segundasReunioesRealizadas: "2as reuniões realizadas"
        case .terceirasReunioesRealizadas: "3as reuniões realizadas"
        case .pesquisas: "Pesquisas efetuadas"
        case .referencias: "Referências obtidas"
        }
    }

    var shortLabel: String {
        switch self {
        case .contactos: "Contactos"
        case .primeirasReunioesMarcadas: "1as marc."
        case .segundasReunioesMarcadas: "2as marc."
        case .terceirasReunioesMarcadas: "3as marc."
        case .primeirasReunioesRealizadas: "1.ª R."
        case .segundasReunioesRealizadas: "2.ª R."
        case .terceirasReunioesRealizadas: "3.ª R."
        case .pesquisas: "Pesquisas"
        case .referencias: "Refs."
        }
    }

    /// Cabeçalho usado na exportação CSV — igual ao da folha Excel da PWA.
    var csvHeader: String {
        switch self {
        case .contactos: "Contactos"
        case .primeirasReunioesMarcadas: "1as Marcadas"
        case .segundasReunioesMarcadas: "2as Marcadas"
        case .terceirasReunioesMarcadas: "3as Marcadas"
        case .primeirasReunioesRealizadas: "1as Realizadas"
        case .segundasReunioesRealizadas: "2as Realizadas"
        case .terceirasReunioesRealizadas: "3as Realizadas"
        case .pesquisas: "Pesquisas"
        case .referencias: "Referências"
        }
    }
}

/// Totais agregados de uma semana, indexados por `Metric`.
struct MetricTotals: Equatable, Sendable {
    private var storage: [Metric: Int]

    init(_ storage: [Metric: Int] = [:]) {
        self.storage = storage
    }

    subscript(metric: Metric) -> Int {
        get { storage[metric] ?? 0 }
        set { storage[metric] = newValue }
    }

    static func summing(_ entries: [DailyEntry]) -> MetricTotals {
        var totals = MetricTotals()
        for metric in Metric.allCases {
            totals[metric] = entries.reduce(0) { $0 + $1[metric] }
        }
        return totals
    }
}
