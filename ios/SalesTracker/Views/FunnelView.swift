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
        let goal = Double(settings.goalMensalValor)

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
                            needed: baseline.needed(step, forGoal: goal),
                            conversion: baseline.conversion(into: step)
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
            return "Preços calculados com os meses de \(names): \(valor) fechados a dividir pela atividade que os produziu. \"Precisas\" é quanto desse passo leva ao objetivo mensal ao mesmo ritmo."
        case .objetivo:
            return "Ainda não há meses anteriores com valor fechado. Os preços vêm do objetivo mensal repartido pelos objetivos semanais. Contactos e reuniões marcadas ganham preço quando houver um mês fechado."
        }
    }
}

private struct FunnelRow: View {
    let step: FunnelStep
    let unitValue: Double?
    let done: Int
    let needed: Int?
    let conversion: Double?

    private var fraction: Double {
        guard let needed, needed > 0 else { return 0 }
        return min(1, Double(done) / Double(needed))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(step.label).font(.subheadline)
                Spacer()
                Text(unitValue.map(euros) ?? "—")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            HStack {
                if let needed {
                    Text("\(done) de \(needed) este mês")
                } else {
                    Text("\(done) este mês")
                }
                Spacer()
                if let conversion {
                    Text("conversão \(conversion.formatted(.percent.precision(.fractionLength(0))))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if needed != nil {
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
