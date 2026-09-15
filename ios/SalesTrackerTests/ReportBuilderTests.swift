import Testing
import Foundation
@testable import SalesTracker

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var c = DateComponents()
    c.year = year; c.month = month; c.day = day; c.hour = 12
    return WeekMath.calendar.date(from: c)!
}

@Suite("Relatório semanal para WhatsApp")
struct ReportBuilderTests {

    private var week: Week { WeekMath.week(containing: date(2026, 4, 22)) }

    private func totals() -> MetricTotals {
        var t = MetricTotals()
        t[.primeirasReunioesRealizadas] = 10
        t[.segundasReunioesRealizadas] = 7
        t[.terceirasReunioesRealizadas] = 3
        t[.referencias] = 12
        return t
    }

    @Test("O texto sai exatamente no formato esperado pelo destinatário")
    func exactFormat() {
        let extra = WeeklyExtra(
            contratosFechados: 2,
            valorTotalFechos: 1450.50,
            pessoasSeguras: 4,
            reunioes1aProxSemana: 8,
            reunioes2aProxSemana: 5,
            reunioes3aProxSemana: 1
        )
        let text = ReportBuilder.whatsAppText(week: week, totals: totals(), extra: extra)

        #expect(text == """
        *20/04/2026 - 26/04/2026*

        1.ªR 10
        2.ªR 7
        3.ªR 3
        Contratos 2
        Valor 1451€
        Referências 12
        Pessoas seguras 4

        P. Semana
        1.ª- 8
        2.ª- 5
        3.ª- 1
        """)
    }

    @Test("O valor é sempre arredondado para cima, como na PWA")
    func valueRoundsUp() {
        var extra = WeeklyExtra.empty
        extra.valorTotalFechos = 1000.01
        let text = ReportBuilder.whatsAppText(week: week, totals: MetricTotals(), extra: extra)
        #expect(text.contains("Valor 1001€"))
    }

    @Test("Um valor inteiro não ganha um euro extra por arredondamento")
    func wholeValueUnchanged() {
        var extra = WeeklyExtra.empty
        extra.valorTotalFechos = 2000
        let text = ReportBuilder.whatsAppText(week: week, totals: MetricTotals(), extra: extra)
        #expect(text.contains("Valor 2000€"))
    }

    @Test("Uma semana vazia produz zeros e não campos em falta")
    func emptyWeek() {
        let text = ReportBuilder.whatsAppText(week: week, totals: MetricTotals(), extra: .empty)
        #expect(text.contains("1.ªR 0"))
        #expect(text.contains("Contratos 0"))
        #expect(text.contains("Valor 0€"))
        #expect(text.contains("Pessoas seguras 0"))
        #expect(text.contains("3.ª- 0"))
    }
}

@Suite("Totais de métricas")
struct MetricTotalsTests {

    @Test("Somar entradas acumula cada métrica em separado")
    func summing() {
        let a = DailyEntry(date: date(2026, 4, 20))
        a[.contactos] = 5
        a[.primeirasReunioesRealizadas] = 2

        let b = DailyEntry(date: date(2026, 4, 21))
        b[.contactos] = 3
        b[.referencias] = 4

        let totals = MetricTotals.summing([a, b])
        #expect(totals[.contactos] == 8)
        #expect(totals[.primeirasReunioesRealizadas] == 2)
        #expect(totals[.referencias] == 4)
        #expect(totals[.pesquisas] == 0)
    }

    @Test("Somar uma lista vazia dá zero em todas as métricas")
    func summingEmpty() {
        let totals = MetricTotals.summing([])
        for metric in Metric.allCases {
            #expect(totals[metric] == 0)
        }
    }

    @Test("Valores negativos são fixados a zero ao gravar")
    func negativeClamped() {
        let entry = DailyEntry(date: date(2026, 4, 20))
        entry[.contactos] = -5
        #expect(entry[.contactos] == 0)
    }

    @Test("Um dia sem métricas conta como não registado")
    func emptyEntry() {
        let entry = DailyEntry(date: date(2026, 4, 20))
        #expect(entry.isEmpty)
        entry[.pesquisas] = 1
        #expect(!entry.isEmpty)
    }
}
