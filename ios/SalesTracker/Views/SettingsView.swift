import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(SettingsKey.goalPrimeirasReunioes, store: .shared)
    private var goalPrimeiras = 10
    @AppStorage(SettingsKey.goalSegundasReunioes, store: .shared)
    private var goalSegundas = 8
    @AppStorage(SettingsKey.goalMensalValor, store: .shared)
    private var goalMensal = 5000
    @AppStorage(SettingsKey.remindersEnabled, store: .shared)
    private var remindersEnabled = false
    @AppStorage(SettingsKey.reminderHour, store: .shared)
    private var reminderHour = 18
    @AppStorage(SettingsKey.reminderMinute, store: .shared)
    private var reminderMinute = 30

    @State private var reminderTime = Date.now
    @State private var permissionDenied = false

    var body: some View {
        Form {
            Section("Objetivos semanais") {
                StepperRow(label: "1as reuniões realizadas", value: $goalPrimeiras)
                StepperRow(label: "2as reuniões realizadas", value: $goalSegundas)
            }

            Section("Objetivo mensal") {
                HStack {
                    Text("Valor de fechos (€)")
                        .font(.subheadline)
                    Spacer()
                    TextField("0", value: $goalMensal, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .frame(width: 110)
                }
            }

            Section {
                Toggle("Lembrete diário", isOn: $remindersEnabled)
                if remindersEnabled {
                    DatePicker("Hora", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            } footer: {
                if permissionDenied {
                    Text("As notificações estão desativadas nas Definições do iPhone. Ativa-as aí para receberes lembretes.")
                        .foregroundStyle(.orange)
                } else {
                    Text("O lembrete só aparece nos dias que ainda não registaste.")
                }
            }

            Section {
                LabeledContent("Sincronização", value: "iCloud")
                LabeledContent("Versão", value: Bundle.main.appVersion)
            } footer: {
                Text("Os dados ficam na tua conta iCloud privada e sincronizam entre os teus dispositivos. Nada é enviado para servidores de terceiros.")
            }
        }
        .navigationTitle("Definições")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            reminderTime = WeekMath.calendar.date(from: components) ?? .now
        }
        .onChange(of: reminderTime) { _, newValue in
            let components = WeekMath.calendar.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 18
            reminderMinute = components.minute ?? 30
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
        .onChange(of: goalMensal) { _, _ in WidgetRefresher.reload() }
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
