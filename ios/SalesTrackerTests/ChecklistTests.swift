import Testing
import Foundation
@testable import SalesTracker

@Suite("Checklist diária")
struct ChecklistTests {

    @Test("Os ids concluídos sobrevivem à ida e volta para texto")
    func roundTrip() {
        let entry = DailyEntry(date: .now)
        entry.completedChecklistIDs = ["b", "a", "c"]

        // Ordenado na gravação para o mesmo conjunto dar sempre o mesmo texto — senão
        // dois dispositivos gravariam strings diferentes para o mesmo estado.
        #expect(entry.checklistDoneIDs == "a,b,c")
        #expect(entry.completedChecklistIDs == ["a", "b", "c"])
    }

    @Test("Um conjunto vazio limpa o campo")
    func emptySet() {
        let entry = DailyEntry(date: .now)
        entry.completedChecklistIDs = ["x"]
        entry.completedChecklistIDs = []
        #expect(entry.checklistDoneIDs.isEmpty)
    }

    @Test("Um dia só com tarefas marcadas conta como registado")
    func checklistCountsAsFilled() {
        let entry = DailyEntry(date: .now)
        #expect(entry.isEmpty)

        entry.completedChecklistIDs = ["tarefa"]
        // Sem isto o lembrete de "ainda não registaste" dispararia num dia trabalhado.
        #expect(!entry.isEmpty)
    }

    @Test("Um dia com métricas mas sem tarefas continua registado")
    func metricsCountAsFilled() {
        let entry = DailyEntry(date: .now)
        entry[.contactos] = 3
        #expect(!entry.isEmpty)
    }
}


@Suite("Lembretes diários")
struct ReminderSettingsTests {

    @Test("São dois por dia, de manhã e ao fim da tarde")
    func twoTimesPerDay() {
        let settings = AppSettings()
        let times = settings.reminderTimes

        #expect(times.count == 2)
        #expect(times[0].hour == 9 && times[0].minute == 0)
        #expect(times[1].hour == 17 && times[1].minute == 0)
        #expect(times[0].moment == .morning)
        #expect(times[1].moment == .evening)
    }

    @Test("Cada momento tem o seu texto")
    func momentsReadDifferently() {
        // Às 9h ainda não houve dia nenhum para registar; às 17h já houve.
        #expect(ReminderMoment.morning.body != ReminderMoment.evening.body)
        #expect(ReminderMoment.evening.body.contains("Ainda não registaste"))
    }
}

@Suite("Aspeto da aplicação")
struct AppearanceTests {

    @Test("Sistema não força nenhum esquema de cor")
    func systemFollowsTheDevice() {
        #expect(AppAppearance.system.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test("Um valor desconhecido cai no sistema")
    func unknownValueFallsBackToSystem() {
        #expect(AppAppearance(rawValue: "sepia") == nil)
    }
}
