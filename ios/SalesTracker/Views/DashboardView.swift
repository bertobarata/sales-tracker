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

    /// Contratos e valor vivem no resumo semanal, não nos registos diários — é lá que
    /// são escritos, no separador Relatório.
    private var weekSummary: WeeklySummary? {
        allSummaries.first { $0.weekStartKey == week.startKey }
    }

    /// O período de fecho em curso. Nem sempre é o mês de calendário: há carteiras
    /// que fecham a meio do mês, e o objetivo mensal tem de seguir essa data.
    private var closingMonth: MonthSpan {
        WeekMath.commercialMonth(containing: .now, closingOn: settings.monthCloseDay)
    }

    private var monthlyValor: Double {
        allSummaries
            .filter { closingMonth.contains($0.weekStart) }
            .reduce(0) { $0 + $1.valorTotalFechos }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WeekNavigator(offset: $weekOffset, week: week)
                    dayStrip
                }

                Section("Objetivos da semana") {
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
                    GoalBar(
                        label: "3as Reuniões",
                        value: totals[.terceirasReunioesRealizadas],
                        goal: settings.goalTerceirasReunioes
                    )
                    GoalBar(
                        label: "Contratos fechados",
                        value: weekSummary?.contratosFechados ?? 0,
                        goal: settings.goalContratosSemana
                    )
                    GoalBar(
                        label: "Valor fechos",
                        value: Int((weekSummary?.valorTotalFechos ?? 0).rounded(.up)),
                        goal: settings.goalValorSemana
                    )
                }

                Section {
                    GoalBar(
                        label: "Valor fechos",
                        value: Int(monthlyValor.rounded(.up)),
                        goal: settings.goalMensalValor
                    )
                    monthlyRemainder
                } header: {
                    Text("Objetivo mensal")
                } footer: {
                    // Só vale a pena mostrar o período quando não é o mês inteiro.
                    if settings.monthCloseDay < 28 {
                        Text("Fecha a \(settings.monthCloseDay) · \(closingMonth.rangeLabel)")
                    }
                }

                Section("Reuniões realizadas") {
                    GlassEffectContainer(spacing: 10) { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
                    } }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                Section("Prospeção") {
                    GlassEffectContainer(spacing: 10) { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricCard(label: "Pesquisas", value: totals[.pesquisas])
                        MetricCard(label: "Referências", value: totals[.referencias])
                    } }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
            .navigationTitle("Semana")
            .navigationBarTitleDisplayMode(.inline)
            .settingsToolbar()
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
