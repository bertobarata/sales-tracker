import Foundation
import UserNotifications

/// Lembretes diários. Em vez de uma notificação repetitiva, agenda-se uma por dia
/// para os próximos sete dias e saltam-se os dias já registados — é a única forma
/// de o lembrete não aparecer num dia que já foi preenchido.
enum ReminderScheduler {
    private static let identifierPrefix = "daily-reminder-"
    private static let horizonDays = 7

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// `filledDayKeys` são os dias que já têm registo e portanto não precisam de lembrete.
    static func reschedule(settings: AppSettings, filledDayKeys: Set<String>) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        guard settings.remindersEnabled else { return }
        guard await authorizationStatus() == .authorized else { return }

        let now = Date.now
        for offset in 0..<horizonDays {
            guard let day = WeekMath.calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = WeekMath.dayKey(day)
            if filledDayKeys.contains(key) { continue }

            for time in settings.reminderTimes {
                var components = WeekMath.calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = time.hour
                components.minute = time.minute

                // Uma hora que já passou hoje não se agenda — dispararia de imediato.
                guard let fireDate = WeekMath.calendar.date(from: components),
                      fireDate > now
                else { continue }

                let content = UNMutableNotificationContent()
                content.title = "MetTracker"
                content.body = time.moment.body
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    // O momento entra no identificador: sem isso o segundo lembrete do
                    // dia substituía o primeiro em vez de se juntar a ele.
                    identifier: "\(identifierPrefix)\(key)-\(time.moment.rawValue)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
