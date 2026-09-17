import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(SettingsKey.goalPrimeirasReunioes, store: .shared)
    private var goalPrimeiras = 10
    @AppStorage(SettingsKey.goalSegundasReunioes, store: .shared)
    private var goalSegundas = 8
    @AppStorage(SettingsKey.goalTerceirasReunioes, store: .shared)
    private var goalTerceiras = 4
    @AppStorage(SettingsKey.goalContratosSemana, store: .shared)
    private var goalContratos = 2
    @AppStorage(SettingsKey.goalValorSemana, store: .shared)
    private var goalValorSemana = 1500
    @AppStorage(SettingsKey.goalMensalValor, store: .shared)
    private var goalMensal = 5000
    @AppStorage(SettingsKey.monthCloseDay, store: .shared)
    private var monthCloseDay = 31
    @AppStorage(SettingsKey.remindersEnabled, store: .shared)
    private var remindersEnabled = false
    @AppStorage(SettingsKey.reminderMorningHour, store: .shared)
    private var morningHour = 9
    @AppStorage(SettingsKey.reminderMorningMinute, store: .shared)
    private var morningMinute = 0
    @AppStorage(SettingsKey.reminderEveningHour, store: .shared)
    private var eveningHour = 17
    @AppStorage(SettingsKey.reminderEveningMinute, store: .shared)
    private var eveningMinute = 0
    @AppStorage(SettingsKey.appearance, store: .shared)
    private var appearance = AppAppearance.system.rawValue
    @AppStorage(SettingsKey.onboardingCompletedVersion, store: .shared)
    private var onboardingCompletedVersion = 0

    @State private var morningTime = Date.now
    @State private var eveningTime = Date.now
    @State private var permissionDenied = false
    @State private var checklistItems: [ChecklistItem] = []
    @State private var newTaskLabel = ""
    @State private var showsOnboarding = false

    var body: some View {
        Form {
            Section("Objetivos da semana") {
                StepperRow(label: "1as reuniões realizadas", value: $goalPrimeiras)
                StepperRow(label: "2as reuniões realizadas", value: $goalSegundas)
                StepperRow(label: "3as reuniões realizadas", value: $goalTerceiras)
                StepperRow(label: "Contratos fechados", value: $goalContratos)
                amountField(label: "Valor a fechar", value: $goalValorSemana)
            }

            Section {
                amountField(label: "Valor de fechos", value: $goalMensal)
                StepperRow(label: "Dia de fecho", value: closeDayBinding)
            } header: {
                Text("Objetivo mensal")
            } footer: {
                Text(closeDayExplanation)
            }

            checklistSection

            Section {
                Toggle("Lembretes diários", isOn: $remindersEnabled)
                if remindersEnabled {
                    DatePicker("De manhã", selection: $morningTime, displayedComponents: .hourAndMinute)
                    DatePicker("Ao fim da tarde", selection: $eveningTime, displayedComponents: .hourAndMinute)
                }
            } footer: {
                if permissionDenied {
                    Text("As notificações estão desativadas nas Definições do iPhone. Ativa-as aí para receberes lembretes.")
                        .foregroundStyle(.orange)
                } else {
                    Text("Dois por dia, e só nos dias que ainda não registaste.")
                }
            }

            Section {
                Picker("Aspeto", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.label).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Aspeto")
            } footer: {
                Text("\"Sistema\" segue o que o iPhone estiver a usar.")
            }

            Section {
                Button("Rever introdução") { showsOnboarding = true }
                LabeledContent("Sincronização", value: "iCloud")
                LabeledContent("Versão", value: Bundle.main.appVersion)
            } footer: {
                Text("Os dados ficam na tua conta iCloud privada e sincronizam entre os teus dispositivos. Nada é enviado para servidores de terceiros.")
            }
        }
        .navigationTitle("Definições")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsOnboarding) {
            OnboardingView()
        }
        .onAppear {
            checklistItems = ChecklistStore.items
            morningTime = time(hour: morningHour, minute: morningMinute)
            eveningTime = time(hour: eveningHour, minute: eveningMinute)
        }
        .onChange(of: morningTime) { _, newValue in
            let components = WeekMath.calendar.dateComponents([.hour, .minute], from: newValue)
            morningHour = components.hour ?? 9
            morningMinute = components.minute ?? 0
            Task { await applyReminderSettings() }
        }
        .onChange(of: eveningTime) { _, newValue in
            let components = WeekMath.calendar.dateComponents([.hour, .minute], from: newValue)
            eveningHour = components.hour ?? 17
            eveningMinute = components.minute ?? 0
            Task { await applyReminderSettings() }
        }
        .onChange(of: remindersEnabled) { _, isOn in
            Task {
                if isOn {
                    let granted = await ReminderScheduler.requestAuthorization()
                    permissionDenied = !granted
                    if !granted {
                        remindersEnabled = false
                        return
                    }
                }
                await applyReminderSettings()
            }
        }
        .onChange(of: goalPrimeiras) { _, _ in WidgetRefresher.reload() }
        .onChange(of: goalSegundas) { _, _ in WidgetRefresher.reload() }
        .onChange(of: goalTerceiras) { _, _ in WidgetRefresher.reload() }
        .onChange(of: goalContratos) { _, _ in WidgetRefresher.reload() }
        .onChange(of: goalValorSemana) { _, _ in WidgetRefresher.reload() }
        .onChange(of: goalMensal) { _, _ in WidgetRefresher.reload() }
        .onChange(of: monthCloseDay) { _, _ in WidgetRefresher.reload() }
    }

    /// Tarefas diárias de sim/não, escritas por quem usa a app.
    ///
    /// A app não traz tarefas de nenhuma empresa: quem precisa de marcar "acesso ao portal
    /// X" escreve-o aqui, e fica só no seu telemóvel.
    private var checklistSection: some View {
        Section {
            ForEach($checklistItems) { $item in
                TextField("Nome da tarefa", text: $item.label)
                    .onSubmit { ChecklistStore.rename(id: item.id, to: item.label) }
            }
            .onDelete { offsets in
                ChecklistStore.remove(atOffsets: offsets)
                checklistItems = ChecklistStore.items
            }
            .onMove { source, destination in
                ChecklistStore.move(fromOffsets: source, toOffset: destination)
                checklistItems = ChecklistStore.items
            }

            HStack {
                TextField("Acrescentar tarefa", text: $newTaskLabel)
                    .onSubmit(addTask)
                Button("Juntar", action: addTask)
                    .disabled(newTaskLabel.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("Tarefas do dia")
        } footer: {
            Text("Aparecem no separador Hoje, para marcares. Apagar uma tarefa não apaga o histórico dos dias em que já a marcaste.")
        }
    }

    /// Nem todas as carteiras fecham no último dia do mês. O valor é limitado a 1–31 e
    /// encurtado ao comprimento de cada mês no `WeekMath`, para não existir um dia 31
    /// em fevereiro.
    private var closeDayBinding: Binding<Int> {
        Binding(
            get: { monthCloseDay },
            set: { monthCloseDay = max(1, min(31, $0)) }
        )
    }

    private var closeDayExplanation: String {
        let span = WeekMath.commercialMonth(closingOn: monthCloseDay)
        if monthCloseDay >= 28 {
            return "O mês fecha no último dia. Uma semana conta para o mês em que começa."
        }
        return "O mês fecha no dia \(monthCloseDay). O período em curso vai de "
            + "\(span.rangeLabel). Uma semana conta para o período em que começa."
    }

    /// Os objetivos são euros inteiros, mas o campo é o mesmo do relatório: editar texto
    /// e converter no fim. Com formatação de moeda a cada tecla, escrever um valor novo
    /// por cima do antigo era impossível.
    private func amountField(label: String, value: Binding<Int>) -> some View {
        CurrencyField(
            label: label,
            amount: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = max(0, Int($0.rounded())) }
            )
        )
    }

    private func addTask() {
        ChecklistStore.add(newTaskLabel)
        newTaskLabel = ""
        checklistItems = ChecklistStore.items
    }

    private func time(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return WeekMath.calendar.date(from: components) ?? .now
    }

    private func applyReminderSettings() async {
        let store = EntryStore(context)
        let horizon = WeekMath.week(offsetBy: 0).days + WeekMath.week(offsetBy: 1).days
        let filled = Set(
            horizon
                .compactMap { store.entry(for: $0) }
                .filter { !$0.isEmpty }
                .map(\.dayKey)
        )
        await ReminderScheduler.reschedule(settings: .current, filledDayKeys: filled)
    }
}

extension Bundle {
    var appVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
