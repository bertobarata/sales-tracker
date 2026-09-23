import XCTest

/// Capturas para a App Store. Corre a app com `--demo-data`, que a arranca
/// com base em memória já semeada, e guarda uma imagem por separador.
/// As imagens saem no `.xcresult` como anexos e extraem-se com `xcresulttool`.
@MainActor
final class ScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureAppStoreScreenshots() {
        captureOnboarding()

        let app = XCUIApplication()
        app.launchArguments = ["--demo-data", "--skip-onboarding"]
        app.launch()

        let tabs = ["Hoje", "Semana", "Relatório", "Tendências"]

        for (index, tab) in tabs.enumerated() {
            let button = app.tabBars.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 20), "Separador \(tab) não apareceu")
            button.tap()
            XCTAssertTrue(
                app.navigationBars[tab].waitForExistence(timeout: 20),
                "Ecrã \(tab) não renderizou"
            )

            // O relatório da semana em curso está meio vazio — os contratos e o valor só
            // se escrevem no fim. Recua uma semana para a captura mostrar uma semana
            // fechada, que é o que a secção serve para fazer.
            if tab == "Relatório" {
                let previous = app.buttons["week.previous"]
                if previous.waitForExistence(timeout: 5) { previous.tap() }
            }

            // Dá tempo aos gráficos de Tendências para desenharem antes do disparo.
            Thread.sleep(forTimeInterval: 1.5)
            capture(named: String(format: "%02d-%@", index + 2, slug(tab)))
        }
    }

    /// A introdução é a primeira coisa que alguém vê na loja, por isso é a primeira
    /// captura. Corre numa instância própria porque tem de arrancar por mostrar.
    private func captureOnboarding() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data", "--reset-onboarding"]
        app.launch()

        let skip = app.buttons["Saltar introdução"]
        XCTAssertTrue(skip.waitForExistence(timeout: 20), "A introdução não apareceu")
        Thread.sleep(forTimeInterval: 1.0)
        capture(named: "00-introducao")

        // Segunda página: o diagrama do funil, que é o que explica a app de relance.
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 1.0)
        capture(named: "01-funil")

        app.terminate()
    }

    private func capture(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func slug(_ value: String) -> String {
        value.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }
}
