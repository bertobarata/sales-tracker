import Foundation

/// Exportação do histórico semanal. A PWA gera .xlsx; em iOS gera-se CSV
/// (abre no Numbers e no Excel sem conversão) com as mesmas colunas e ordem.
enum CSVExport {
    static let fileName = "historico_vendas.csv"

    static func csv(for summaries: [WeeklySummary]) -> String {
        var columns = ["Semana (início)", "Semana (fim)"]
        columns += Metric.allCases.map(\.csvHeader)
        columns += [
            "Contratos Fechados", "Valor Fechos (€)", "Pessoas Seguras",
            "1ª Próxima Semana", "2ª Próxima Semana", "3ª Próxima Semana",
        ]

        var lines = [columns.map(escape).joined(separator: ",")]

        for summary in summaries.sorted(by: { $0.weekStart < $1.weekStart }) {
            var row = [summary.weekStartKey, WeekMath.dayKey(summary.weekEnd)]
            row += Metric.allCases.map { String(summary.totals[$0]) }
            let extra = summary.extra
            row += [
                String(extra.contratosFechados),
                String(format: "%.2f", extra.valorTotalFechos),
                String(extra.pessoasSeguras),
                String(extra.reunioes1aProxSemana),
                String(extra.reunioes2aProxSemana),
                String(extra.reunioes3aProxSemana),
            ]
            lines.append(row.map(escape).joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    /// Escreve o CSV num ficheiro temporário pronto a passar a um `ShareLink`.
    static func writeTemporaryFile(for summaries: [WeeklySummary]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: fileName)
        // BOM para o Excel reconhecer UTF-8 e não estragar os acentos.
        let contents = "\u{FEFF}" + csv(for: summaries)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
