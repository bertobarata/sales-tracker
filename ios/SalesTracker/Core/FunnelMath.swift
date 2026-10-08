import Foundation

/// Um passo do funil comercial, da primeira chamada ao contrato.
enum FunnelStep: String, CaseIterable, Identifiable, Sendable {
    case contactos
    case primeirasMarcadas
    case primeirasRealizadas
    case segundasMarcadas
    case segundasRealizadas
    case terceirasMarcadas
    case terceirasRealizadas
    case contratos

    var id: String { rawValue }

    var label: String {
        switch self {
        case .contactos: "Contacto"
        case .primeirasMarcadas: "1.ª reunião marcada"
        case .primeirasRealizadas: "1.ª reunião realizada"
        case .segundasMarcadas: "2.ª reunião marcada"
        case .segundasRealizadas: "2.ª reunião realizada"
        case .terceirasMarcadas: "3.ª reunião marcada"
        case .terceirasRealizadas: "3.ª reunião realizada"
        case .contratos: "Contrato fechado"
        }
    }

    /// A métrica diária correspondente. Os contratos só existem no fecho semanal.
    var metric: Metric? {
        switch self {
        case .contactos: .contactos
        case .primeirasMarcadas: .primeirasReunioesMarcadas
        case .primeirasRealizadas: .primeirasReunioesRealizadas
        case .segundasMarcadas: .segundasReunioesMarcadas
        case .segundasRealizadas: .segundasReunioesRealizadas
        case .terceirasMarcadas: .terceirasReunioesMarcadas
        case .terceirasRealizadas: .terceirasReunioesRealizadas
        case .contratos: nil
        }
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
        let weeks = summaries.filter { month.contains($0.weekStart) }
        var result = FunnelCounts()
        for step in FunnelStep.allCases {
            if let metric = step.metric { result[step] = Double(totals[metric]) }
        }
        result[.contratos] = Double(weeks.reduce(0) { $0 + $1.contratosFechados })
        result.valor = weeks.reduce(0) { $0 + $1.valorTotalFechos }
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
    /// Sem histórico: o objetivo mensal repartido pelos objetivos semanais.
    case objetivo
}

/// O funil de referência: quanto vale cada passo e quantos são precisos para o objetivo.
///
/// "Quanto vale uma chamada" é o valor fechado a dividir pelo número de chamadas que o
/// produziu. Com meses anteriores, usam-se os números reais desses meses; sem eles, a
/// referência é o objetivo mensal a dividir pelos objetivos de atividade do mês.
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

    /// O mês "ideal" segundo os objetivos: objetivos semanais vezes as semanas do mês.
    /// Contactos e reuniões marcadas não têm objetivo, por isso ficam sem preço.
    static func goalReference(settings: AppSettings, now: Date) -> FunnelCounts {
        let month = WeekMath.commercialMonth(containing: now, closingOn: settings.monthCloseDay)
        let days = (WeekMath.calendar.dateComponents([.day], from: month.start, to: month.end).day ?? 30) + 1
        let weeks = Double(days) / 7
        var r = FunnelCounts()
        r[.primeirasRealizadas] = Double(settings.goalPrimeirasReunioes) * weeks
        r[.segundasRealizadas] = Double(settings.goalSegundasReunioes) * weeks
        r[.terceirasRealizadas] = Double(settings.goalTerceirasReunioes) * weeks
        r[.contratos] = Double(settings.goalContratosSemana) * weeks
        r.valor = Double(settings.goalMensalValor)
        return r
    }

    /// Valor de cada unidade deste passo, em euros. `nil` quando o passo não tem contagem.
    func valuePerUnit(_ step: FunnelStep) -> Double? {
        let count = reference[step]
        guard count > 0, reference.valor > 0 else { return nil }
        return reference.valor / count
    }

    /// Quantos deste passo são precisos para chegar a `goal` euros.
    func needed(_ step: FunnelStep, forGoal goal: Double) -> Int? {
        guard let unit = valuePerUnit(step), unit > 0 else { return nil }
        return Int((goal / unit).rounded(.up))
    }

    /// Conversão do passo anterior para este (ex.: marcadas / contactos).
    func conversion(into step: FunnelStep) -> Double? {
        guard let index = FunnelStep.allCases.firstIndex(of: step), index > 0 else { return nil }
        let previous = reference[FunnelStep.allCases[index - 1]]
        guard previous > 0 else { return nil }
        return reference[step] / previous
    }
}
