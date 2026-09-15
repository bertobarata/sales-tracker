import SwiftUI
import SwiftData

struct DailyInputView: View {
    @Environment(\.modelContext) private var context

    @State private var weekOffset = 0
    @State private var selectedDate = WeekMath.startOfDay(.now)
    @State private var values: [Metric: Int] = [:]
    @State private var isSaved = false

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
                    if isSaved {
                        Label("Registo guardado.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    Button("Guardar") { save() }
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
            .navigationTitle("Hoje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .onAppear(perform: load)
        .onChange(of: selectedDate) { _, _ in load() }
        .onChange(of: weekOffset) { _, _ in
            // Ao mudar de semana, salta para hoje se for a semana atual, senão para segunda.
            selectedDate = weekOffset == 0 ? today : week.start
        }
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
                isSaved = false
            }
        )
    }

    private func load() {
        if let existing = store.entry(for: selectedDate) {
            values = Dictionary(uniqueKeysWithValues: Metric.allCases.map { ($0, existing[$0]) })
            isSaved = !existing.isEmpty
        } else {
            values = [:]
            isSaved = false
        }
    }

    private func save() {
        let entry = store.entryOrCreate(for: selectedDate)
        for metric in Metric.allCases {
            entry[metric] = values[metric] ?? 0
        }
        store.save()
        isSaved = true
        WidgetRefresher.reload()
    }
}
