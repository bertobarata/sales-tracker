import Testing
import Foundation
import SwiftData
@testable import SalesTracker

/// Contentor em memória: os testes não tocam na base real nem no iCloud.
///
/// O contentor é devolvido junto com a loja e guardado pelo teste de propósito. O
/// `EntryStore` só guarda o `ModelContext`, e um contexto cujo contentor já foi libertado
/// rebenta dentro do SwiftData no primeiro `fetch` — com EXC_BREAKPOINT, não com erro.
@MainActor
private struct TestEnvironment {
    let container: ModelContainer
    let store: EntryStore

    init() throws {
        let schema = Schema([DailyEntry.self, WeeklySummary.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        store = EntryStore(container.mainContext)
    }
}

@Suite("Gravação automática do dia")
@MainActor
struct EntryStoreTests {

    @Test("Um dia todo a zeros nunca chega a ser criado")
    func emptyDayIsNotCreated() throws {
        let env = try TestEnvironment()
        let store = env.store
        let day = Date.now

        let saved = store.saveDay([:], checklist: [], for: day)

        // Com gravação automática, abrir o separador e não escrever nada não pode
        // deixar rasto: um dia vazio contaria para as tendências e calaria o lembrete.
        #expect(saved == false)
        #expect(store.entry(for: day) == nil)
    }

    @Test("Um dia com valores é gravado")
    func dayWithValuesIsSaved() throws {
        let env = try TestEnvironment()
        let store = env.store
        let day = Date.now

        let saved = store.saveDay([.contactos: 4], checklist: [], for: day)

        #expect(saved)
        #expect(store.entry(for: day)?[.contactos] == 4)
    }

    @Test("Um dia só com tarefas marcadas é gravado")
    func dayWithOnlyChecklistIsSaved() throws {
        let env = try TestEnvironment()
        let store = env.store
        let day = Date.now

        let saved = store.saveDay([:], checklist: ["tarefa"], for: day)

        #expect(saved)
        #expect(store.entry(for: day)?.completedChecklistIDs == ["tarefa"])
    }

    @Test("Apagar tudo num dia já gravado apaga o registo")
    func clearingAnExistingDayRemovesIt() throws {
        let env = try TestEnvironment()
        let store = env.store
        let day = Date.now
        store.saveDay([.contactos: 4], checklist: ["tarefa"], for: day)

        let saved = store.saveDay([.contactos: 0], checklist: [], for: day)

        // Baixar tudo a zero é a forma de desfazer. Deixar o registo lá deixaria um
        // dia "preenchido" com zeros, que é diferente de um dia não registado.
        #expect(saved == false)
        #expect(store.entry(for: day) == nil)
    }

    @Test("Gravar duas vezes o mesmo dia não cria um segundo registo")
    func repeatedSaveDoesNotDuplicate() throws {
        let env = try TestEnvironment()
        let store = env.store
        let day = Date.now

        store.saveDay([.contactos: 1], checklist: [], for: day)
        store.saveDay([.contactos: 9], checklist: [], for: day)

        let week = WeekMath.week(containing: day)
        let entries = store.entries(in: week).filter { $0.dayKey == WeekMath.dayKey(day) }
        #expect(entries.count == 1)
        #expect(entries.first?[.contactos] == 9)
    }
}
