import Foundation

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
    static let reminderHour = "reminderHour"
    static let reminderMinute = "reminderMinute"
    static let remindersEnabled = "remindersEnabled"
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
    var reminderHour: Int = 18
    var reminderMinute: Int = 30
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
        if d.object(forKey: SettingsKey.reminderHour) != nil {
            s.reminderHour = d.integer(forKey: SettingsKey.reminderHour)
        }
        if d.object(forKey: SettingsKey.reminderMinute) != nil {
            s.reminderMinute = d.integer(forKey: SettingsKey.reminderMinute)
        }
        s.remindersEnabled = d.bool(forKey: SettingsKey.remindersEnabled)
        return s
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
