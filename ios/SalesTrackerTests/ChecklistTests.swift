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
