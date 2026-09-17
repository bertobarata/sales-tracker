import SwiftUI
import SwiftData

/// Introdução mostrada no primeiro arranque e reabrível em Definições.
///
/// Existe porque a app registava números sem nunca dizer para que serviam. O objetivo
/// não é ensinar a mexer nos botões — isso vê-se — é explicar o funil e porque é que
/// contar só os fechos chega tarde de mais para se corrigir alguma coisa.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.remindersEnabled, store: .shared)
    private var remindersEnabled = false
    @State private var permissionOutcome: PermissionOutcome = .notAsked
    @AppStorage(SettingsKey.onboardingCompletedVersion, store: .shared)
    private var completedVersion = 0

    @State private var page = 0

    private let pages: [Page] = [
        Page(
            symbol: "point.topleft.down.to.point.bottomright.curvepath",
            title: "Isto não é uma folha de contas",
            body: """
            É o acompanhamento do teu funil, dia a dia. Registas o que fizeste em dois \
            minutos e a app trata de somar, comparar com os teus objetivos e preparar o \
            relatório da semana.
            """
        ),
        Page(
            symbol: "line.3.horizontal.decrease",
            title: "O funil",
            body: """
            Cada contacto tem de atravessar quatro degraus até virar contrato, e em cada \
            um perdem-se pessoas. É normal — o que interessa é saber em qual é que se \
            perdem a mais.
            """,
            showsFunnel: true
        ),
        Page(
            symbol: "chart.line.uptrend.xyaxis",
            title: "Porque é que contar fechos chega tarde",
            body: """
            Uma semana fraca de contratos começou a formar-se três semanas antes, no topo \
            do funil. Se só olhares para o fim, descobres o problema quando já não há \
            tempo de o corrigir. Por isso se regista o funil todo, não só o resultado.
            """
        ),
        Page(
            symbol: "slider.horizontal.3",
            title: "Os objetivos são teus",
            body: """
            Reuniões por semana, contratos, valor a fechar, tarefas diárias — defines tudo \
            em Definições, e mudas quando quiseres. A app não impõe números de ninguém.
            """
        ),
        Page(
            symbol: "bell.badge",
            title: "Dois lembretes por dia",
            body: """
            Um de manhã, para ires registando à medida que acontece, e outro ao fim da \
            tarde para fechares o dia. Só aparecem nos dias que ainda não registaste, e \
            mudam-se ou desligam-se a qualquer momento nas definições.
            """,
            showsReminderButton: true
        ),
        Page(
            symbol: "lock.iphone",
            title: "Os dados não saem daqui",
            body: """
            Não há conta nem registo. O que escreves fica no teu iPhone e, se tiveres o \
            iCloud ligado, na tua conta privada do iCloud. Não passa por servidores nossos \
            — não existe servidor nenhum.
            """
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    PageView(page: item) {
                        if item.showsReminderButton {
                            reminderPermission
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            // Sem isto os pontos saem brancos sobre fundo claro e não se vê em que
            // página se está — o indicador não tem cor própria por omissão.
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(isLastPage ? "Começar" : "Continuar") {
                if isLastPage {
                    finish()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            Button("Saltar introdução") { finish() }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(isLastPage ? 0 : 1)
                .padding(.bottom, 20)
        }
        .interactiveDismissDisabled()
    }

    private var isLastPage: Bool { page == pages.count - 1 }

    private func finish() {
        completedVersion = SettingsKey.onboardingVersion
        dismiss()
    }

    fileprivate struct Page {
        let symbol: String
        let title: String
        let body: String
        var showsFunnel = false
        var showsReminderButton = false
    }

    enum PermissionOutcome {
        case notAsked, granted, denied
    }

    /// Pede a autorização só depois de explicar para que serve.
    ///
    /// Aceitar liga os lembretes de imediato: quem carregou no botão já disse que os
    /// quer, e obrigar a ir depois às definições ligar um interruptor seria pedir a
    /// mesma coisa duas vezes.
    @ViewBuilder
    private var reminderPermission: some View {
        switch permissionOutcome {
        case .notAsked:
            Button("Ativar lembretes") {
                Task { await requestReminders() }
            }
            .font(.headline)
            .buttonStyle(.glass)

        case .granted:
            Label("Lembretes ativados às 9:00 e às 17:00", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
                .multilineTextAlignment(.center)

        case .denied:
            Text("Sem problema. Podes ativá-los mais tarde em Definições.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func requestReminders() async {
        let granted = await ReminderScheduler.requestAuthorization()
        permissionOutcome = granted ? .granted : .denied
        guard granted else { return }
        remindersEnabled = true
        await ReminderScheduler.refresh(using: context)
    }

    private struct PageView<Extra: View>: View {
        let page: Page
        @ViewBuilder var extra: Extra

        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: page.symbol)
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 48)

                    Text(page.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(page.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)

                    if page.showsFunnel {
                        FunnelDiagram().padding(.top, 8)
                    }

                    extra
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
    }
}

/// Os degraus do funil, cada um mais estreito que o anterior.
///
/// As referências entram por fora e por cima, porque alimentam o topo em vez de serem
/// um degrau — é a distinção que costuma faltar a quem vê estas métricas pela primeira vez.
private struct FunnelDiagram: View {
    private struct Step: Identifiable {
        let id = UUID()
        let label: String
        let width: Double
    }

    private let steps: [Step] = [
        Step(label: "Contactos", width: 1.00),
        Step(label: "1.ª reunião", width: 0.82),
        Step(label: "2.ª reunião", width: 0.62),
        Step(label: "3.ª reunião", width: 0.44),
        Step(label: "Contrato", width: 0.30),
    ]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.right.down")
                Text("Referências alimentam o topo")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            GeometryReader { proxy in
                VStack(spacing: 6) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        Text(step.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(index == steps.count - 1 ? Color.white : Color.primary)
                            .frame(width: proxy.size.width * step.width, height: 36)
                            .background(
                                index == steps.count - 1
                                    ? AnyShapeStyle(Color.accentColor)
                                    : AnyShapeStyle(.quaternary.opacity(0.45)),
                                in: .rect(cornerRadius: 9)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 210)
        }
        .frame(maxWidth: 340)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Funil: contactos, primeira reunião, segunda reunião, terceira reunião, contrato. "
            + "As referências alimentam o topo do funil."
        )
    }
}
