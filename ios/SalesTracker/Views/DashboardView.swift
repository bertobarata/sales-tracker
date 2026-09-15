import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var allEntries: [DailyEntry]
    @Query private var allSummaries: [WeeklySummary]

    @State private var weekOffset = 0

    private var store: EntryStore { EntryStore(context) }
    private var week: Week { WeekMath.week(offsetBy: weekOffset) }
    private var settings: AppSettings { .current }

    /// Filtra em memória a partir do `@Query` para a vista reagir a alterações
    /// vindas do CloudKit sem precisar de recarregar manualmente.
    private var weekEntries: [DailyEntry] {
        allEntries.filter { week.contains($0.date) }
    }

    private var totals: MetricTotals { MetricTotals.summing(weekEntries) }

    private var monthlyValor: Double {
        let (year, month) = WeekMath.month(containing: .now)
        let prefix = String(format: "%04d-%02d", year, month)
        return allSummaries
            .filter { $0.weekStartKey.hasPrefix(prefix) }
            .reduce(0) { $0 + $1.valorTotalFechos }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WeekNavigator(offset: $weekOffset, week: week)
                    dayStrip
                }

                Section("Objetivos") {
                    GoalBar(
                        label: "1as Reuniões",
                        value: totals[.primeirasReunioesRealizadas],
                        goal: settings.goalPrimeirasReunioes
                    )
                    GoalBar(
                        label: "2as Reuniões",
                        value: totals[.segundasReunioesRealizadas],
                        goal: settings.goalSegundasReunioes
                    )
                }

                Section("Objetivo mensal") {
                    GoalBar(
                        label: "Valor fechos",
                        value: Int(monthlyValor.rounded(.up)),
                        goal: settings.goalMensalValor
                    )
                    monthlyRemainder
                }

                Section("Reuniões realizadas") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricCard(
                            label: "1as",
                            value: totals[.primeirasReunioesRealizadas],
                            subtitle: "\(totals[.primeirasReunioesMarcadas]) marcadas"
                        )
                        MetricCard(
                            label: "2as",
                            value: totals[.segundasReunioesRealizadas],
                            subtitle: "\(totals[.segundasReunioesMarcadas]) marcadas"
                        )
                        MetricCard(
                            label: "3as",
                            value: totals[.terceirasReunioesRealizadas],
                            subtitle: "\(totals[.terceirasReunioesMarcadas]) marcadas"
                        )
                        MetricCard(label: "Contactos", value: totals[.contactos])
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                Section("Prospeção") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricCard(label: "Pesquisas", value: totals[.pesquisas])
                        MetricCard(label: "Referências", value: totals[.referencias])
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
            .navigationTitle("Semana")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var monthlyRemainder: some View {
        let remaining = max(0, Double(settings.goalMensalValor) - monthlyValor)
        if remaining > 0 {
            Text("Faltam \(Int(remaining.rounded(.up)).formatted(.number.locale(Locale(identifier: "pt_PT"))))€ para o objetivo")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            Label("Objetivo mensal atingido!", systemImage: "checkmark.seal.fill")
                .font(.footnote)
                .foregroundStyle(.green)
        }
    }

    private var dayStrip: some View {
        HStack(spacing: 6) {
            ForEach(Array(week.days.enumerated()), id: \.element) { index, day in
                let entry = weekEntries.first { WeekMath.isSameDay($0.date, day) }
                let isToday = WeekMath.isSameDay(day, .now)
                VStack(spacing: 2) {
                    Text(WeekMath.weekdayAbbreviations[index])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.map { "\($0[.contactos])" } ?? "—")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    entry != nil ? AnyShapeStyle(Color.accentColor.opacity(0.15)) : AnyShapeStyle(.quaternary.opacity(0.3)),
                    in: .rect(cornerRadius: 10)
                )
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.accentColor, lineWidth: 1.5)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }
}
