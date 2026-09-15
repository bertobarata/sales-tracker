import WidgetKit
import SwiftUI
import SwiftData

struct WeekProgressEntry: TimelineEntry {
    let date: Date
    let week: Week
    let primeiras: Int
    let segundas: Int
    let contactos: Int
    let settings: AppSettings

    static let placeholder = WeekProgressEntry(
        date: .now,
        week: WeekMath.week(containing: .now),
        primeiras: 6,
        segundas: 4,
        contactos: 23,
        settings: AppSettings()
    )
}

struct WeekProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekProgressEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WeekProgressEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekProgressEntry>) -> Void) {
        let entry = currentEntry()
        // Nada muda sozinho: a próxima atualização certa é a viragem do dia.
        // Entre elas, quem grava na app chama `reloadAllTimelines`.
        let nextMidnight = WeekMath.calendar.startOfDay(
            for: WeekMath.calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    /// Lê num `ModelContext` próprio em vez do `mainContext`: o provider corre
    /// fora do MainActor e o contexto não atravessa fronteiras de isolamento.
    private func currentEntry() -> WeekProgressEntry {
        let week = WeekMath.week(containing: .now)
        guard let container = SharedContainer.shared else {
            return WeekProgressEntry(
                date: .now, week: week,
                primeiras: 0, segundas: 0, contactos: 0,
                settings: .current
            )
        }
        let totals = EntryStore(ModelContext(container)).totals(in: week)
        return WeekProgressEntry(
            date: .now,
            week: week,
            primeiras: totals[.primeirasReunioesRealizadas],
            segundas: totals[.segundasReunioesRealizadas],
            contactos: totals[.contactos],
            settings: .current
        )
    }
}

struct WeekProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetRefresher.kind, provider: WeekProgressProvider()) { entry in
            WeekProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Progresso da semana")
        .description("Reuniões realizadas face aos objetivos da semana.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular,
        ])
    }
}

struct WeekProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeekProgressEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: fraction(entry.primeiras, entry.settings.goalPrimeirasReunioes)) {
                Image(systemName: "person.2.fill")
            } currentValueLabel: {
                Text("\(entry.primeiras)")
            }
            .gaugeStyle(.accessoryCircular)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.week.label).font(.caption2).foregroundStyle(.secondary)
                Text("1as \(entry.primeiras)/\(entry.settings.goalPrimeirasReunioes)")
                    .font(.headline)
                Text("2as \(entry.segundas)/\(entry.settings.goalSegundasReunioes)")
                    .font(.caption)
            }

        case .systemMedium:
            VStack(alignment: .leading, spacing: 10) {
                header
                bar("1as Reuniões", entry.primeiras, entry.settings.goalPrimeirasReunioes)
                bar("2as Reuniões", entry.segundas, entry.settings.goalSegundasReunioes)
                HStack(spacing: 8) {
                    Button(intent: LogMetricIntent(metric: .primeiraReuniao)) {
                        Label("1.ª R.", systemImage: "plus")
                    }
                    Button(intent: LogMetricIntent(metric: .segundaReuniao)) {
                        Label("2.ª R.", systemImage: "plus")
                    }
                    Button(intent: LogMetricIntent(metric: .contactos)) {
                        Label("Contacto", systemImage: "plus")
                    }
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }

        default:
            VStack(alignment: .leading, spacing: 8) {
                header
                bar("1as", entry.primeiras, entry.settings.goalPrimeirasReunioes)
                bar("2as", entry.segundas, entry.settings.goalSegundasReunioes)
            }
        }
    }

    private var header: some View {
        Text(entry.week.label)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func bar(_ label: String, _ value: Int, _ goal: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text("\(value)/\(goal)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(value >= goal ? .green : .primary)
            }
            ProgressView(value: fraction(value, goal))
                .tint(value >= goal ? .green : .accentColor)
        }
    }

    private func fraction(_ value: Int, _ goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(value) / Double(goal))
    }
}
