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

    /// Soma do valor de fechos das semanas cujo início cai no mês indicado.
    /// Mesma regra da PWA: a semana conta para o mês em que *começa*.
    func monthlyValorTotal(year: Int, month: Int) -> Double {
        let prefix = String(format: "%04d-%02d", year, month)
        let descriptor = FetchDescriptor<WeeklySummary>(
            predicate: #Predicate { $0.weekStartKey.starts(with: prefix) }
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        return matches.reduce(0) { $0 + $1.valorTotalFechos }
    }

    func save() {
        try? context.save()
    }
}
