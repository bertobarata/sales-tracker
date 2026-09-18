import Foundation
import SwiftData

/// Acesso tipado ao SwiftData. Concentra aqui a deduplicação por dia e por semana,
/// porque o CloudKit não permite `@Attribute(.unique)` — sem isto, dois dispositivos
/// a gravar o mesmo dia criariam dois registos.
struct EntryStore {
    let context: ModelContext

    init(_ context: ModelContext) {
        self.context = context
    }

    // MARK: - Dias

    func entry(for date: Date) -> DailyEntry? {
        let key = WeekMath.dayKey(date)
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.dayKey == key },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        // Se o CloudKit trouxe duplicados do mesmo dia, fica o mais recente.
        for duplicate in matches.dropFirst() {
            context.delete(duplicate)
        }
        return matches.first
    }

    func entryOrCreate(for date: Date) -> DailyEntry {
        if let existing = entry(for: date) { return existing }
        let created = DailyEntry(date: date)
        context.insert(created)
        return created
    }

    /// Grava um dia inteiro e devolve `true` se ficou alguma coisa gravada.
    ///
    /// Com gravação automática, qualquer toque num campo passaria a criar registo. Um dia
    /// todo a zeros não é um dia registado: contaria para as tendências, calaria o lembrete
    /// de "ainda não registaste" e encheria o iCloud de nada. Por isso um dia que fique
    /// vazio é apagado, e um dia vazio que ainda não exista nunca chega a ser criado.
    @discardableResult
    func saveDay(_ values: [Metric: Int], checklist: Set<String>, for date: Date) -> Bool {
        let hasContent = Metric.allCases.contains { (values[$0] ?? 0) > 0 } || !checklist.isEmpty

        guard hasContent else {
            if let existing = entry(for: date) {
                context.delete(existing)
                save()
            }
            return false
        }

        let entry = entryOrCreate(for: date)
        for metric in Metric.allCases {
            entry[metric] = values[metric] ?? 0
        }
        entry.completedChecklistIDs = checklist
        save()
        return true
    }

    /// Os dias já registados entre duas datas, numa só consulta.
    ///
    /// O agendamento dos lembretes precisa disto para catorze dias. Perguntar dia a dia
    /// dava catorze consultas seguidas na thread principal, cada uma com a deduplicação
    /// por cima — e isso acontecia a cada regresso à app.
    func filledDayKeys(from start: Date, through end: Date) -> Set<String> {
        let first = WeekMath.startOfDay(start)
        let last = WeekMath.startOfDay(end)
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date >= first && $0.date <= last }
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        return Set(matches.filter { !$0.isEmpty }.map(\.dayKey))
    }

    func entries(in week: Week) -> [DailyEntry] {
        let start = week.start
        let end = week.end
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func totals(in week: Week) -> MetricTotals {
        MetricTotals.summing(entries(in: week))
    }

    // MARK: - Semanas

    func summary(for week: Week) -> WeeklySummary? {
        let key = week.startKey
        let descriptor = FetchDescriptor<WeeklySummary>(
            predicate: #Predicate { $0.weekStartKey == key },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        for duplicate in matches.dropFirst() {
            context.delete(duplicate)
        }
        return matches.first
    }

    func summaryOrCreate(for week: Week) -> WeeklySummary {
        if let existing = summary(for: week) { return existing }
        let created = WeeklySummary(week: week)
        context.insert(created)
        return created
    }

    func allSummaries() -> [WeeklySummary] {
        let descriptor = FetchDescriptor<WeeklySummary>(sortBy: [SortDescriptor(\.weekStart)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Soma do valor de fechos das semanas cujo início cai no período indicado.
    ///
    /// Mesma regra da PWA — a semana conta para o período em que *começa* — mas o
    /// período já não é o mês de calendário: é o mês comercial, que fecha no dia
    /// escolhido nas definições.
    func valorTotal(in span: MonthSpan) -> Double {
        let start = span.start
        let end = span.end
        let descriptor = FetchDescriptor<WeeklySummary>(
            predicate: #Predicate { $0.weekStart >= start && $0.weekStart <= end }
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        return matches.reduce(0) { $0 + $1.valorTotalFechos }
    }

    func save() {
        try? context.save()
    }
}
