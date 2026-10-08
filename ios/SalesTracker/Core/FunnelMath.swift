import Foundation

/// Os passos do funil que têm preço no Painel: o contacto e as reuniões realizadas.
///
/// As marcadas ficam de fora de propósito: o que produz valor é a reunião que acontece,
/// e uma marcada que cai não vale nada.
enum FunnelStep: String, CaseIterable, Identifiable, Sendable {
    case contactos
    case primeirasRealizadas
    case segundasRealizadas
    case terceirasRealizadas

    var id: String { rawValue }

    var label: String {
        switch self {
        case .contactos: "Contacto"
        case .primeirasRealizadas: "1.ª reunião realizada"
        case .segundasRealizadas: "2.ª reunião realizada"
        case .terceirasRealizadas: "3.ª reunião realizada"
        }
    }

    var metric: Metric {
        switch self {
        case .contactos: .contactos
        case .primeirasRealizadas: .primeirasReunioesRealizadas
        case .segundasRealizadas: .segundasReunioesRealizadas
        case .terceirasRealizadas: .terceirasReunioesRealizadas
        }
    }

    /// Alvo do mês a partir dos objetivos de atividade: contactos por dia útil, reuniões
    /// por semana (cinco dias úteis).
    func monthlyTarget(settings: AppSettings, workdays: Int) -> Int {
        let weeks = Double(workdays) / 5
        let value: Double = switch self {
        case .contactos: Double(settings.goalContactosDia * workdays)
        case .primeirasRealizadas: Double(settings.goalPrimeirasReunioes) * weeks
        case .segundasRealizadas: Double(settings.goalSegundasReunioes) * weeks
        case .terceirasRealizadas: Double(settings.goalTerceirasReunioes) * weeks
        }
        return Int(value.rounded())
    }
}

enum FunnelCalendar {
    /// Dias de segunda a sexta dentro do período, inclusive.
    static func workdays(in month: MonthSpan) -> Int {
        let cal = WeekMath.calendar
        var day = month.start
        var count = 0
        while day <= month.end {
            if !cal.isDateInWeekend(day) { count += 1 }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return count
    }
}

/// Contagens de um período (mês ou soma de meses) e o valor fechado nele.
struct FunnelCounts: Equatable, Sendable {
    var counts: [FunnelStep: Double] = [:]
    var valor: Double = 0

    subscript(step: FunnelStep) -> Double {
        get { counts[step] ?? 0 }
        set { counts[step] = newValue }
    }

    static func summing(
        entries: [DailyEntry],
        summaries: [WeeklySummary],
        in month: MonthSpan
    ) -> FunnelCounts {
        let totals = MetricTotals.summing(entries.filter { month.contains($0.date) })
        var result = FunnelCounts()
        for step in FunnelStep.allCases { result[step] = Double(totals[step.metric]) }
        result.valor = summaries
            .filter { month.contains($0.weekStart) }
            .reduce(0) { $0 + $1.valorTotalFechos }
        return result
    }

    static func + (a: FunnelCounts, b: FunnelCounts) -> FunnelCounts {
        var r = FunnelCounts()
        for step in FunnelStep.allCases { r[step] = a[step] + b[step] }
        r.valor = a.valor + b.valor
        return r
    }
}

/// De onde vêm os preços de cada passo.
enum FunnelSource: Equatable, Sendable {
    /// Meses fechados com valor registado, do mais antigo para o mais recente.
    case historico([MonthSpan])
    /// Sem histórico: o objetivo mensal a dividir pelo alvo de atividade do mês.
    case objetivo
}

/// O preço de cada passo do funil: quanto vale um contacto, uma 1.ª reunião realizada…
///
/// É o valor fechado a dividir pela quantidade desse passo que o produziu. Com meses
/// anteriores usam-se os números reais deles; sem eles, o objetivo mensal a dividir
/// pelo alvo de atividade do mês.
struct FunnelBaseline: Equatable, Sendable {
    let source: FunnelSource
    let reference: FunnelCounts

    /// Até três meses fechados anteriores ao atual; só contam os que têm valor fechado,
    /// porque sem valor não há preço a tirar deles.
    static let lookbackMonths = 3

    static func make(
        entries: [DailyEntry],
        summaries: [WeeklySummary],
        settings: AppSettings,
        now: Date = .now
    ) -> FunnelBaseline {
        let past = (1...lookbackMonths).reversed().map {
            WeekMath.commercialMonth(offsetBy: -$0, closingOn: settings.monthCloseDay, from: now)
        }
        let withValue = past.compactMap { month -> (MonthSpan, FunnelCounts)? in
            let counts = FunnelCounts.summing(entries: entries, summaries: summaries, in: month)
            return counts.valor > 0 ? (month, counts) : nil
        }
        if !withValue.isEmpty {
            let sum = withValue.map(\.1).reduce(FunnelCounts(), +)
            return FunnelBaseline(source: .historico(withValue.map(\.0)), reference: sum)
        }
        return FunnelBaseline(source: .objetivo, reference: goalReference(settings: settings, now: now))
    }

    /// O mês segundo os objetivos: alvo de atividade do mês e o objetivo mensal em euros.
    static func goalReference(settings: AppSettings, now: Date) -> FunnelCounts {
        let month = WeekMath.commercialMonth(containing: now, closingOn: settings.monthCloseDay)
        let workdays = FunnelCalendar.workdays(in: month)
        var r = FunnelCounts()
        for step in FunnelStep.allCases {
            r[step] = Double(step.monthlyTarget(settings: settings, workdays: workdays))
        }
        r.valor = Double(settings.goalMensalValor)
        return r
    }

    /// Valor de cada unidade deste passo, em euros. `nil` quando o passo não tem contagem.
    func valuePerUnit(_ step: FunnelStep) -> Double? {
        let count = reference[step]
        guard count > 0, reference.valor > 0 else { return nil }
        return reference.valor / count
    }
}
