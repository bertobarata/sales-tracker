import Testing
import Foundation
@testable import SalesTracker

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var c = DateComponents()
    c.year = year; c.month = month; c.day = day; c.hour = 12
    return WeekMath.calendar.date(from: c)!
}

@Suite("Funil do painel")
struct FunnelMathTests {

    @Test("Só o contacto e as reuniões realizadas têm preço")
    func steps() {
        #expect(FunnelStep.allCases == [.contactos, .primeirasRealizadas, .segundasRealizadas, .terceirasRealizadas])
    }

    @Test("Cada contacto vale o valor fechado a dividir pelos contactos")
    func valuePerContact() {
        var r = FunnelCounts()
        r[.contactos] = 200
        r[.primeirasRealizadas] = 40
        r.valor = 6000
        let b = FunnelBaseline(source: .historico([]), reference: r)
        #expect(b.valuePerUnit(.contactos) == 30)
        #expect(b.valuePerUnit(.primeirasRealizadas) == 150)
        #expect(b.valuePerUnit(.terceirasRealizadas) == nil)
    }

    @Test("Outubro de 2026 tem 22 dias úteis")
    func workdays() {
        let oct = WeekMath.commercialMonth(containing: date(2026, 10, 10), closingOn: 31)
        #expect(FunnelCalendar.workdays(in: oct) == 22)
    }

    @Test("O alvo de contactos é o objetivo diário vezes os dias úteis")
    func contactTarget() {
        var s = AppSettings()
        s.goalContactosDia = 12
        s.goalPrimeirasReunioes = 10
        #expect(FunnelStep.contactos.monthlyTarget(settings: s, workdays: 22) == 264)
        // 10 por semana × 22/5 semanas = 44
        #expect(FunnelStep.primeirasRealizadas.monthlyTarget(settings: s, workdays: 22) == 44)
    }

    @Test("Sem histórico, o preço é o objetivo mensal a dividir pelo alvo do mês")
    func goalFallback() {
        var s = AppSettings()
        s.goalMensalValor = 5280
        s.goalContactosDia = 12
        s.monthCloseDay = 31
        let r = FunnelBaseline.goalReference(settings: s, now: date(2026, 10, 10))
        let b = FunnelBaseline(source: .objetivo, reference: r)
        // 5280 € ÷ (12 × 22 = 264 contactos) = 20 €
        #expect(b.valuePerUnit(.contactos) == 20)
    }
}
