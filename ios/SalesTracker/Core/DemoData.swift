#if DEBUG
import Foundation
import SwiftData

/// Dados de demonstração para as capturas de ecrã da App Store.
///
/// Só existe em builds Debug e só corre com `--demo-data` nos argumentos de
/// lançamento, por isso não há caminho que o ative numa build de distribuição.
/// Usa contentor em memória: não toca na base de dados real nem no iCloud.
enum DemoData {

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("--demo-data")
    }

    /// Valores por dia da semana (segunda a sexta). O fim de semana fica a zero,
    /// que é o padrão real de quem faz prospeção em dias úteis.
    private static let weekdayShape: [[Int]] = [
        //  cont, 1aM, 2aM, 3aM, 1aR, 2aR, 3aR, pesq, refs
        [14, 4, 2, 1, 3, 2, 1, 6, 3],
        [11, 3, 3, 1, 2, 2, 1, 5, 2],
        [16, 5, 2, 2, 4, 1, 2, 7, 4],
        [9, 2, 3, 1, 2, 3, 1, 4, 2],
        [13, 4, 2, 1, 3, 2, 1, 6, 3],
    ]

    static func seed(into context: ModelContext) {
        let store = EntryStore(context)
        let today = WeekMath.startOfDay(.now)
        seedSettings()
        let tasks = ChecklistStore.items

        // Doze semanas para as Tendências terem série suficiente para ler.
        for offset in stride(from: -11, through: 0, by: 1) {
            let week = WeekMath.week(offsetBy: offset)
            var weekTotals = MetricTotals()

            for (index, day) in week.days.enumerated() where index < weekdayShape.count {
                // A semana atual só tem dias até hoje — o resto ainda não aconteceu.
                if day > today { continue }

                let shape = weekdayShape[index]
                let variation = variationFactor(week: offset, weekday: index)
                let entry = store.entryOrCreate(for: day)
                for (metricIndex, metric) in Metric.allCases.enumerated() {
                    let value = max(0, Int((Double(shape[metricIndex]) * variation).rounded()))
                    entry[metric] = value
                    weekTotals[metric] += value
                }
                // Nem todos os dias com as tarefas todas feitas — um ecrã onde está tudo
                // marcado não mostra como é que a secção se comporta por preencher.
                entry.completedChecklistIDs = Set(tasks.prefix(index % 2 == 0 ? tasks.count : 1).map(\.id))
            }

            // As semanas fechadas levam resumo; a atual fica por fechar, que é o
            // estado normal a meio da semana.
            guard offset < 0 else { continue }
            let summary = store.summaryOrCreate(for: week)
            summary.totals = weekTotals
            summary.extra = extra(forWeekOffset: offset, totals: weekTotals)
        }

        store.save()
    }

    /// Faz a série subir ao longo do trimestre em vez de ser uma linha plana,
    /// senão o gráfico de Tendências não mostra nada de interessante.
    private static func variationFactor(week: Int, weekday: Int) -> Double {
        let trend = 1.0 + Double(11 + week) * 0.025
        let wobble = [0.92, 1.08, 0.97, 1.05, 1.0][weekday % 5]
        return trend * wobble
    }

    private static func extra(forWeekOffset offset: Int, totals: MetricTotals) -> WeeklyExtra {
        let fechos = max(1, totals[.terceirasReunioesRealizadas] / 2)
        return WeeklyExtra(
            contratosFechados: fechos,
            valorTotalFechos: Double(fechos) * 780 + Double(abs(offset) % 3) * 120,
            pessoasSeguras: fechos + 1,
            reunioes1aProxSemana: 4,
            reunioes2aProxSemana: 3,
            reunioes3aProxSemana: 2
        )
    }

    private static func seedSettings() {
        let d = UserDefaults.shared
        d.set(12, forKey: SettingsKey.goalPrimeirasReunioes)
        d.set(9, forKey: SettingsKey.goalSegundasReunioes)
        d.set(5, forKey: SettingsKey.goalTerceirasReunioes)
        d.set(3, forKey: SettingsKey.goalContratosSemana)
        d.set(1800, forKey: SettingsKey.goalValorSemana)
        d.set(6000, forKey: SettingsKey.goalMensalValor)
        d.set(18, forKey: SettingsKey.reminderHour)
        d.set(30, forKey: SettingsKey.reminderMinute)
        d.set(true, forKey: SettingsKey.remindersEnabled)
        // A introdução não aparece nas capturas dos outros separadores — exceto quando o
        // teste a pede de propósito, e aí o argumento tem de ganhar à semente.
        if !ProcessInfo.processInfo.arguments.contains("--reset-onboarding") {
            d.set(SettingsKey.onboardingVersion, forKey: SettingsKey.onboardingCompletedVersion)
        }

        // Rótulos genéricos de propósito: as capturas vão para a App Store, e nada na
        // app pode parecer preso a um empregador.
        ChecklistStore.items = [
            ChecklistItem(id: "demo-portal", label: "Acesso ao portal"),
            ChecklistItem(id: "demo-crm", label: "Registo no CRM"),
            ChecklistItem(id: "demo-follow", label: "Seguimentos do dia"),
        ]
    }
}
#endif
