import Foundation

/// Uma tarefa diária de sim/não, definida pelo próprio utilizador.
///
/// A app não traz tarefas de nenhuma empresa nem de nenhum modelo de negócio: quem usa
/// escreve as suas. O `id` é gerado uma vez e nunca muda, para que renomear a etiqueta
/// não perca o histórico dos dias já marcados.
struct ChecklistItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var label: String

    init(id: String = UUID().uuidString, label: String) {
        self.id = id
        self.label = label
    }
}

/// Guarda a definição da checklist em `UserDefaults` partilhado, como JSON.
///
/// São poucos itens e mudam raramente — não justifica uma entidade no SwiftData, e ficando
/// fora do SwiftData não entra no esquema do CloudKit, que é irreversível depois de
/// promovido a produção.
enum ChecklistStore {
    static let key = "dailyChecklistItems"

    static var items: [ChecklistItem] {
        get {
            guard let data = UserDefaults.shared.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([ChecklistItem].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.shared.set(data, forKey: key)
        }
    }

    static func add(_ label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(ChecklistItem(label: trimmed))
    }

    /// Só remove a definição. Os ids que ficarem nos registos antigos são ignorados na
    /// leitura, o que mantém o histórico intacto se a tarefa voltar a ser criada.
    static func remove(atOffsets offsets: IndexSet) {
        var current = items
        current.remove(atOffsets: offsets)
        items = current
    }

    static func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var current = items
        current.move(fromOffsets: source, toOffset: destination)
        items = current
    }

    static func rename(id: String, to label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var current = items
        guard let index = current.firstIndex(where: { $0.id == id }) else { return }
        current[index].label = trimmed
        items = current
    }
}
