import SwiftUI
import SwiftData

/// Painel do mês: o funil comercial com o preço de cada passo.
///
/// Responde a "quanto vale cada chamada que faço?" e "quantas reuniões me faltam para o
/// objetivo?". O preço sai dos meses anteriores (valor fechado ÷ quantidade de cada passo);
/// sem histórico, sai do objetivo mensal repartido pelos objetivos de atividade.
struct FunnelView: View {
    @Query private var allEntries: [DailyEntry]
    @Query private var allSummaries: [WeeklySummary]

    private var settings: AppSettings { .current }

    private var month: MonthSpan {
        WeekMath.commercialMonth(containing: .now, closingOn: settings.monthCloseDay)
    }

    var body: some View {
        let settings = self.settings
        let baseline = FunnelBaseline.make(entries: allEntries, summaries: allSummaries, settings: settings)
        let current = FunnelCounts.summing(entries: allEntries, summaries: allSummaries, in: month)
        let workdays = FunnelCalendar.workdays(in: month)

        return NavigationStack {
            List {
                Section {
                    GoalBar(
                        label: "Valor fechado",
                        value: Int(current.valor.rounded()),
                        goal: settings.goalMensalValor
                    )
                } header: {
                    Text("Objetivo do mês")
                } footer: {
                    Text(month.rangeLabel)
                }

                Section {
                    ForEach(FunnelStep.allCases) { step in
                        FunnelRow(
                            step: step,
                            unitValue: baseline.valuePerUnit(step),
                            done: Int(current[step]),
                            target: step.monthlyTarget(settings: settings, workdays: workdays)
                        )
                    }
                } header: {
                    Text("Quanto vale cada passo")
                } footer: {
                    Text(sourceExplanation(baseline))
                }
            }
            .navigationTitle("Painel")
            .settingsToolbar()
        }
    }

    private func sourceExplanation(_ baseline: FunnelBaseline) -> String {
        switch baseline.source {
        case .historico(let months):
            let names = months.map(\.label).joined(separator: ", ")
            let valor = baseline.reference.valor.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
            return "Cada valor é o que fechaste em \(names) (\(valor)) a dividir pela quantidade desse passo nesses meses. O alvo do mês vem dos teus objetivos: contactos por dia útil e reuniões por semana."
        case .objetivo:
            return "Ainda não há meses anteriores com valor fechado, por isso cada valor é o objetivo mensal a dividir pelo alvo do mês. Depois do primeiro mês fechado passa a usar os teus números reais."
        }
    }
}

private struct FunnelRow: View {
    let step: FunnelStep
    let unitValue: Double?
    let done: Int
    let target: Int

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(done) / Double(target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(step.label).font(.subheadline)
                Spacer()
                Text(unitValue.map(euros) ?? "—")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            Text("\(done) de \(target) este mês")
                .font(.caption)
                .foregroundStyle(.secondary)
            if target > 0 {
                ProgressView(value: fraction)
                    .tint(fraction >= 1 ? .green : .accentColor)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func euros(_ value: Double) -> String {
        // Abaixo de 10 € os cêntimos contam (um contacto pode valer 4,50 €).
        let digits = value < 10 ? 2 : 0
        return value.formatted(.currency(code: "EUR").precision(.fractionLength(digits)))
    }
}
