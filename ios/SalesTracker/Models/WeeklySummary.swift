import Foundation
import SwiftData

/// Fecho de uma semana: os totais congelados no momento em que foi guardada,
/// mais os campos que só existem ao nível semanal (contratos, valor, próxima semana).
@Model
final class WeeklySummary {
    var weekStartKey: String = ""
    var weekStart: Date = Date.distantPast
    var weekEnd: Date = Date.distantPast

    // Snapshot dos totais diários no momento do fecho.
    var contactos: Int = 0
    var primeirasReunioesMarcadas: Int = 0
    var segundasReunioesMarcadas: Int = 0
    var terceirasReunioesMarcadas: Int = 0
    var primeirasReunioesRealizadas: Int = 0
    var segundasReunioesRealizadas: Int = 0
    var terceirasReunioesRealizadas: Int = 0
    var pesquisas: Int = 0
    var referencias: Int = 0

    // Campos exclusivos do relatório semanal.
    var contratosFechados: Int = 0
    var valorTotalFechos: Double = 0
    var pessoasSeguras: Int = 0
    var reunioes1aProxSemana: Int = 0
    var reunioes2aProxSemana: Int = 0
    var reunioes3aProxSemana: Int = 0

    var updatedAt: Date = Date.distantPast

    init(week: Week) {
        self.weekStart = week.start
        self.weekEnd = week.end
        self.weekStartKey = week.startKey
        self.updatedAt = .now
    }

    var totals: MetricTotals {
        get {
            var t = MetricTotals()
            t[.contactos] = contactos
            t[.primeirasReunioesMarcadas] = primeirasReunioesMarcadas
            t[.segundasReunioesMarcadas] = segundasReunioesMarcadas
            t[.terceirasReunioesMarcadas] = terceirasReunioesMarcadas
            t[.primeirasReunioesRealizadas] = primeirasReunioesRealizadas
            t[.segundasReunioesRealizadas] = segundasReunioesRealizadas
            t[.terceirasReunioesRealizadas] = terceirasReunioesRealizadas
            t[.pesquisas] = pesquisas
            t[.referencias] = referencias
            return t
        }
        set {
            contactos = newValue[.contactos]
            primeirasReunioesMarcadas = newValue[.primeirasReunioesMarcadas]
            segundasReunioesMarcadas = newValue[.segundasReunioesMarcadas]
            terceirasReunioesMarcadas = newValue[.terceirasReunioesMarcadas]
            primeirasReunioesRealizadas = newValue[.primeirasReunioesRealizadas]
            segundasReunioesRealizadas = newValue[.segundasReunioesRealizadas]
            terceirasReunioesRealizadas = newValue[.terceirasReunioesRealizadas]
            pesquisas = newValue[.pesquisas]
            referencias = newValue[.referencias]
            updatedAt = .now
        }
    }

    var extra: WeeklyExtra {
        get {
            WeeklyExtra(
                contratosFechados: contratosFechados,
                valorTotalFechos: valorTotalFechos,
                pessoasSeguras: pessoasSeguras,
                reunioes1aProxSemana: reunioes1aProxSemana,
                reunioes2aProxSemana: reunioes2aProxSemana,
                reunioes3aProxSemana: reunioes3aProxSemana
            )
        }
        set {
            contratosFechados = newValue.contratosFechados
            valorTotalFechos = newValue.valorTotalFechos
            pessoasSeguras = newValue.pessoasSeguras
            reunioes1aProxSemana = newValue.reunioes1aProxSemana
            reunioes2aProxSemana = newValue.reunioes2aProxSemana
            reunioes3aProxSemana = newValue.reunioes3aProxSemana
            updatedAt = .now
        }
    }
}

struct WeeklyExtra: Equatable, Sendable {
    var contratosFechados: Int = 0
    var valorTotalFechos: Double = 0
    var pessoasSeguras: Int = 0
    var reunioes1aProxSemana: Int = 0
    var reunioes2aProxSemana: Int = 0
    var reunioes3aProxSemana: Int = 0

    /// Reuniões agendadas para a semana seguinte, somadas. É o número que diz se a
    /// semana que vem já tem trabalho marcado — ler os três em separado obriga a somar
    /// de cabeça de cada vez.
    var totalProximaSemana: Int {
        reunioes1aProxSemana + reunioes2aProxSemana + reunioes3aProxSemana
    }

    static let empty = WeeklyExtra()
}
