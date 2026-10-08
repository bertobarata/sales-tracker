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

    private func history(contactos: Double, primeiras: Double, contratos: Double, valor: Double) -> FunnelBaseline {
        var r = FunnelCounts()
        r[.contactos] = contactos
        r[.primeirasMarcadas] = primeiras
        r[.contratos] = contratos
        r.valor = valor
        return FunnelBaseline(source: .historico([]), reference: r)
    }

    @Test("Cada contacto vale o valor fechado a dividir pelos contactos")
    func valuePerContact() {
        let b = history(contactos: 200, primeiras: 50, contratos: 4, valor: 6000)
        #expect(b.valuePerUnit(.contactos) == 30)
        #expect(b.valuePerUnit(.contratos) == 1500)
    }

    @Test("Para o objetivo, arredonda para cima")
    func neededRoundsUp() {
        let b = history(contactos: 200, primeiras: 50, contratos: 4, valor: 6000)
        // 5000 € a 30 € por contacto = 166,7 → 167
        #expect(b.needed(.contactos, forGoal: 5000) == 167)
    }

    @Test("Conversão é este passo a dividir pelo anterior")
    func conversion() {
        let b = history(contactos: 200, primeiras: 50, contratos: 4, valor: 6000)
        #expect(b.conversion(into: .primeirasMarcadas) == 0.25)
        #expect(b.conversion(into: .contactos) == nil)
    }

    @Test("Passo sem contagem não tem preço nem necessidade")
    func emptyStep() {
        let b = history(contactos: 200, primeiras: 50, contratos: 4, valor: 6000)
        #expect(b.valuePerUnit(.terceirasRealizadas) == nil)
        #expect(b.needed(.terceirasRealizadas, forGoal: 5000) == nil)
    }

    @Test("Sem histórico, o objetivo mensal reparte-se pelos objetivos semanais")
    func goalFallback() {
        var s = AppSettings()
        s.goalMensalValor = 6000
        s.goalPrimeirasReunioes = 10
        s.goalContratosSemana = 2
        s.monthCloseDay = 31
        let r = FunnelBaseline.goalReference(settings: s, now: date(2026, 9, 15))
        // setembro: 30 dias = 30/7 semanas
        let weeks = 30.0 / 7
        #expect(abs(r[.primeirasRealizadas] - 10 * weeks) < 0.0001)
        #expect(r.valor == 6000)
        #expect(r[.contactos] == 0)
        let b = FunnelBaseline(source: .objetivo, reference: r)
        #expect(b.valuePerUnit(.contactos) == nil)
        #expect(b.needed(.contratos, forGoal: 6000) == 9) // 2 × 30/7 = 8,57 → 9
    }
}
