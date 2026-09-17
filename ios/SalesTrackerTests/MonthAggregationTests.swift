import Testing
import Foundation
@testable import SalesTracker

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var c = DateComponents()
    c.year = year; c.month = month; c.day = day; c.hour = 12
    return WeekMath.calendar.date(from: c)!
}

@Suite("Agregação por mês nas tendências")
struct MonthAggregationTests {

    @Test("Um mês vai do dia 1 ao último dia")
    func monthBoundaries() {
        let month = WeekMath.monthSpan(offsetBy: 0, from: date(2026, 4, 15))
        #expect(WeekMath.dayKey(month.start) == "2026-04-01")
        #expect(WeekMath.dayKey(month.end) == "2026-04-30")
    }

    @Test("Fevereiro de ano bissexto termina a 29")
    func leapFebruary() {
        let month = WeekMath.monthSpan(offsetBy: 0, from: date(2028, 2, 10))
        #expect(WeekMath.dayKey(month.end) == "2028-02-29")
    }

    @Test("Recuar meses atravessa a viragem do ano")
    func crossesYearBoundary() {
        let month = WeekMath.monthSpan(offsetBy: -2, from: date(2026, 1, 20))
        #expect(WeekMath.dayKey(month.start) == "2025-11-01")
    }

    @Test("Seis meses devolvem seis meses, do mais antigo para o atual")
    func lastMonthsOrder() {
        let months = WeekMath.lastMonths(6, from: date(2026, 6, 15))
        #expect(months.count == 6)
        #expect(WeekMath.dayKey(months.first!.start) == "2026-01-01")
        #expect(WeekMath.dayKey(months.last!.start) == "2026-06-01")
    }

    @Test("O mês sabe que dias lhe pertencem")
    func containsDay() {
        let month = WeekMath.monthSpan(offsetBy: 0, from: date(2026, 4, 15))
        #expect(month.contains(date(2026, 4, 1)))
        #expect(month.contains(date(2026, 4, 30)))
        #expect(!month.contains(date(2026, 5, 1)))
        #expect(!month.contains(date(2026, 3, 31)))
    }

    @Test("As semanas de um período acabam sempre na semana atual")
    func weeksEndOnCurrentWeek() {
        let now = date(2026, 4, 15)
        let weeks = WeekMath.weeksCovering(months: 3, from: now)
        #expect(weeks.last == WeekMath.week(containing: now))
        #expect(weeks.count >= 12)
    }

    @Test("A semana que contém o início do período entra inteira")
    func firstWeekIsWhole() {
        // 2026-02-01 é um domingo: a sua semana ISO começa a 26 de janeiro.
        let weeks = WeekMath.weeksCovering(months: 3, from: date(2026, 4, 15))
        #expect(WeekMath.dayKey(weeks.first!.start) == "2026-01-26")
    }

    @Test("As semanas saem por ordem e sem repetições")
    func weeksAreOrderedAndUnique() {
        let weeks = WeekMath.weeksCovering(months: 6, from: date(2026, 4, 15))
        #expect(weeks == weeks.sorted { $0.start < $1.start })
        #expect(Set(weeks.map(\.startKey)).count == weeks.count)
    }
}
