import WidgetKit
import SwiftUI
import AppIntents

/// Control do Centro de Controlo / Ecrã Bloqueado (iOS 18+): um toque
/// soma uma 1.ª reunião ao dia de hoje sem abrir a app.
struct QuickLogControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.bertobarata.salestracker.quicklog") {
            ControlWidgetButton(action: LogMetricIntent(metric: .primeiraReuniao)) {
                Label("1.ª Reunião", systemImage: "person.2.badge.plus")
            }
        }
        .displayName("Registar 1.ª reunião")
        .description("Soma uma primeira reunião realizada ao dia de hoje.")
    }
}
