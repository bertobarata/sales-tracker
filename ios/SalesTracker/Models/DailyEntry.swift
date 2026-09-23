import Foundation
import SwiftData

/// Registo de um dia. `dayKey` ("yyyy-MM-dd") é a identidade lógica e mantém
/// o mesmo formato usado pela PWA, para migrações e exportações continuarem a bater certo.
///
/// CloudKit exige valor por omissão em todas as propriedades e proíbe
/// `@Attribute(.unique)`, por isso a deduplicação por dia é feita no `EntryStore`.
@Model
final class DailyEntry {
    var dayKey: String = ""
    var date: Date = Date.distantPast

    var contactos: Int = 0
    var primeirasReunioesMarcadas: Int = 0
    var segundasReunioesMarcadas: Int = 0
    var terceirasReunioesMarcadas: Int = 0
    var primeirasReunioesRealizadas: Int = 0
    var segundasReunioesRealizadas: Int = 0
    var terceirasReunioesRealizadas: Int = 0
    var pesquisas: Int = 0
    var referencias: Int = 0

    /// Ids das tarefas da checklist concluídas neste dia, separados por vírgula.
    /// Texto em vez de coleção de propósito: o CloudKit não aceita `@Attribute` de
    /// unicidade nem lida bem com arrays, e uma `String` mantém o esquema trivial.
    var checklistDoneIDs: String = ""

    var updatedAt: Date = Date.distantPast

    init(date: Date) {
        let day = WeekMath.startOfDay(date)
        self.date = day
        self.dayKey = WeekMath.dayKey(day)
        self.updatedAt = .now
    }

    subscript(metric: Metric) -> Int {
        get {
            switch metric {
            case .contactos: contactos
            case .primeirasReunioesMarcadas: primeirasReunioesMarcadas
            case .segundasReunioesMarcadas: segundasReunioesMarcadas
            case .terceirasReunioesMarcadas: terceirasReunioesMarcadas
            case .primeirasReunioesRealizadas: primeirasReunioesRealizadas
            case .segundasReunioesRealizadas: segundasReunioesRealizadas
            case .terceirasReunioesRealizadas: terceirasReunioesRealizadas
            case .pesquisas: pesquisas
            case .referencias: referencias
            }
        }
        set {
            let value = max(0, newValue)
            switch metric {
            case .contactos: contactos = value
            case .primeirasReunioesMarcadas: primeirasReunioesMarcadas = value
            case .segundasReunioesMarcadas: segundasReunioesMarcadas = value
            case .terceirasReunioesMarcadas: terceirasReunioesMarcadas = value
            case .primeirasReunioesRealizadas: primeirasReunioesRealizadas = value
            case .segundasReunioesRealizadas: segundasReunioesRealizadas = value
            case .terceirasReunioesRealizadas: terceirasReunioesRealizadas = value
            case .pesquisas: pesquisas = value
            case .referencias: referencias = value
            }
            updatedAt = .now
        }
    }

    /// Conjunto das tarefas concluídas. Ids desconhecidos — de tarefas entretanto
    /// apagadas — ficam guardados na mesma, para o histórico sobreviver a quem as recrie.
    var completedChecklistIDs: Set<String> {
        get {
            Set(checklistDoneIDs.split(separator: ",").map(String.init))
        }
        set {
            checklistDoneIDs = newValue.sorted().joined(separator: ",")
            updatedAt = .now
        }
    }

    /// Um dia sem nenhuma métrica preenchida e sem nenhuma tarefa marcada conta como
    /// não registado. Sem contar a checklist, um dia só com tarefas feitas continuaria
    /// a disparar o lembrete de "ainda não registaste".
    var isEmpty: Bool {
        Metric.allCases.allSatisfy { self[$0] == 0 } && checklistDoneIDs.isEmpty
    }
}
