import SwiftUI
import SwiftData

struct DailyInputView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var weekOffset = 0
    @State private var selectedDate = WeekMath.startOfDay(.now)
    @State private var values: [Metric: Int] = [:]
    @State private var checklistDone: Set<String> = []
    @State private var checklistItems: [ChecklistItem] = ChecklistStore.items

    @State private var savedAt: Date?
    /// Muda a cada alteração e reinicia o `task` de gravação, o que faz o atraso.
    @State private var editToken = UUID()
    @State private var hasPendingEdit = false

    private var store: EntryStore { EntryStore(context) }
    private var week: Week { WeekMath.week(offsetBy: weekOffset) }
    private var today: Date { WeekMath.startOfDay(.now) }
    private var isToday: Bool { WeekMath.isSameDay(selectedDate, today) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    WeekNavigator(offset: $weekOffset, week: week)
                    daySelector
                }

                Section {
                    ForEach(Metric.allCases) { metric in
                        StepperRow(label: metric.label, value: binding(for: metric))
                    }
                } header: {
                    Text(headerTitle)
                } footer: {
                    SaveStatus(savedAt: savedAt)
                }

                if !checklistItems.isEmpty {
                    Section("Tarefas do dia") {
                        ForEach(checklistItems) { item in
                            Toggle(item.label, isOn: checklistBinding(for: item))
                        }
                    }
                }
            }
            .navigationTitle("Hoje")
            .navigationBarTitleDisplayMode(.inline)
            .settingsToolbar()
        }
        .onAppear {
            checklistItems = ChecklistStore.items
            load()
        }
        .onChange(of: selectedDate) { _, _ in
            flushPendingEdit()
            load()
        }
        .onChange(of: weekOffset) { _, _ in
            // Ao mudar de semana, salta para hoje se for a semana atual, senão para segunda.
            selectedDate = weekOffset == 0 ? today : week.start
        }
        // Reinicia a cada alteração: só grava quando o utilizador pára de mexer.
        .task(id: editToken) {
            guard hasPendingEdit else { return }
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            commit()
        }
        // Sair da app é o momento em que se perdia tudo. Grava sem esperar pelo atraso.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { flushPendingEdit() }
        }
        .onDisappear { flushPendingEdit() }
    }

    private var headerTitle: String {
        WeekMath.displayDate(selectedDate) + (isToday ? " — Hoje" : "")
    }

    private var daySelector: some View {
        HStack(spacing: 6) {
            ForEach(Array(week.days.enumerated()), id: \.element) { index, day in
                let isFuture = day > today
                let isSelected = WeekMath.isSameDay(day, selectedDate)
                Button {
                    selectedDate = day
                } label: {
                    VStack(spacing: 2) {
                        Text(WeekMath.weekdayAbbreviations[index])
                            .font(.caption2)
                        Text("\(WeekMath.calendar.component(.day, from: day))")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.4)),
                        in: .rect(cornerRadius: 10)
                    )
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .overlay {
                        if WeekMath.isSameDay(day, today) && !isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.accentColor, lineWidth: 1.5)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
                .opacity(isFuture ? 0.3 : 1)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }

    private func binding(for metric: Metric) -> Binding<Int> {
        Binding(
            get: { values[metric] ?? 0 },
            set: {
                values[metric] = max(0, $0)
                markEdited()
            }
        )
    }

    private func checklistBinding(for item: ChecklistItem) -> Binding<Bool> {
        Binding(
            get: { checklistDone.contains(item.id) },
            set: { isOn in
                if isOn {
                    checklistDone.insert(item.id)
                } else {
                    checklistDone.remove(item.id)
                }
                markEdited()
            }
        )
    }

    private func markEdited() {
        hasPendingEdit = true
        editToken = UUID()
    }

    private func load() {
        if let existing = store.entry(for: selectedDate) {
            values = Dictionary(uniqueKeysWithValues: Metric.allCases.map { ($0, existing[$0]) })
            checklistDone = existing.completedChecklistIDs
            savedAt = existing.isEmpty ? nil : existing.updatedAt
        } else {
            values = [:]
            checklistDone = []
            savedAt = nil
        }
        hasPendingEdit = false
    }

    private func flushPendingEdit() {
        guard hasPendingEdit else { return }
        commit()
    }

    private func commit() {
        hasPendingEdit = false
        let didSave = store.saveDay(values, checklist: checklistDone, for: selectedDate)
        savedAt = didSave ? .now : nil
        WidgetRefresher.reload()
    }
}
