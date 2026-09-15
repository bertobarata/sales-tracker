import SwiftUI
import SwiftData

struct WeeklyReportView: View {
    @Environment(\.modelContext) private var context
    @Query private var allEntries: [DailyEntry]
    @Query(sort: \WeeklySummary.weekStart) private var allSummaries: [WeeklySummary]

    @State private var weekOffset = 0
    @State private var extra = WeeklyExtra.empty
    @State private var didCopy = false
    @State private var didSave = false
    @State private var exportURL: URL?

    private var store: EntryStore { EntryStore(context) }
    private var week: Week { WeekMath.week(offsetBy: weekOffset) }
    private var totals: MetricTotals {
        MetricTotals.summing(allEntries.filter { week.contains($0.date) })
    }
    private var reportText: String {
        ReportBuilder.whatsAppText(week: week, totals: totals, extra: extra)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WeekNavigator(offset: $weekOffset, week: week)
                }

                Section("Totais da semana") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        MetricCard(label: "1.ª R.", value: totals[.primeirasReunioesRealizadas])
                        MetricCard(label: "2.ª R.", value: totals[.segundasReunioesRealizadas])
                        MetricCard(label: "3.ª R.", value: totals[.terceirasReunioesRealizadas])
                        MetricCard(label: "Pesquisas", value: totals[.pesquisas])
                        MetricCard(label: "Refs.", value: totals[.referencias])
                        MetricCard(label: "Contactos", value: totals[.contactos])
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                Section("Esta semana") {
                    StepperRow(label: "Contratos fechados", value: $extra.contratosFechados)
                    valorField
                    StepperRow(label: "Pessoas seguras", value: $extra.pessoasSeguras)
                }

                Section("Próxima semana") {
                    StepperRow(label: "1.ª reuniões", value: $extra.reunioes1aProxSemana)
                    StepperRow(label: "2.ª reuniões", value: $extra.reunioes2aProxSemana)
                    StepperRow(label: "3.ª reuniões", value: $extra.reunioes3aProxSemana)
                }

                Section("Pré-visualização") {
                    Text(reportText)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }

                Section {
                    ShareLink(item: reportText) {
                        Label("Partilhar para WhatsApp", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        UIPasteboard.general.string = reportText
                        didCopy = true
                    } label: {
                        Label(didCopy ? "Copiado!" : "Copiar texto", systemImage: "doc.on.doc")
                    }
                    Button {
                        save()
                    } label: {
                        Label(didSave ? "Guardado!" : "Guardar semana", systemImage: "tray.and.arrow.down")
                    }
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Exportar histórico (CSV)", systemImage: "tablecells")
                        }
                    } else {
                        Button {
                            exportURL = try? CSVExport.writeTemporaryFile(for: allSummaries)
                        } label: {
                            Label("Preparar exportação CSV", systemImage: "tablecells")
                        }
                    }
                }
            }
            .navigationTitle("Relatório")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(perform: load)
        .onChange(of: weekOffset) { _, _ in load() }
        .onChange(of: extra) { _, _ in
            didCopy = false
            didSave = false
            exportURL = nil
        }
    }

    private var valorField: some View {
        HStack {
            Text("Valor total (€)")
                .font(.subheadline)
            Spacer()
            TextField("0", value: $extra.valorTotalFechos, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.semibold).monospacedDigit())
                .frame(width: 110)
        }
    }

    private func load() {
        extra = store.summary(for: week)?.extra ?? .empty
        didCopy = false
        didSave = false
        exportURL = nil
    }

    private func save() {
        let summary = store.summaryOrCreate(for: week)
        summary.totals = totals
        summary.extra = extra
        store.save()
        didSave = true
        WidgetRefresher.reload()
    }
}
