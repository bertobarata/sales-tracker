import Foundation
import SwiftUI

enum AppGroup {
    static let identifier = "group.com.bertobarata.salestracker"
    static let cloudKitContainer = "iCloud.com.bertobarata.salestracker"

    /// `ModelConfiguration(groupContainer:)` faz `fatalError` — não lança — quando o
    /// App Group não está nos entitlements (builds sem assinatura, testes unitários).
    /// Verificar aqui primeiro é o que permite ter um fallback em vez de um crash.
    static var isAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }
}

extension UserDefaults {
    /// Partilhado entre a app e o widget.
    /// `UserDefaults` é thread-safe mas não está marcado `Sendable`, daí o `nonisolated(unsafe)`.
    nonisolated(unsafe) static let shared = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
}

enum SettingsKey {
    static let goalPrimeirasReunioes = "goalPrimeirasReunioesRealizadas"
    static let goalSegundasReunioes = "goalSegundasReunioesRealizadas"
    static let goalTerceirasReunioes = "goalTerceirasReunioesRealizadas"
    static let goalContratosSemana = "goalContratosSemana"
    static let goalValorSemana = "goalValorSemana"
    static let goalMensalValor = "goalMensalValor"
    static let monthCloseDay = "monthCloseDay"
    static let reminderMorningHour = "reminderMorningHour"
    static let reminderMorningMinute = "reminderMorningMinute"
    static let reminderEveningHour = "reminderEveningHour"
    static let reminderEveningMinute = "reminderEveningMinute"
    static let remindersEnabled = "remindersEnabled"
    static let appearance = "appearance"
    static let onboardingCompletedVersion = "onboardingCompletedVersion"

    /// Versão da introdução já vista. Subir este número volta a mostrá-la a quem já a viu.
    /// Vive aqui, e não na vista, porque `Core/` também é compilado no widget, que não
    /// tem acesso às vistas da app.
    static let onboardingVersion = 1
}

/// Snapshot das definições, para código fora das vistas (widget, agendador de notificações).
struct AppSettings: Equatable, Sendable {
    var goalPrimeirasReunioes: Int = 10
    var goalSegundasReunioes: Int = 8
    var goalTerceirasReunioes: Int = 4
    var goalContratosSemana: Int = 2
    var goalValorSemana: Int = 1500
    var goalMensalValor: Int = 5000
    /// Dia em que o mês fecha. 31 dá o último dia em qualquer mês, porque se encurta
    /// ao comprimento do mês — é por isso que serve de omissão sem precisar de sentinela.
    var monthCloseDay: Int = 31
    /// Dois lembretes por dia: um de manhã, para lembrar de ir registando, e outro ao
    /// fim da tarde, para fechar o dia. Um só, ao fim do dia, chega tarde de mais para
    /// quem já não se lembra do que fez de manhã.
    var reminderMorningHour: Int = 9
    var reminderMorningMinute: Int = 0
    var reminderEveningHour: Int = 17
    var reminderEveningMinute: Int = 0
    var remindersEnabled: Bool = false

    static var current: AppSettings {
        let d = UserDefaults.shared
        var s = AppSettings()
        if d.object(forKey: SettingsKey.goalPrimeirasReunioes) != nil {
            s.goalPrimeirasReunioes = d.integer(forKey: SettingsKey.goalPrimeirasReunioes)
        }
        if d.object(forKey: SettingsKey.goalSegundasReunioes) != nil {
            s.goalSegundasReunioes = d.integer(forKey: SettingsKey.goalSegundasReunioes)
        }
        if d.object(forKey: SettingsKey.goalTerceirasReunioes) != nil {
            s.goalTerceirasReunioes = d.integer(forKey: SettingsKey.goalTerceirasReunioes)
        }
        if d.object(forKey: SettingsKey.goalContratosSemana) != nil {
            s.goalContratosSemana = d.integer(forKey: SettingsKey.goalContratosSemana)
        }
        if d.object(forKey: SettingsKey.goalValorSemana) != nil {
            s.goalValorSemana = d.integer(forKey: SettingsKey.goalValorSemana)
        }
        if d.object(forKey: SettingsKey.goalMensalValor) != nil {
            s.goalMensalValor = d.integer(forKey: SettingsKey.goalMensalValor)
        }
        if d.object(forKey: SettingsKey.monthCloseDay) != nil {
            s.monthCloseDay = max(1, min(31, d.integer(forKey: SettingsKey.monthCloseDay)))
        }
        if d.object(forKey: SettingsKey.reminderMorningHour) != nil {
            s.reminderMorningHour = d.integer(forKey: SettingsKey.reminderMorningHour)
        }
        if d.object(forKey: SettingsKey.reminderMorningMinute) != nil {
            s.reminderMorningMinute = d.integer(forKey: SettingsKey.reminderMorningMinute)
        }
        if d.object(forKey: SettingsKey.reminderEveningHour) != nil {
            s.reminderEveningHour = d.integer(forKey: SettingsKey.reminderEveningHour)
        }
        if d.object(forKey: SettingsKey.reminderEveningMinute) != nil {
            s.reminderEveningMinute = d.integer(forKey: SettingsKey.reminderEveningMinute)
        }
        s.remindersEnabled = d.bool(forKey: SettingsKey.remindersEnabled)
        return s
    }

    /// As duas horas do dia em que o lembrete dispara, da mais cedo para a mais tarde.
    var reminderTimes: [(hour: Int, minute: Int, moment: ReminderMoment)] {
        [
            (reminderMorningHour, reminderMorningMinute, .morning),
            (reminderEveningHour, reminderEveningMinute, .evening),
        ]
    }

    func goal(for metric: Metric) -> Int? {
        switch metric {
        case .primeirasReunioesRealizadas: goalPrimeirasReunioes
        case .segundasReunioesRealizadas: goalSegundasReunioes
        case .terceirasReunioesRealizadas: goalTerceirasReunioes
        default: nil
        }
    }
}


/// Qual dos dois lembretes do dia. Muda o texto: de manhã ainda não houve dia nenhum
/// para registar, ao fim da tarde já houve.
enum ReminderMoment: String, Sendable {
    case morning
    case evening

    var body: String {
        switch self {
        case .morning: "Dia novo. Vai registando à medida que acontece."
        case .evening: "Ainda não registaste o dia de hoje."
        }
    }
}

/// Aspeto da aplicação. `system` segue o iPhone, que é o que quase toda a gente quer;
/// as outras duas existem para quem prefere fixar um dos dois.
enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Sistema"
        case .light: "Claro"
        case .dark: "Escuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    static var current: AppAppearance {
        let raw = UserDefaults.shared.string(forKey: SettingsKey.appearance) ?? ""
        return AppAppearance(rawValue: raw) ?? .system
    }
}
