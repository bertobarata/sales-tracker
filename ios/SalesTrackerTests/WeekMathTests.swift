import Testing
import Foundation
@testable import SalesTracker

/// Constrói uma data a partir de componentes no mesmo calendário que a app usa,
/// para os testes não dependerem do fuso horário da máquina.
private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var c = DateComponents()
    c.year = year; c.month = month; c.day = day
    c.hour = 12 // meio-dia evita ambiguidades de mudança de hora
    return WeekMath.calendar.date(from: c)!
}

@Suite("Aritmética de semanas ISO 8601")
struct WeekMathTests {

    @Test("A semana começa à segunda e termina ao domingo")
    func weekBoundaries() {
        // 2026-04-22 é uma quarta-feira.
        let week = WeekMath.week(containing: date(2026, 4, 22))
        #expect(week.startKey == "2026-04-20")
        #expect(week.endKey == "2026-04-26")
    }

    @Test("Um domingo pertence à semana que começou na segunda anterior")
    func sundayBelongsToPreviousMonday() {
        // 2026-04-26 é um domingo.
        let week = WeekMath.week(containing: date(2026, 4, 26))
        #expect(week.startKey == "2026-04-20")
    }

    @Test("Uma segunda-feira é o primeiro dia da sua própria semana")
    func mondayStartsItsOwnWeek() {
        let week = WeekMath.week(containing: date(2026, 4, 20))
        #expect(week.startKey == "2026-04-20")
        #expect(week.endKey == "2026-04-26")
    }

    @Test("A semana tem exatamente sete dias consecutivos")
    func weekHasSevenDays() {
        let week = WeekMath.week(containing: date(2026, 4, 22))
        #expect(week.days.count == 7)
        #expect(WeekMath.dayKey(week.days.first!) == "2026-04-20")
        #expect(WeekMath.dayKey(week.days.last!) == "2026-04-26")
    }

    @Test("O offset recua e avança uma semana de cada vez")
    func weekOffset() {
        let reference = date(2026, 4, 22)
        #expect(WeekMath.week(offsetBy: 0, from: reference).startKey == "2026-04-20")
        #expect(WeekMath.week(offsetBy: -1, from: reference).startKey == "2026-04-13")
        #expect(WeekMath.week(offsetBy: -4, from: reference).startKey == "2026-03-23")
        #expect(WeekMath.week(offsetBy: 1, from: reference).startKey == "2026-04-27")
    }

    @Test("O offset atravessa a fronteira do ano")
    func weekOffsetCrossesYear() {
        let reference = date(2027, 1, 6) // quarta-feira
        #expect(WeekMath.week(offsetBy: -1, from: reference).startKey == "2026-12-28")
    }

    @Test("A numeração ISO usa a âncora da quinta-feira")
    func isoWeekNumbers() {
        // 2026-01-01 é uma quinta — logo a semana que a contém é a semana 1 de 2026.
        #expect(WeekMath.week(containing: date(2026, 1, 1)).isoWeekNumber == 1)
        #expect(WeekMath.week(containing: date(2026, 4, 22)).isoWeekNumber == 17)
    }

    @Test("A etiqueta da semana usa o mês do dia final")
    func weekLabel() {
        let week = WeekMath.week(containing: date(2026, 4, 22))
        #expect(week.label == "Semana 17 · 20–26 abr")
    }

    @Test("A chave do dia é sempre yyyy-MM-dd com zeros à esquerda")
    func dayKeyPadding() {
        #expect(WeekMath.dayKey(date(2026, 1, 5)) == "2026-01-05")
        #expect(WeekMath.dayKey(date(2026, 12, 31)) == "2026-12-31")
    }

    @Test("A data apresentada é dd/MM/yyyy")
    func displayDate() {
        #expect(WeekMath.displayDate(date(2026, 4, 20)) == "20/04/2026")
        #expect(WeekMath.displayDate(date(2026, 1, 5)) == "05/01/2026")
    }

    @Test("contains cobre todos os dias da semana e exclui os vizinhos")
    func weekContains() {
        let week = WeekMath.week(containing: date(2026, 4, 22))
        #expect(week.contains(date(2026, 4, 20)))
        #expect(week.contains(date(2026, 4, 26)))
        #expect(!week.contains(date(2026, 4, 19)))
        #expect(!week.contains(date(2026, 4, 27)))
    }
}
