import SwiftUI
import SwiftData

struct WeeklyReportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allEntries: [DailyEntry]
    @Query(sort: \WeeklySummary.weekStart) private var allSummaries: [WeeklySummary]

    @State private var weekOffset = 0
    @State private var extra = WeeklyExtra.empty
    @State private var didCopy = false
    @State private var exportURL: URL?

    @State private var savedAt: Date?
    @State private var editToken = UUID()
    @State private var hasPendingEdit = false

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
                    GlassEffectContainer(spacing: 10) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            MetricCard(label: "1.ª R.", value: totals[.primeirasReunioesRealizadas])
                            MetricCard(label: "2.ª R.", value: totals[.segundasReunioesRealizadas])
                            MetricCard(label: "3.ª R.", value: totals[.terceirasReunioesRealizadas])
                            MetricCard(label: "Pesquisas", value: totals[.pesquisas])
                            MetricCard(label: "Refs.", value: totals[.referencias])
                            MetricCard(label: "Contactos", value: totals[.contactos])
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                Section {
                    StepperRow(label: "Pessoas seguras", value: extraBinding(\.pessoasSeguras))
                    StepperRow(label: "Contratos fechados", value: extraBinding(\.contratosFechados))
                    valorField
                } header: {
                    Text("Esta semana")
                } footer: {
                    SaveStatus(savedAt: savedAt)
                }

                Section("Próxima semana") {
                    StepperRow(label: "1.ª reuniões", value: extraBinding(\.reunioes1aProxSemana))
                    StepperRow(label: "2.ª reuniões", value: extraBinding(\.reunioes2aProxSemana))
                    StepperRow(label: "3.ª reuniões", value: extraBinding(\.reunioes3aProxSemana))
                    LabeledContent("Total agendado", value: "\(extra.totalProximaSemana)")
                        .font(.subheadline.weight(.semibold))
                }

                Section("Pré-visualização") {
                    Text(reportText)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }

                Section {
                    ShareLink(item: reportText) {
                        // Sem presumir destinatário: a folha de partilha leva o texto
                        // para onde o utilizador quiser. Dizer "ao seu manager" presumia
                        // uma hierarquia que a app não tem e que muitos utilizadores não têm.
                        Label("Enviar relatório", systemImage: "paperplane.fill")
                    }
                    Button {
                        UIPasteboard.general.string = reportText
                        didCopy = true
                    } label: {
                        Label(didCopy ? "Copiado!" : "Copiar texto", systemImage: "doc.on.doc")
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
            .settingsToolbar()
        }
        .onAppear(perform: load)
        .onChange(of: weekOffset) { _, _ in
            flushPendingEdit()
            load()
        }
        .task(id: editToken) {
            guard hasPendingEdit else { return }
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            commit()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { flushPendingEdit() }
        }
        .onDisappear { flushPendingEdit() }
    }

    /// Mostra `0,00 €` em vez de um zero solto — o campo é dinheiro e deve parecer dinheiro.
    /// A gravação só acontece ao sair do campo, não a cada tecla.
    private var valorField: some View {
        CurrencyField(
            label: "Valor total",
            amount: Binding(
                get: { extra.valorTotalFechos },
                set: { extra.valorTotalFechos = max(0, $0) }
            ),
            onCommit: markEdited
        )
    }

    private func extraBinding(_ path: WritableKeyPath<WeeklyExtra, Int>) -> Binding<Int> {
        Binding(
            get: { extra[keyPath: path] },
            set: {
                extra[keyPath: path] = max(0, $0)
                markEdited()
            }
        )
    }

    private func markEdited() {
        hasPendingEdit = true
        editToken = UUID()
        didCopy = false
        exportURL = nil
    }

    private func load() {
        let summary = store.summary(for: week)
        extra = summary?.extra ?? .empty
        savedAt = summary?.updatedAt
        didCopy = false
        exportURL = nil
        hasPendingEdit = false
    }

    private func flushPendingEdit() {
        guard hasPendingEdit else { return }
        commit()
    }

    private func commit() {
        hasPendingEdit = false
        let summary = store.summaryOrCreate(for: week)
        summary.totals = totals
        summary.extra = extra
        store.save()
        savedAt = .now
        WidgetRefresher.reload()
    }
}
