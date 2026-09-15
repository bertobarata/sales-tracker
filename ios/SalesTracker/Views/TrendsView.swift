import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @Query(sort: \WeeklySummary.weekStart) private var allSummaries: [WeeklySummary]

    @State private var weeksShown = 8

    private struct WeekPoint: Identifiable {
        let id: Date
        let week: Week
        let totals: MetricTotals
        var label: String { "S\(week.isoWeekNumber)" }
    }

    private var points: [WeekPoint] {
        (0..<weeksShown).reversed().map { back in
            let week = WeekMath.week(offsetBy: -back)
            let entries = allEntries.filter { week.contains($0.date) }
            return WeekPoint(id: week.start, week: week, totals: MetricTotals.summing(entries))
        }
    }

    private var valorPoints: [(week: Week, valor: Double)] {
        (0..<weeksShown).reversed().map { back in
            let week = WeekMath.week(offsetBy: -back)
            let valor = allSummaries.first { $0.weekStartKey == week.startKey }?.valorTotalFechos ?? 0
            return (week, valor)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Período", selection: $weeksShown) {
                        Text("8 semanas").tag(8)
                        Text("12 semanas").tag(12)
                        Text("26 semanas").tag(26)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Reuniões realizadas") {
                    Chart {
                        ForEach(points) { point in
                            ForEach(meetingMetrics, id: \.self) { metric in
                                BarMark(
                                    x: .value("Semana", point.label),
                                    y: .value("Total", point.totals[metric])
                                )
                                .foregroundStyle(by: .value("Tipo", metric.shortLabel))
                            }
                        }
                    }
                    .chartLegend(position: .bottom)
                    .frame(height: 220)
                }

                Section("Contactos e prospeção") {
                    Chart {
                        ForEach(points) { point in
                            LineMark(
                                x: .value("Semana", point.label),
                                y: .value("Contactos", point.totals[.contactos])
                            )
                            .foregroundStyle(by: .value("Tipo", "Contactos"))
                            LineMark(
                                x: .value("Semana", point.label),
                                y: .value("Pesquisas", point.totals[.pesquisas])
                            )
                            .foregroundStyle(by: .value("Tipo", "Pesquisas"))
                        }
                    }
                    .chartLegend(position: .bottom)
                    .frame(height: 200)
                }

                Section {
                    Chart {
                        ForEach(valorPoints, id: \.week) { item in
                            BarMark(
                                x: .value("Semana", "S\(item.week.isoWeekNumber)"),
                                y: .value("Valor", item.valor)
                            )
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                    .frame(height: 200)
                } header: {
                    Text("Valor de fechos (€)")
                } footer: {
                    Text("O valor vem das semanas guardadas no separador Relatório.")
                }
            }
            .navigationTitle("Tendências")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var meetingMetrics: [Metric] {
        [.primeirasReunioesRealizadas, .segundasReunioesRealizadas, .terceirasReunioesRealizadas]
    }
}
