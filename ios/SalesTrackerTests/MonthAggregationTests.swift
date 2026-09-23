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


@Suite("Mês comercial com dia de fecho")
struct CommercialMonthTests {

    @Test("Com fecho a 25, o período vai do dia 26 do mês anterior ao 25 deste")
    func periodSpansTheClosingCycle() {
        let span = WeekMath.commercialMonth(containing: date(2026, 9, 10), closingOn: 25)
        #expect(WeekMath.dayKey(span.start) == "2026-08-26")
        #expect(WeekMath.dayKey(span.end) == "2026-09-25")
    }

    @Test("O próprio dia de fecho ainda pertence ao período que fecha")
    func closingDayBelongsToTheClosingPeriod() {
        let span = WeekMath.commercialMonth(containing: date(2026, 9, 25), closingOn: 25)
        #expect(WeekMath.dayKey(span.end) == "2026-09-25")
    }

    @Test("O dia seguinte ao fecho já conta para o período seguinte")
    func dayAfterClosingStartsTheNextPeriod() {
        let span = WeekMath.commercialMonth(containing: date(2026, 9, 26), closingOn: 25)
        #expect(WeekMath.dayKey(span.start) == "2026-09-26")
        #expect(WeekMath.dayKey(span.end) == "2026-10-25")
    }

    @Test("Fecho a 31 dá o mês de calendário inteiro")
    func closingOn31MatchesTheCalendarMonth() {
        let span = WeekMath.commercialMonth(containing: date(2026, 9, 10), closingOn: 31)
        #expect(WeekMath.dayKey(span.start) == "2026-09-01")
        #expect(WeekMath.dayKey(span.end) == "2026-09-30")
    }

    @Test("Um dia que não existe no mês encurta-se ao último")
    func impossibleDayClampsToMonthLength() {
        // 2026 não é bissexto: fevereiro acaba a 28.
        let span = WeekMath.commercialMonth(containing: date(2026, 2, 10), closingOn: 31)
        #expect(WeekMath.dayKey(span.end) == "2026-02-28")

        let leap = WeekMath.commercialMonth(containing: date(2028, 2, 10), closingOn: 30)
        #expect(WeekMath.dayKey(leap.end) == "2028-02-29")
    }

    @Test("Recuar períodos atravessa a viragem do ano")
    func offsetCrossesTheYearBoundary() {
        let span = WeekMath.commercialMonth(offsetBy: -2, closingOn: 25, from: date(2026, 1, 10))
        #expect(WeekMath.dayKey(span.start) == "2025-10-26")
        #expect(WeekMath.dayKey(span.end) == "2025-11-25")
    }

    @Test("Os períodos saem por ordem, sem buracos nem sobreposições")
    func periodsAreContiguous() {
        let months = WeekMath.lastCommercialMonths(6, closingOn: 25, from: date(2026, 9, 10))
        #expect(months.count == 6)

        for (earlier, later) in zip(months, months.dropFirst()) {
            let dayAfter = WeekMath.calendar.date(byAdding: .day, value: 1, to: earlier.end)!
            // Sem isto, um dia podia cair fora de todos os períodos — ou dentro de dois.
            #expect(WeekMath.dayKey(dayAfter) == WeekMath.dayKey(later.start))
        }
    }

    @Test("O período é nomeado pelo mês em que termina")
    func labelComesFromTheClosingMonth() {
        let span = WeekMath.commercialMonth(containing: date(2026, 9, 10), closingOn: 25)
        #expect(span.label == "set")
        #expect(span.rangeLabel == "26 ago – 25 set")
    }
}
