import Testing
import Foundation
@testable import SalesTracker

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var c = DateComponents()
    c.year = year; c.month = month; c.day = day; c.hour = 12
    return WeekMath.calendar.date(from: c)!
}

@Suite("Exportação CSV do histórico")
struct CSVExportTests {

    private func summary(week: Week, valor: Double, primeiras: Int) -> WeeklySummary {
        let s = WeeklySummary(week: week)
        var totals = MetricTotals()
        totals[.primeirasReunioesRealizadas] = primeiras
        s.totals = totals
        var extra = WeeklyExtra.empty
        extra.valorTotalFechos = valor
        s.extra = extra
        return s
    }

    @Test("O cabeçalho tem as mesmas colunas e ordem da folha da PWA")
    func header() {
        let line = CSVExport.csv(for: []).split(separator: "\n").first!
        #expect(line == "Semana (início),Semana (fim),Contactos,1as Marcadas,2as Marcadas,3as Marcadas,1as Realizadas,2as Realizadas,3as Realizadas,Pesquisas,Referências,Contratos Fechados,Valor Fechos (€),Pessoas Seguras,1ª Próxima Semana,2ª Próxima Semana,3ª Próxima Semana")
    }

    @Test("As semanas saem ordenadas da mais antiga para a mais recente")
    func sortedByWeek() {
        let recent = summary(week: WeekMath.week(containing: date(2026, 4, 22)), valor: 100, primeiras: 1)
        let older = summary(week: WeekMath.week(containing: date(2026, 3, 11)), valor: 200, primeiras: 2)

        let lines = CSVExport.csv(for: [recent, older]).split(separator: "\n")
        #expect(lines.count == 3)
        #expect(lines[1].hasPrefix("2026-03-09"))
        #expect(lines[2].hasPrefix("2026-04-20"))
    }

    @Test("Cada linha tem tantos campos quantas as colunas do cabeçalho")
    func columnCountMatches() {
        let s = summary(week: WeekMath.week(containing: date(2026, 4, 22)), valor: 1234.5, primeiras: 9)
        let lines = CSVExport.csv(for: [s]).split(separator: "\n")
        let headerCount = lines[0].split(separator: ",", omittingEmptySubsequences: false).count
        let rowCount = lines[1].split(separator: ",", omittingEmptySubsequences: false).count
        #expect(headerCount == rowCount)
    }

    @Test("O valor mantém duas casas decimais e não é arredondado para cima")
    func valuePrecision() {
        let s = summary(week: WeekMath.week(containing: date(2026, 4, 22)), valor: 1234.56, primeiras: 0)
        let row = CSVExport.csv(for: [s]).split(separator: "\n")[1]
        #expect(row.contains("1234.56"))
    }
}
