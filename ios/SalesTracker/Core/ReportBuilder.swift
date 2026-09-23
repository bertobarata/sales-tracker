import Foundation

/// Gera o texto do relatório semanal no formato exato que é colado no WhatsApp.
/// O formato é replicado carácter a carácter a partir da PWA — quem lê o relatório
/// do outro lado espera sempre a mesma estrutura, por isso não deve variar.
enum ReportBuilder {
    static func whatsAppText(week: Week, totals: MetricTotals, extra: WeeklyExtra) -> String {
        let valor = Int(extra.valorTotalFechos.rounded(.up))
        return """
        *\(WeekMath.displayDate(week.start)) - \(WeekMath.displayDate(week.end))*

        1.ªR \(totals[.primeirasReunioesRealizadas])
        2.ªR \(totals[.segundasReunioesRealizadas])
        3.ªR \(totals[.terceirasReunioesRealizadas])
        Contratos \(extra.contratosFechados)
        Valor \(valor)€
        Referências \(totals[.referencias])
        Pessoas seguras \(extra.pessoasSeguras)

        P. Semana
        1.ª- \(extra.reunioes1aProxSemana)
        2.ª- \(extra.reunioes2aProxSemana)
        3.ª- \(extra.reunioes3aProxSemana)
        """
    }
}
