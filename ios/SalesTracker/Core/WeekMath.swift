import Foundation

/// Uma semana ISO 8601: começa à segunda, termina ao domingo.
struct Week: Equatable, Hashable, Identifiable, Sendable {
    let start: Date
    let end: Date

    var id: Date { start }
    var startKey: String { WeekMath.dayKey(start) }
    var endKey: String { WeekMath.dayKey(end) }

    /// Os sete dias da semana, de segunda a domingo.
    var days: [Date] {
        (0..<7).compactMap {
            WeekMath.calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    var isoWeekNumber: Int {
        WeekMath.calendar.component(.weekOfYear, from: start)
    }

    /// "Semana 17 · 20–26 abr"
    var label: String {
        let startDay = WeekMath.calendar.component(.day, from: start)
        let endDay = WeekMath.calendar.component(.day, from: end)
        let endMonth = WeekMath.calendar.component(.month, from: end)
        return "Semana \(isoWeekNumber) · \(startDay)–\(endDay) \(WeekMath.monthAbbreviations[endMonth - 1])"
    }

    func contains(_ date: Date) -> Bool {
        let day = WeekMath.startOfDay(date)
        return day >= start && day <= end
    }
}

/// Aritmética de datas da app. Tudo assenta no calendário ISO 8601 em hora local —
/// as chaves "yyyy-MM-dd" são construídas à mão para nunca dependerem de locale
/// nem escorregarem um dia por conversão UTC, tal como na PWA.
enum WeekMath {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        return cal
    }()

    static let monthAbbreviations = [
        "jan", "fev", "mar", "abr", "mai", "jun",
        "jul", "ago", "set", "out", "nov", "dez",
    ]

    static let weekdayAbbreviations = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// "yyyy-MM-dd" em hora local.
    static func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// "dd/MM/yyyy" — o formato mostrado ao utilizador e usado no relatório.
    static func displayDate(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%02d/%02d/%04d", c.day ?? 0, c.month ?? 0, c.year ?? 0)
    }

    static func week(containing date: Date = .now) -> Week {
        let day = startOfDay(date)
        let interval = calendar.dateInterval(of: .weekOfYear, for: day)
        let start = interval.map { startOfDay($0.start) } ?? day
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return Week(start: start, end: end)
    }

    /// `offset` negativo recua no tempo, positivo avança. 0 é a semana atual.
    static func week(offsetBy offset: Int, from date: Date = .now) -> Week {
        let base = week(containing: date)
        guard let shifted = calendar.date(byAdding: .weekOfYear, value: offset, to: base.start) else {
            return base
        }
        return week(containing: shifted)
    }

    // MARK: - Meses

    /// `offset` negativo recua no tempo. 0 é o mês atual.
    static func monthSpan(offsetBy offset: Int, from date: Date = .now) -> MonthSpan {
        let base = startOfDay(date)
        let shifted = calendar.date(byAdding: .month, value: offset, to: base) ?? base
        let interval = calendar.dateInterval(of: .month, for: shifted)
        let start = interval.map { startOfDay($0.start) } ?? shifted
        let end = calendar.date(byAdding: .day, value: -1, to: interval?.end ?? shifted)
            .map(startOfDay) ?? shifted
        return MonthSpan(start: start, end: end)
    }

    // MARK: - Mês comercial

    /// O dia de fecho não cai sempre no último dia do mês, e em meses curtos um dia 31
    /// não existe. Encurta-se sempre ao último dia disponível, que é o que qualquer
    /// pessoa entende por "fecha no fim do mês".
    static func closeDate(year: Int, month: Int, closingOn day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let first = calendar.date(from: components) ?? startOfDay(.now)
        let length = calendar.range(of: .day, in: .month, for: first)?.count ?? 28
        components.day = max(1, min(day, length))
        return startOfDay(calendar.date(from: components) ?? first)
    }

    /// O período de fecho a que uma data pertence.
    ///
    /// Com fecho a 25, o mês comercial de setembro vai de 26 de agosto a 25 de setembro.
    /// Uma data depois do dia de fecho já conta para o período seguinte.
    static func commercialMonth(containing date: Date = .now, closingOn day: Int) -> MonthSpan {
        let today = startOfDay(date)
        let c = calendar.dateComponents([.year, .month], from: today)
        var endYear = c.year ?? 0
        var endMonth = c.month ?? 1

        if today > closeDate(year: endYear, month: endMonth, closingOn: day) {
            endMonth += 1
            if endMonth > 12 {
                endMonth = 1
                endYear += 1
            }
        }

        let end = closeDate(year: endYear, month: endMonth, closingOn: day)
        var previousYear = endYear
        var previousMonth = endMonth - 1
        if previousMonth < 1 {
            previousMonth = 12
            previousYear -= 1
        }
        let previousClose = closeDate(year: previousYear, month: previousMonth, closingOn: day)
        let start = calendar.date(byAdding: .day, value: 1, to: previousClose).map(startOfDay) ?? end

        return MonthSpan(start: start, end: end)
    }

    /// `offset` negativo recua períodos de fecho. 0 é o período em curso.
    static func commercialMonth(
        offsetBy offset: Int,
        closingOn day: Int,
        from date: Date = .now
    ) -> MonthSpan {
        let current = commercialMonth(containing: date, closingOn: day)
        // Ancorar no fim e recuar meses de calendário: recuar dias daria
        // resultados diferentes conforme o comprimento dos meses pelo caminho.
        let anchor = calendar.date(byAdding: .month, value: offset, to: current.end) ?? current.end
        return commercialMonth(containing: anchor, closingOn: day)
    }

    /// Os últimos `count` períodos de fecho, do mais antigo para o atual.
    static func lastCommercialMonths(
        _ count: Int,
        closingOn day: Int,
        from date: Date = .now
    ) -> [MonthSpan] {
        guard count > 0 else { return [] }
        return (0..<count).reversed().map {
            commercialMonth(offsetBy: -$0, closingOn: day, from: date)
        }
    }

    /// Os últimos `count` meses, do mais antigo para o mais recente, incluindo o atual.
    static func lastMonths(_ count: Int, from date: Date = .now) -> [MonthSpan] {
        guard count > 0 else { return [] }
        return (0..<count).reversed().map { monthSpan(offsetBy: -$0, from: date) }
    }

    /// As semanas que cobrem os últimos `months` meses, da mais antiga para a atual.
    ///
    /// A fronteira é o início do mês mais antigo: a semana que o contém entra inteira,
    /// mesmo que comece no mês anterior. É o que evita um primeiro ponto do gráfico
    /// artificialmente baixo por lhe faltarem dias.
    static func weeksCovering(months: Int, from date: Date = .now) -> [Week] {
        guard months > 0 else { return [] }
        let firstDay = monthSpan(offsetBy: -(months - 1), from: date).start
        let firstWeek = week(containing: firstDay)
        let currentWeek = week(containing: date)
        let span = calendar.dateComponents(
            [.weekOfYear], from: firstWeek.start, to: currentWeek.start
        ).weekOfYear ?? 0
        return (0...max(0, span)).map { week(offsetBy: -span + $0, from: date) }
    }

    static func month(containing date: Date = .now) -> (year: Int, month: Int) {
        let c = calendar.dateComponents([.year, .month], from: date)
        return (c.year ?? 0, c.month ?? 0)
    }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }
}


/// Um mês de calendário, do dia 1 ao último dia.
struct MonthSpan: Equatable, Hashable, Identifiable, Sendable {
    let start: Date
    let end: Date

    var id: Date { start }

    /// "abr" — abreviatura usada nos eixos dos gráficos.
    ///
    /// Vem do mês em que o período **termina**: com fecho a 25, o período que começa
    /// a 26 de agosto é o mês de setembro, e é assim que se fala dele.
    var label: String {
        let index = WeekMath.calendar.component(.month, from: end) - 1
        return WeekMath.monthAbbreviations[max(0, min(11, index))]
    }

    /// "26 ago – 25 set", para mostrar o período quando não é o mês de calendário.
    var rangeLabel: String {
        let cal = WeekMath.calendar
        let startDay = cal.component(.day, from: start)
        let endDay = cal.component(.day, from: end)
        let startMonth = WeekMath.monthAbbreviations[cal.component(.month, from: start) - 1]
        let endMonth = WeekMath.monthAbbreviations[cal.component(.month, from: end) - 1]
        return "\(startDay) \(startMonth) – \(endDay) \(endMonth)"
    }

    func contains(_ date: Date) -> Bool {
        let day = WeekMath.startOfDay(date)
        return day >= start && day <= end
    }
}
