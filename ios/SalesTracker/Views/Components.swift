import SwiftUI

/// Navegação ‹ semana › usada em Hoje, Semana e Relatório.
/// `offset` é 0 na semana atual e negativo para trás; avançar além da atual é bloqueado.
struct WeekNavigator: View {
    @Binding var offset: Int
    let week: Week
    var title: String?

    private var isCurrentWeek: Bool { offset == 0 }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    offset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    if let title {
                        Text(title).font(.headline)
                    }
                    Text(week.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    offset += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.plain)
                .disabled(isCurrentWeek)
                .opacity(isCurrentWeek ? 0.2 : 1)
            }

            if !isCurrentWeek {
                Button("Esta semana") { offset = 0 }
                    .font(.footnote.weight(.medium))
            }
        }
        .animation(.default, value: offset)
    }
}

/// Barra de progresso de um objetivo.
struct GoalBar: View {
    let label: String
    let value: Int
    let goal: Int

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(value) / Double(goal))
    }
    private var isDone: Bool { value >= goal }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text("\(value) / \(goal)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isDone ? Color.green : Color.primary)
            }
            ProgressView(value: fraction)
                .tint(isDone ? .green : .accentColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) de \(goal)")
    }
}

/// Cartão de métrica com valor grande e uma legenda opcional por baixo.
struct MetricCard: View {
    let label: String
    let value: Int
    var subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title.weight(.semibold).monospacedDigit())
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

/// Linha − valor + para registar uma métrica. O valor é editável por teclado numérico.
struct StepperRow: View {
    let label: String
    @Binding var value: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                stepButton(systemName: "minus", delta: -1)

                TextField("0", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .frame(width: 56)
                    .focused($isFocused)
                    .accessibilityLabel(label)
                    .onChange(of: value) { _, newValue in
                        if newValue < 0 { value = 0 }
                    }

                stepButton(systemName: "plus", delta: 1)
            }
            .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
        }
        .padding(.vertical, 2)
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { isFocused = false }
                }
            }
        }
    }

    private func stepButton(systemName: String, delta: Int) -> some View {
        Button {
            value = max(0, value + delta)
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 40, height: 40)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // Sem isto o VoiceOver anuncia só "mais" / "menos", sem dizer de que métrica.
        .accessibilityLabel(delta > 0 ? "Aumentar \(label)" : "Diminuir \(label)")
        .accessibilityIdentifier(delta > 0 ? "stepper.increment" : "stepper.decrement")
    }
}


/// Botão de Definições na barra de navegação.
///
/// Está nos quatro separadores: quem quer mudar um objetivo não devia ter de adivinhar
/// que a porta é o separador Hoje.
struct SettingsToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Definições")
            }
        }
    }
}

extension View {
    func settingsToolbar() -> some View {
        modifier(SettingsToolbar())
    }
}

/// Indicador de gravação automática.
///
/// Substitui o botão "Guardar": em vez de pedir uma ação, confirma que já aconteceu.
/// Discreto de propósito — é para tranquilizar de relance, não para interromper.
struct SaveStatus: View {
    let savedAt: Date?

    var body: some View {
        Group {
            if let savedAt {
                Label(
                    "Guardado às " + savedAt.formatted(date: .omitted, time: .shortened),
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.secondary)
            } else {
                Label("As alterações guardam-se sozinhas.", systemImage: "icloud")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.caption)
        .animation(.default, value: savedAt)
    }
}


/// Campo de dinheiro.
///
/// Um `TextField(value:format:.currency)` reanalisa o texto a cada tecla: escrever "1"
/// passa logo a "1,00 €" e a tecla seguinte vai parar ao sítio errado. Com gravação
/// automática por cima, a vista redesenha a meio e o campo volta ao início.
///
/// Aqui edita-se texto simples e só se converte para número quando o campo perde o foco.
/// Enquanto não está a ser editado mostra o valor formatado, que é o que interessa ler.
struct CurrencyField: View {
    let label: String
    @Binding var amount: Double
    var onCommit: () -> Void = {}

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.semibold).monospacedDigit())
                .frame(width: 140)
                .focused($isFocused)
                .accessibilityLabel(label)
        }
        .contentShape(.rect)
        // Tocar na linha inteira entra no campo: o alvo do número sozinho é pequeno.
        .onTapGesture { isFocused = true }
        .onAppear { text = displayText }
        .onChange(of: isFocused) { _, focused in
            // Entrar no campo limpa-o e deixa o valor antigo como sugestão. Num campo de
            // dinheiro quase nunca se emenda um dígito — escreve-se o valor todo de novo,
            // e ter de apagar o anterior à mão era o que o tornava insuportável.
            // Sair sem escrever nada mantém o que lá estava.
            if focused {
                text = ""
            } else {
                commit()
            }
        }
        .onChange(of: amount) { _, _ in
            // Uma alteração vinda de fora (iCloud, mudança de semana) só pode reescrever
            // o campo quando não está a ser editado, senão apaga o que se está a escrever.
            if !isFocused { text = displayText }
        }
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { isFocused = false }
                }
            }
        }
    }

    private var displayText: String {
        amount.formatted(.currency(code: "EUR"))
    }

    /// Enquanto se escreve, o valor anterior fica como sugestão em cinzento.
    private var placeholder: String {
        amount > 0 ? displayText : "0"
    }

    private func commit() {
        let separator = Locale.current.decimalSeparator ?? ","
        let cleaned = text
            .replacingOccurrences(of: separator, with: ".")
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }

        defer { text = displayText }

        // Campo deixado em branco não é zero: é não ter mexido.
        guard !cleaned.isEmpty, let parsed = Double(cleaned) else { return }

        let rounded = (max(0, parsed) * 100).rounded() / 100
        guard rounded != amount else { return }
        amount = rounded
        onCommit()
    }
}
