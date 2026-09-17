import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @Query(sort: \WeeklySummary.weekStart) private var allSummaries: [WeeklySummary]

    @State private var period: Period = .threeMonths

    /// O período é escolhido em meses porque é assim que se fala de resultados.
    /// A granularidade do gráfico é consequência: a seis meses, vinte e tal barras
    /// semanais não se lêem num telemóvel, por isso agrega-se por mês.
    enum Period: Int, CaseIterable, Identifiable {
        case oneMonth = 1
        case threeMonths = 3
        case sixMonths = 6

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .oneMonth: "1 mês"
            case .threeMonths: "3 meses"
            case .sixMonths: "6 meses"
            }
        }

        var groupsByMonth: Bool { self == .sixMonths }
    }

    private struct Bucket: Identifiable {
        let id: Date
        let label: String
        let totals: MetricTotals
        let valor: Double
    }

    private var buckets: [Bucket] {
        period.groupsByMonth ? monthBuckets : weekBuckets
    }

    private var weekBuckets: [Bucket] {
        WeekMath.weeksCovering(months: period.rawValue).map { week in
            let entries = allEntries.filter { week.contains($0.date) }
            let valor = allSummaries
                .first { $0.weekStartKey == week.startKey }?
                .valorTotalFechos ?? 0
            return Bucket(
                id: week.start,
                label: "S\(week.isoWeekNumber)",
                totals: MetricTotals.summing(entries),
                valor: valor
            )
        }
    }

    private var monthBuckets: [Bucket] {
        WeekMath.lastMonths(period.rawValue).map { month in
            let entries = allEntries.filter { month.contains($0.date) }
            // Uma semana conta para o mês em que começa — mesma regra do valor mensal
            // no `EntryStore`, para os dois números nunca se contradizerem.
            let valor = allSummaries
                .filter { month.contains($0.weekStart) }
                .reduce(0) { $0 + $1.valorTotalFechos }
            return Bucket(
                id: month.start,
                label: month.label,
                totals: MetricTotals.summing(entries),
                valor: valor
            )
        }
    }

    private var hasData: Bool {
        buckets.contains { bucket in
            Metric.allCases.contains { bucket.totals[$0] > 0 } || bucket.valor > 0
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Período", selection: $period) {
                        ForEach(Period.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(period.groupsByMonth
                         ? "A seis meses, cada barra é um mês."
                         : "Cada barra é uma semana.")
                }

                if hasData {
                    meetingsSection
                    prospectingSection
                    valueSection
                } else {
                    Section {
                        ContentUnavailableView(
                            "Ainda sem histórico",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Regista alguns dias no separador Hoje e as tendências aparecem aqui.")
                        )
                    }
                }
            }
            .navigationTitle("Tendências")
            .navigationBarTitleDisplayMode(.inline)
            .settingsToolbar()
        }
    }

    private var meetingsSection: some View {
        Section("Reuniões realizadas") {
            Chart {
                ForEach(buckets) { bucket in
                    ForEach(meetingMetrics, id: \.self) { metric in
                        BarMark(
                            x: .value("Período", bucket.label),
                            y: .value("Total", bucket.totals[metric])
                        )
                        .foregroundStyle(by: .value("Tipo", metric.shortLabel))
                    }
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 220)
        }
    }

    private var prospectingSection: some View {
        Section("Contactos e prospeção") {
            Chart {
                ForEach(buckets) { bucket in
                    ForEach(prospectingMetrics, id: \.self) { metric in
                        LineMark(
                            x: .value("Período", bucket.label),
                            y: .value("Total", bucket.totals[metric])
                        )
                        .foregroundStyle(by: .value("Tipo", metric.chartLabel))
                    }
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 200)
        }
    }

    private var valueSection: some View {
        Section {
            Chart {
                ForEach(buckets) { bucket in
                    BarMark(
                        x: .value("Período", bucket.label),
                        y: .value("Valor", bucket.valor)
                    )
                    .foregroundStyle(Color.accentColor)
                }
            }
            .frame(height: 200)
        } header: {
            Text("Valor de fechos (€)")
        } footer: {
            Text("O valor vem das semanas preenchidas no separador Relatório.")
        }
    }

    private var meetingMetrics: [Metric] {
        [.primeirasReunioesRealizadas, .segundasReunioesRealizadas, .terceirasReunioesRealizadas]
    }

    private var prospectingMetrics: [Metric] {
        [.contactos, .pesquisas, .referencias]
    }
}
